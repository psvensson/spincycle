Db          = require('mongodb').Db
Server      = require('mongodb').Server
MongoClient = require('mongodb').MongoClient
defer       = require('node-promise').defer
MongoOplog  = require('mongo-oplog');

debug = process.env["DEBUG"]

oplog = undefined
cursor = undefined

class MongoPersistence

  if process.env['MONGODB_PORT_27017_TCP_PORT'] then madr = 'mongodb' else madr = '127.0.0.1'
  mport = process.env['MONGODB_PORT_27017_TCP_PORT'] or '27017'

  if debug then console.log 'mongodb adr = '+madr+', port = '+mport
  watcher = undefined


  constructor: (@dburl, @DB) ->
    if @dburl then madr = @dburl
    @dbs = []

  connect: ()=>
    console.log 'Mongo connect called'

  getConnection: () =>
    q = defer()
    if @db
      q.resolve(@db)
    else
      @foo(q)
    return q

  foo: (q) =>
    @cstring = 'mongodb://'+madr+':'+mport+'/spincycle'
    repls = process.env['MONGODB_REPLS']
    rs = process.env['MONGODB_RS']
    if repls
      @cstring = 'mongodb://'+repls+'/spincycle?replicaSet='+rs
      if debug then console.log 'Mongo driver cstring is '+@cstring
      MongoClient.connect @cstring, {fsync: true,  slave_ok: true, replSet:{replicaSet: rs, connectWithNoPrimary: true}}, (err, db) =>
        if err
          console.log 'MONGO Error connecting to "'+@cstring+'" '+err
          console.dir err
          console.log 'retrying.....'
          setTimeout(
            ()=>
              @foo(q)
            2000)
        else
          console.log("---- We are connected ---- *")
          @db = db
          rs=[]
          rarr = repls.split ","
          rarr.forEach (repl) ->
            parts = repl.split ":"
            rs.push {host: parts[0], port: parts[1]}
          console.log 'watcher replicas ---->'
          console.dir rs

          q.resolve(db)
    else
      if debug then console.log 'Mongo driver cstring is '+@cstring
      MongoClient.connect @cstring, {fsync: true,  slave_ok: true}, (err, db) =>
        if err
          console.log 'MONGO Error connecting to "'+@cstring+'" '+err
          console.dir err
          console.log 'retrying.....'
          setTimeout(
            ()=>
              @foo(q)
            2000)
        else
          console.log("---- We are connected ----")
          @db = db
          q.resolve(db)

  getDbFor: (_type) =>
    q = defer()
    type = _type.toLowerCase()
    db = @dbs[type]
    if not db
      @getConnection().then (connection) =>
        connection.collection(type, (err, ndb) =>
          if err
            console.log 'MONGO Error getting collection: '+err
            console.dir err
            q.resolve(null)
          else
            @dbs[type] = ndb
            repls = process.env['MONGODB_REPLS']
            if repls
              #-----------------------------------------------------------------
              oplog = MongoOplog('mongodb://'+repls+'/local', { ns: 'spincycle.'+type }).tail()
              oplog.on 'insert', (doc) =>
                console.log('insert '+type+' --> '+doc.op._id)
                console.dir doc
              oplog.on 'update', (doc) =>
                console.log('update '+type+' --> '+doc.o.id)
                @DB.onUpdated(doc.o)
                #console.dir doc
              oplog.on 'delete', (doc) =>
                console.log('delete '+type+' --> '+doc.op._id)
                console.dir doc
              #-----------------------------------------------------------------
            q.resolve(ndb)
        )
    else
      q.resolve(db)
    return q

  all: (_type, cb)=>
    if debug then console.log 'Mongo::all called for type '+_type
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      if collection
        if debug then console.log 'Mongo.all collection is '+collection
        collection.find {},(err,res) =>
          res.toArray (err, items) =>
            if err
              console.log 'MONGO Error getting all: '+err
              console.dir err
              cb(null)
            else
              cb (items)
      else
        cb (null)

  count: (_type)=>
    if debug then console.log 'Mongo::count called for type '+_type
    type = _type.toLowerCase()
    q = defer()
    @getDbFor(type).then (collection) =>
      if collection
        collection.count {},(err,count) =>
          if err
            console.log 'MONGO count Error: '+err
            console.dir err
            cb(-1)
          else
            q.resolve(count)
      else
        console.log '!!!!! Mongo.count could not get collection!!!!!!!!  '+collection
        cb (-1)
    return q

  get: (_type, id, cb) =>
    type = _type.toLowerCase()
    #console.log 'Mongo.get called for type '+type+' and id '+id
    if typeof id == 'object'
      console.log 'Mongo.get got an object as id instead of string !!!!! '
      #console.dir id
      cb(null)
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
          if debug then console.log 'Mongo byProviderId for '+pid+' got back'
          if debug then console.dir item
          q.resolve(item)

    return q

  # This is not easily implementable in couch, so now we're diverging
  find: (_type, property, value) =>
    if debug then console.log 'Mongo find called for type '+_type+' property '+property+' and value '+value
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      query = {}
      query[property] = value
      if debug then console.log 'query is '
      if debug then console.dir query
      collection.findOne query, (err, item) =>
        if err
          console.log 'MONGO find Error: '+err
          console.dir err
          q.resolve(null)
        else if not item[property] == value
          q.resolve(null)
        else
          if debug then console.log 'find result is '
          if debug then console.dir item
          q.resolve(item)
    return q

  findMany: (_type, property, value) =>
    if debug then console.log 'Mongo findmany called for type '+_type+' property '+property+' and value '+value
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      query = {}
      query[property] = value
      if debug then console.log 'query is '
      if debug then console.dir query
      collection.find(query).toArray (err, docs)=>
          arr = docs
          if debug then console.log 'findMany returns '+arr.length+' items'
          q.resolve(arr)
    return q

  findQuery: (_type, query) =>
    console.log 'Mongo findQuery called for type '+_type
    if debug then console.dir query
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      value = query.value or ""
      qu = {}
      if query.wildcard then qu[query.property or 'name'] = new RegExp('^'+value)
      options = {}
      if query.limit then options.limit = query.limit
      if query.skip then options.skip = query.skip
      if query.sort then options.sort = query.sort
      console.log 'query is '
      console.dir qu
      if debug then console.log 'options are '
      if debug then console.dir options
      collection.find qu, options, (err, cursor) =>
        if err
          console.log 'MONGO findQuery Error: '+err
          console.dir err
          q.resolve(null)
        else
          arr = []
          cursor.each (err, el) ->
            console.log 'cursor for each element '+el+' err = '+err
            if el == null
              cursor.toArray (err, items) =>
                if debug then console.log 'cursor returns'
                if debug then console.dir items
                console.log 'findQuery returns '+items.length+' items'
                q.resolve(items)
    return q

  search: (_type, property, value) =>
    console.log 'Mongo search called for type '+_type+' property '+property+' and value '+value
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      query = {}
      query[property] = {$regex: '^'+value}
      if debug then console.log 'mongo find query is'
      if debug then console.dir query
      collection.find query, (err, items) =>
        if err
          console.log 'MONGO search Error: '+err
          console.dir err
          q.resolve(null)
        else
          items.toArray (err2, docs)=>
            if err2
              console.log 'MONGO search toArray Error: '+err2
              console.dir err2
            else
              q.resolve(docs)
    return q

  set: (_type, obj, cb)=>
    type = _type.toLowerCase()
    @getDbFor(type).then (collection) =>
      #console.log 'Mongo.set called for type '+type+' and id '+obj.id
      if typeof obj.id == 'object' then console.dir obj
      collection.update {id: obj.id}, obj,{ upsert: true },(err, result, details) =>
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