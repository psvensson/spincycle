defer           = require('node-promise').defer

class ResolveModule

  @modulecache = []
  constructor: (@basepath) ->
    console.log("+++ new ResolveModule created ++")
    process.on 'resolvemodule', (name, cb) =>
      @resolve(name, cb)

  resolve: (name, cb) =>
    rv = ResolveModule.modulecache[name]
    if rv
      #console.log 'resolving module '+name+' from cache'
      cb(rv)
    else
      console.log '.. looking up module '+name
      finder = require('findit')(@basepath)

      #This listens for files found
      finder.on 'file', (origfile) ->
        #console.log('File: ' + file)
        file = ""+origfile
        if file.indexOf('/') > -1
          file = file.substring(file.lastIndexOf('/')+1, file.length)

        if file.indexOf('.') > -1
          file = file.substring(0, file.indexOf('.'))
        #console.log('File: ' + file)
        if file == name and origfile.indexOf('.js') > -1 and origfile.indexOf('.map') == -1
            rv = origfile
            ResolveModule.modulecache[name] = file
            console.log 'saving module '+name+' in module cache'
            finder.stop()
            cb(rv)

      finder.on 'end', () ->

  createObjectFrom: (record) =>
    q = defer()
    if not record or not record[0]
      console.log 'createObjectFrom got null record...'
      q.resolve(null)
    else
      #console.log 'createObjectFrom got record '+record[0].id+' type '+record[0].type
      @resolve record[0].type, (filename) ->
        console.log 'resolved module '+record[0].type+" as "+filename
        module = ResolveModule.modulecache[record[0].type] or require(filename.replace('.js', ''))
        console.log 'module is '+module
        console.dir module
        ResolveModule.modulecache[record[0].type] = module
        o = Object.create(module.prototype)
        o._rev = record._rev
        o.constructor(record[0])
        q.resolve(o)
    return q

module.exports = ResolveModule