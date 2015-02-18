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
      finder.on 'file', (file) ->
        #console.log('File: ' + file)
        if file.indexOf('/') > -1
          file = file.substring(file.lastIndexOf('/')+1, file.length)

        if file.indexOf('.') > -1
          file = file.substring(0, file.indexOf('.')-1)
        console.log('File: ' + file)
        if file == name and file.indexOf(name+'.js') > -1
          #console.log 'happily adding file '+file
          if file.indexOf('.map') == -1 and file.indexOf('.coffee') == -1
            rv = file
            ResolveModule.modulecache[name] = file
            finder.stop()
            cb(rv)

      finder.on 'end', () ->



module.exports = ResolveModule