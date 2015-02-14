class ResolveModule

  @modulecache = []
  constructor: (@basepath) ->
    console.log("+++ new ResolveModule created ++")
    process.on 'resolvemodule', (name, cb) =>
      @resolve(name, cb)

  resolve: (name, cb) =>
    rv = ResolveModule.modulecache[name]
    if rv
      console.log 'resolving modeule '+name+' from cache'
      cb(rv)
    else
      console.log '.. looking up module '+name
      finder = require('findit')(@basepath)
      #This listens for directories found
      finder.on 'directory', (dir) ->
        #console.log('Directory: ' + dir + '/')

      #This listens for files found
      finder.on 'file', (file) ->
        #console.log('File: ' + file)
        if file.indexOf(name+'.js') > -1

          #console.log 'happily adding file '+file
          if not file.indexOf '.map' and not file.indexOf '.coffee'
            rv = file
            ResolveModule.modulecache[name] = file
            finder.stop()
            cb(rv)

      finder.on 'end', () ->



module.exports = ResolveModule