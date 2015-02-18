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
        console.log('File: ' + file)
        if file == name
            rv = origfile
            ResolveModule.modulecache[name] = file
            finder.stop()
            cb(rv)

      finder.on 'end', () ->



module.exports = ResolveModule