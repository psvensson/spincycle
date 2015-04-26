influx = require('influx')

class InfluxPersistence

  constructor: () ->
    @dbs = []
    @serverInflux = influx()

  connect: ()=>
    @client = influx({
      host : 'localhost'
      port : 8090
      username : 'foouser'
      password : 'foopassword'
      database : 'qp'
    })

  getDbFor: (_type) =>
    q = defer()
    type = _type.toLowerCase()
    db = @dbs[type]
    if not db
      serverInflux.getDatabaseNames (err, dbs) =>
        if (err)
          throw err
        else
          if dbs.indexOf(type) == -1
            serverInflux.createDatabases type, (cerr)=>
              if(cerr)
                throw cerr
              else
                @dbs[type] = type
                q.resolve(type)
          else
            @dbs[type] = type
            q.resolve(type)
    else
      q.resolve(type)
    return q


  all: (_type, cb)=>
    rv = []
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>


  get: ()=>


  set: ()=>


  remove: ()=>



module.exports = InfluxPersistence