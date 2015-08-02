Db = require('mongodb').Db
Server = require('mongodb').Server
MongoClient = require('mongodb').MongoClient
defer           = require('node-promise').defer

class MongoPersistence

  madr = process.env['MONGODB_PORT_28017_TCP_ADDR'] or '127.0.0.1'
  mport = process.env['MONGODB_PORT_28017_TCP_PORT'] or '27017'

  constructor: () ->
    @dbs = []

  connect: ()=>
    console.log 'Mongo connect called'

  getConnection: () =>
    q = defer()
    if @db
      q.resolve(@db)
    else
      MongoClient.connect( 'mongodb://mongodb:27017/spincycle', (err, db) =>
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
        connection.collection(type, (err, collection) =>
          if err
            console.log 'MONGO Error getting collection: '+err
            console.dir err
            q.resolve(null)
          else
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
    if typeof id == 'object'
      console.log 'Mongo.get got an object as id instead of string !!!!! '
      #console.dir id
      xyzzy
    @getDbFor(type).then (collection) =>
      collection.findOne {id: id}, (err, item) =>
        if err
          console.log 'MONGO get Error: '+err
          console.dir err
          cb(null)
        else
          cb(item)

  byProviderId: (_type, pid) =>
    console.log 'byProviderId called for pid '+pid+' and type '+_type
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      collection.findOne {providerId: pid}, (err, item) =>
        if err
          console.log 'MONGO byProviderId Error: '+err
          console.dir err
          q.resolve(null)
        else
          q.resolve(item)
    return q

    # This is not easily implementable in couch, so now we're diverging
  find: (_type, property, value) =>
    console.log 'byProviderId called for pid '+pid+' and type '+_type
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      query = {}
      query[property] = value
      collection.findOne query, (err, item) =>
        if err
          console.log 'MONGO find Error: '+err
          console.dir err
          q.resolve(null)
        else
          q.resolve(item)
    return q

  set: (_type, obj, cb)=>
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      console.log 'Mongo.set called for type '+type+' and id '+obj.id
      if typeof obj.id == 'object' then console.dir obj
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
      collection.remove {id: obj.id}, {w:1}, (err, numberOfRemovedDocs) =>
        if err
          console.log 'MONGO remove Error: '+err
          console.dir err
          cb(null)
        else
          cb(obj)


module.exports = MongoPersistence