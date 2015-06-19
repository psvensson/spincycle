Db = require('mongodb').Db
Server = require('mongodb').Server
MongoClient = require('mongodb').MongoClient
defer           = require('node-promise').defer

class MongoPersistence

  constructor: () ->
    @dbs = []

  connect: ()=>
    console.log 'Mongo connect called'

#    mongoclient = new MongoClient(new Server("localhost", 27017), {native_parser: true})
#    console.log 'mongoclient = '+mongoclient
#    console.dir mongoclient
#    mongoclient.open((err, db) =>
#      if err
#        console.log 'MONGO Error connection: '+err
#        console.dir err
#      else
#        console.log("---- We are connected ----")
#        @db = db
#    )

  getConnection: () =>
    q = defer()
    if @db
      q.resolve(@db)
    else
      MongoClient.connect( 'mongodb://localhost:27017/spincycle', (err, db) =>
        if err
          console.log 'MONGO Error connection: '+err
          console.dir err
          q.resolve(null)
        else
          console.log("---- We are connected ----")
          @db = db
          q.resolve(db)
      )
    return q

  getDbFor: (_type) =>
    q = defer()
    type = _type.toLowerCase()
    db = @dbs[type]
    if not db
      @getConnection().then (connection) =>
        console.log 'getDbFor got connection '+connection+' typeof is '+(typeof connection)
        connection.collection(type, (err, collection) =>
          if err
            console.log 'MONGO Error getting collection: '+err
            console.dir err
            q.resolve(null)
          else
            console.log 'Getting mongo collection '+type
            console.dir collection
            @dbs[type] = collection
            q.resolve(collection)
        )
    else
      q.resolve(db)
    return q


  all: (_type, cb)=>
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      collection.find().toArray (err, items) =>
        if err
          console.log 'MONGO Error getting all: '+err
          console.dir err
          cb(null)
        else
          cb (items)

  get: (_type, id, cb) =>
    type = _type.toLowerCase()
    console.log 'Mongo.get called for type '+type+' and id '+id
    @getDbFor(type).then (collection) =>
      collection.findOne {id: id}, (err, item) =>
        if err
          console.log 'MONGO get Error: '+err
          console.dir err
          cb(null)
        else
          cb(item)


  set: (_type, obj, cb)=>
    @getDbFor(_type).then (collection) =>
      console.log 'Mongo.set called for type '+_type+' and id '+obj.id
      collection.update {id: obj.id}, obj,{ upsert: true },(err, result, upserted) =>
        if err
          console.log 'MONGO set Error: '+err
          console.dir err
          cb(null)
        else
          cb(result)

  remove: (_type, obj, cb) =>
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      collection = @getDbFor(_type)
      collection.remove {id: obj.id}, {w:1}, (err, numberOfRemovedDocs) =>
        if err
          console.log 'MONGO remove Error: '+err
          console.dir err
          cb(null)
        else
          cb(obj)


module.exports = MongoPersistence