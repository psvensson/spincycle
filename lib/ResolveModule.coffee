class ResolveModule

  constructor: (@basepath) ->
    console.log("+++ new ResolveModule created ++")
    process.on 'resolvemodule', (name, cb) =>
      @resolve(name, cb)

  resolve: (name, cb) =>
    rv = null
    finder = require('findit')(@basepath)

    #This listens for directories found
    finder.on 'directory', (dir) ->
      #console.log('Directory: ' + dir + '/')

    #This listens for files found
    finder.on 'file', (file) ->
      #console.log('File: ' + file)
      if file.indexOf(name+'.js') > -1

        #console.log 'happily adding file '+file
        rv = file
        finder.stop()
        cb(rv)

    finder.on 'end', () ->



module.exports = ResolveModule