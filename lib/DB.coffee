defer           = require('node-promise').defer
all             = require('node-promise').all
uuid            = require('node-uuid')
LRU             = require('lru-cache')

OStore          = require('./OStore')

#GDS            = require('./gds')
#Roach          = require('./cockroach')
Couch           = require('./CouchPersistence')
Mongo           = require('./MongoPersistence')
Rethink         = require('./RethinkPersistence')
Google          = require('./GooglePersistence')

ResolveModule   = require('./ResolveModule')


resolver  = new ResolveModule()
debug = process.env["DEBUG"]

class DB

  @dburl: 'localhost'
  @lru: LRU()
  @lrudiff: LRU()

  @onUpdated: (record)=>
    OStore.updateObj(record)

  @getDataStore: (name) =>
    #console.log 'DB.getDataStore called '
    q = defer()
    if not @DataStore
      #@DataStore = new GDS()
      #@DataStore = new Roach()
      if not name then @DataStore = new Rethink(DB.dburl, DB)
      #if not name then @DataStore = new Google(DB.dburl, DB)
      else if name == 'couchdb' then @DataStore = new Couch(DB.dburl)
      else if name == 'mongodb' then @DataStore = new Mongo(DB.dburl, DB)
      else if name == 'rethinkdb' then @DataStore = new Rethink(DB.dburl, DB)
      else if name == 'google' then @DataStore = new Google(DB.dburl, DB)
      @DataStore.connect().then (ds)=>
        @DataStore = ds
        console.log 'DB got back datastore'
        q.resolve(ds)
    else
      q.resolve(@DataStore)
    return q

  @createDatabases:(dblist) =>
    q = defer()
    console.log 'createDatabases called'
    @getDataStore().then (store)=>
      console.log 'DB.createDatabases got back store'
      promises = []
      dblist.forEach (dbname) =>
        console.log 'attempting to get table for '+dbname
        promises.push store.getDbFor(dbname)
      all(promises).then (results) =>
        console.log 'DB.createDatabases all good'
        q.resolve(results)
    return q

  @getFromStoreOrDB: (type, id) =>
    #console.log 'DB.getFromStoreOrDb called for '+type+' id '+id
    q = defer()
    OStore.getObject(id, type).then (oo)=>
      if oo
        #console.log 'getFromStoreOrDb resolved from Ostore directly...'
        q.resolve(oo)
      else
        @get(type, [id]).then (records) =>
          #console.log 'DB.getFromStoreOrDb get returns..'
          #console.dir records
          if records and records[0]
            record = records[0]
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
          #if debug then console.dir res
          if res and res[0]
            if debug then console.log 'DB.getOrCreateObjectByRecord found existing record in DB *'
            record = res[0]
          resolver.createObjectFrom(record).then (ooo) =>
            if debug then console.log 'DB.getOrCreateObjectByRecord createFromRecord returns '+ooo
            q.resolve(ooo)
    return q

  @byProviderId: (type, pid) =>
    q = defer()
    if pid
      @getDataStore().then (store)=>
        store.byProviderId(type, pid).then (res) =>
          q.resolve(res)
    else
      q.resolve(undefined)
    return q

  @all: (type, query, cb) =>
    @getDataStore().then (store)=>
      if store.all
        store.all(type, query, cb)
      else
        console.log 'DB.all: All not implemented in underlying persistence logic'
        cb []

  @count: (type) =>
    q = defer()
    @getDataStore().then (store)=>
      store.count(type).then (value)=>
        q.resolve(value)
    return q

  @find: (type, property, value) =>
    q = defer()
    @getDataStore().then (store) => store.find(type, property, value).then (result) =>
      if not result
        console.log 'DB.find type '+type+', property '+property+', value '+value+' got back '+result
      else
        @lru.set(result.id, result)
      q.resolve(result)
    return q

  @findMany: (type, property, value) =>
    q = defer()
    @getDataStore().then (store) => store.findMany(type, property, value).then (results) =>
      #if debug then console.log 'DB.findMany results are..'
      #if debug then console.dir results
      if not results or not results.length
        console.log 'DB.find type '+type+', property '+property+', value '+value+' got back '+results
        q.resolve([])
      else
        results.forEach (result) => @lru.set(result.id, result)
        q.resolve(results)
    return q

  @findQuery: (type, query) =>
    q = defer()
    @getDataStore().then (store)=> store.findQuery(type, query).then (results) =>
      if results and results.length and results.length > 0
        #if debug then console.log ' DB.findQuery got back '
        #if debug then console.dir results
        results.forEach (result) =>
          #console.dir result
          if result then @lru.set(result.id, result)
      q.resolve(results)
    return q

  # search for wildcards for property as a string beginning with value..
  @search: (type, property, value) =>
    q = defer()
    @getDataStore().then (store)=> store.search(type, property, value).then (results) =>
      console.log 'DB.search results were..'
      console.dir results
      if not results
        console.log 'DB.search type '+type+', property '+property+', value '+value+' got back '+results
      else
        results.forEach (result) => @lru.set(result.id, result)
      q.resolve(results)
    return q

  @get: (type, ids) =>
    #if debug then console.log 'DB.get called for type "'+type+'" and ids "'+ids+'"'
    if not ids.length then ids = [ids]
    q = defer()
    bam = false

    all(ids.map(
      (id) =>
        try
          rv = @lru.get id
        catch err
          console.log '************* ERROR '
          console.dir arguments
          console.dir err
        p = defer()
        #console.log 'DB found '+id+'  in lru: '+rv
        if not rv
          #if debug then console.log ' attempting to use datastore for type '+type+' and id '+id+' typeof = '+(typeof id)
          if (typeof id == 'object')
            console.log 'DB.get was served an object instead of an id!!!'
            console.dir id
            q.resolve(null)
          else
            @getDataStore().then (store)=>
              #if debug then console.log 'DB.get calling datastore '+store
              store.get(type, id, (result) =>
                if not result
                  if debug
                    console.log 'DB.get for type '+type+' and id '+id+' got back '+result
                    bam = false
                else
                  @lru.set(id, result)
                if not bam
                  #if debug then console.log 'DB.get resolving '+result
                  p.resolve(result)
                bam = true
              )
        else
          if not bam then p.resolve(rv)
          bam = true
        return p
    )).then(
      (result) ->
        q.resolve(result)
      ,(err) ->
        console.log 'DB.get ERROR: '+err
        console.dir err
        q.resolve(null)
    )
    return q

  @set: (type, obj, cb) =>
    if obj
      @lru.set(obj.id, obj)
      @getDataStore().then (store)=> store.set type, obj, (res) ->
        if cb then cb(res)
    else
      cb()

  @remove: (obj, cb) =>
    @lru.del obj.id
    @getDataStore().then (store)=> store.remove obj.type, obj, (res) ->
      if cb then cb(res)


module.exports = DB
