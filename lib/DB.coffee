defer           = require('node-promise').defer
all             = require('node-promise').all
uuid            = require('node-uuid')
LRU             = require('lru-cache')

OStore          = require('./OStore')

#GDS            = require('./gds')
#Roach          = require('./cockroach')
Couch           = require('./CouchPersistence')
Mongo           = require('./MongoPersistence')
ResolveModule   = require('./ResolveModule')


resolver  = new ResolveModule()
debug = process.env["DEBUG"]

class DB

  @dburl: 'localhost'
  @lru: LRU()
  @lrudiff: LRU()

  @getDataStore: (name) =>
    if not @DataStore
      #@DataStore = new GDS()
      #@DataStore = new Roach()
      if not name
        @DataStore = new Mongo(DB.dburl)
      else if name == 'couchdb'
        @DataStore = new Couch(DB.dburl)
      else if name == 'mongodb'
        @DataStore = new Mongo(DB.dburl)
      @DataStore.connect()
    return @DataStore

  @createDatabases:(dblist) =>
    store = @getDataStore()
    q = defer()
    promises = []
    dblist.forEach (dbname) =>
      if debug then console.log 'attempting to get store for '+dbname
      obj =
      {
        id: 'all_'+dbname
        type: dbname
        list: []
        getRecord: ()->
          {type: dbname, id: obj.id, list: obj.list}
        toClient: ()->
          obj.getRecord()
      }
      console.log '------ creating original all_'+dbname+' collection objects ---'
      #console.dir OStore
      OStore.storeObject(obj)
      promises.push store.getDbFor(dbname)
    all(promises).then (results) =>
      q.resolve(results)
    return q

  @getFromStoreOrDB: (type, id) =>
    q = defer()
    OStore.getObject(id, type).then (oo)=>
      if oo
        q.resolve(oo)
      else
        @get(type, [id]).then (records) =>
          if records and records[0]
            record = record[0]
            resolver.createObjectFrom(record).then (ooo) =>
              q.resolve(ooo)
          else
            q.resolve(undefined)
    return q

  @getOrCreateObjectByRecord: (record) =>
    q = defer()
    OStore.getObject(record.id, record.type).then (oo)=>
      if debug then console.log 'DB.getOrCreateObjectByRecord OStore returns '+oo
      if oo
        q.resolve(oo)
      else
        @get(record.type, [record.id]).then (res)=>
          if debug then console.log 'DB.getOrCreateObjectByRecord DB load returns '+res
          if debug then console.dir res
          if res and res[0]
            console.log '* found existing record in DB *'
            record = res[0]
          resolver.createObjectFrom(record).then (ooo) =>
            if debug then console.log 'DB.getOrCreateObjectByRecord createFromRecord returns '+ooo
            q.resolve(ooo)
    return q

  @byProviderId: (type, pid) =>
    q = defer()
    store = @getDataStore()
    store.byProviderId(type, pid).then (res) =>
      q.resolve(res)
    return q

  @all: (type, cb) =>
    store = @getDataStore()
    if store.all
      store.all(type, cb)
    else
      console.log 'DB.all: All not implemented in underlying persistence logic'
      cb []

  @find: (type, property, value) =>
    q = defer()
    @getDataStore().find(type, property, value).then (result) =>
      if not result
        console.log 'DB.find type '+type+', property '+property+', value '+value+' got back '+result
      else
        @lru.set(result.id, result)
      q.resolve(result)
    return q

  @findMany: (type, property, value) =>
    q = defer()
    @getDataStore().findMany(type, property, value).then (results) =>
      if not result
        console.log 'DB.find type '+type+', property '+property+', value '+value+' got back '+results.length+' results'
      else
        results.forEach (result) => @lru.set(result.id, result)
      q.resolve(results)
    return q

  @findQuery: (type, query) =>
    q = defer()
    @getDataStore().findQuery(type, query).then (results) =>
      if not result
        console.log 'DB.findQuery type '+type+', property '+property+', value '+value+' got back '+results.length+' results'
      else
        results.forEach (result) => @lru.set(result.id, result)
      q.resolve(results)
    return q

  # search for wildcards for property as a string beginning with value..
  @search: (type, property, value) =>
    q = defer()
    @getDataStore().search(type, property, value).then (results) =>
      console.log 'DB.search results were..'
      console.dir results
      if not results
        console.log 'DB.search type '+type+', property '+property+', value '+value+' got back '+results
      else
        results.forEach (result) => @lru.set(result.id, result)
      q.resolve(results)
    return q

  @get: (type, ids) =>
    if debug then console.log 'DB.get called for type "'+type+'" and ids "'+ids+'"'
    if not ids.length then ids = [ids]
    q = defer()
    bam = false
    all(ids.map(
      (id) =>
        rv = @lru.get id
        p = defer()
        #console.log 'DB found in lru: '+rv
        if not rv
          #if debug then console.log ' attempting to use datastore for '
          @getDataStore().get(type, id, (result) =>
            if not result
              console.log 'DB.get for type '+type+' and id '+id+' got back '+result
            else
              @lru.set(id, result)
            if not bam then p.resolve(result)
            bam = true
          )
        else
          if not bam then p.resolve(rv)
          bam = true
        return p
    )).then(
      (result) ->
        #console.log 'DB.get resolving ->'
        #console.dir result
        q.resolve(result)
      ,(err) ->
        console.log 'DB.get ERROR: '+err
        console.dir err
        q.resolve(null)
    )
    return q

  @set: (type, obj, cb) =>
    #console.log 'DB.set called for type "'+type+'" and obj "'+obj.id+'"'
    @lru.set(obj.id, obj)
    @getDataStore().set type, obj, (res) ->
      if cb then cb()

  @remove: (obj, cb) =>
    @lru.del obj.id
    @getDataStore().remove obj.type, obj, (res) ->
      if cb then cb(res)


module.exports = DB
