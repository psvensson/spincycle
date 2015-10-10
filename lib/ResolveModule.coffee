defer           = require('node-promise').defer
debug = process.env["DEBUG"]

console.log 'resolvemodule dirname is '+__dirname
console.log(__dirname)
dirname = __dirname.substring(0, __dirname.indexOf('/node_modules'))
if __dirname.indexOf('node_modules') == -1  then dirname = '../..'

console.log 'starting module resolving from path '+dirname

class ResolveModule

  @modulecache = []
  @modulepathcache = []
  constructor: () ->
    console.log("+++ new ResolveModule created ++")
    process.on 'resolvemodule', (name, cb) =>
      @resolve(name, cb)

  resolve: (name, cb) =>
    rv = ResolveModule.modulepathcache[name]
    if rv
      #if debug then console.log 'resolving module '+name+' from cache -> '+rv
      cb(rv)
    else
      #if debug then console.log '.. looking up module '+name
      finder = require('findit')(dirname)

      #This listens for files found
      finder.on 'file', (origfile) ->
        file = ""+origfile
        if file.indexOf('node_modules') == -1 and file.indexOf('bower_components') == -1
          if file.indexOf('/') > -1
            file = file.substring(file.lastIndexOf('/')+1, file.length)
          if file.indexOf('.') > -1
            file = file.substring(0, file.indexOf('.'))
          if file == name and (origfile.indexOf('.js') > -1 or origfile.indexOf('.coffee') > -1) and origfile.indexOf('.map') == -1 and origfile.indexOf('.dump') == -1
            rv = origfile
            ResolveModule.modulepathcache[name] = rv
            finder.stop()
            cb(rv)
          else
            #if debug then console.log '-- no match for file '+origfile+' and name '+name

      finder.on 'end', () ->

  createObjectFrom: (record) =>
    q = defer()
    if debug
      console.log 'ResolveModule.createObjectFrom got record '+record
      console.dir record
    if not record or (record[0] and (record[0] == null) or record[0] == 'null')
      #console.log '++++++++++++++!!!!!!!!!!!!!!!!!!! NULL RECORD!!'
      q.resolve(null)
    else
      if not record[0] then record = [record]
      if debug then console.log 'ResolveModule.createObjectFrom resolving record with '+record[0].id+' of type '+record[0].type
      @resolve record[0].type, (filename) ->
        if debug then console.log 'ResolveModule resolved module '+record[0].type+" as "+filename
        module = ResolveModule.modulecache[record[0].type] or require(filename.replace('.js', ''))
        ResolveModule.modulecache[record[0].type] = module
        o = Object.create(module.prototype)
        o._rev = record._rev
        o.constructor(record[0])
        q.resolve(o)
    return q

module.exports = ResolveModule