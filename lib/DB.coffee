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
  @dbname : ''

  @onUpdated: (record)=>
    if record and record.type and record.id
      resolver.createObjectFrom(record).then (ooo) =>
        OStore.updateObj(ooo)

  @getDataStore: (_name) =>
    name = _name or DB.dbname
    DB.dbname = name
    #console.log 'DB.getDataStore called name = '+name
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
        if debug then console.log 'DB got back datastore for '+name
        q.resolve(ds)
    else
      q.resolve(@DataStore)
    return q

  @createDatabases:(dblist) =>
    q = defer()
    console.log '*** createDatabases called for list of dbs...'
    console.dir dblist
    @getDataStore().then (store)=>
      console.log 'DB.createDatabases got back store'
      promises = []
      dblist.forEach (dbname) =>
        console.log 'attempting to get table for '+dbname
        db = store.getDbFor(dbname)
        promises.push db
      all(promises).then (results) =>
        console.log '*DB.createDatabases all good'
        dblist.forEach (dbname2) => @extendSchemaIfNeeded(DB.DataStore, dbname2)
        q.resolve(results)
    return q

  @extendSchemaIfNeeded:(db,_dbname)=>
    # get schema
    dbname = _dbname
    q = defer()
    console.log '* extendSchemaIfNeeded for module "'+_dbname+'"we have the following modules named in cache:'
    for k,v of ResolveModule.modulecache
      console.log k
    proto = ResolveModule.modulecache[dbname]
    console.log 'extendSchemaIfNeeded resolve '+dbname+' to '+proto
    #console.dir proto
    if not proto
      console.log 'found undefined prototype!. modulecache is'
      #console.dir ResolveModule.modulecache
    db.all dbname,{},(res)=>
      console.log 'extendSchemaIfNeeded found '+res.length+' objects after call to all()'
      #console.log 'first object is '+res[0]
      #console.dir res[0]
      # collect missing properties from first object
      o = res[res.length-1]
      missing = []
      lookup = {createdAt:true, modifiedAt:true, createdBy:true}
      for k,v of o
        lookup[k] = k
      proto.model.forEach (property)=>
        if not lookup[property.name] then missing.push property
      console.log 'found '+missing.length+' missing properties on first object compared to current model : '
      console.dir missing
      if missing.length > 0
        count = res.length*missing.length
        console.log 'adding '+missing.length+' missing properties to '+res.length+' existing objects'
        start = Date.now()
        res.forEach (ro) =>
          missing.forEach (mprop) =>
            if not mprop.default
              if mprop.array then mprop.default = []
              else if mprop.hashtable then mprop.default = {}
              else if mprop.type then mprop.default = ''
            #console.log '   setting new property '+mprop.name+' to default value of '+mprop.default+' on object type '+ro.type+' id '+ro.id
            #ro[mprop.name] = mprop.default or ''
            @extend(ro.type, ro.id, mprop.name, mprop.default).then (o)=>
              @lru.set(o.id, o)
              if --count == 0
                end = Date.now()
                diff = parseInt((end - start)/1000)
                console.log 'extendSchemaIfNeeded done for '+res.length+' objects. runtime = '+diff+' seconds'
                q.resolve()
          #@set ro.type, ro, ()=> if --count == 0 then q.resolve()
      else
        q.resolve()
    return q

  @extend:(type, id, field, def)=> @getDataStore().then (store)=>
    #console.log 'extending '+type+' id '+id+' with new property '+field+' and default value of '+def
    store.extend(type, id, field, def)

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
        console.log 'DB.findMany type '+type+', property '+property+', value '+value+' got back '+results
        q.resolve([])
      else
        results.forEach (result) => @lru.set(result.id, result)
        q.resolve(results)
    return q

  @findQuery: (type, query) =>
    q = defer()
    @getDataStore().then (store)=> store.findQuery(type, query).then (results) =>
      if results and results.length and results.length > 0

        if debug then console.log ' DB.findQuery got back '
        if debug then console.dir results
        results.forEach (result) =>
          #console.dir result
          if result then @lru.set(result.id, result)
      q.resolve(results)
    return q

  # search for wildcards for property as a string beginning with value..
  @search: (type, property, value) =>
    q = defer()
    @getDataStore().then (store)=> store.search(type, property, value).then (results) =>
      #console.log 'DB.search results were..'
     # console.dir results
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
    id = ids[0]
    if (typeof id == 'object')
      console.log 'DB.get was served an object instead of an id!!!'
      console.dir id
      q.resolve(null)
    else
      rv = @lru.get id

      if rv
        if debug then console.log 'DB found '+id+'  in lru: '+rv
        if debug then console.dir rv
        q.resolve([rv])
      else
        #console.log ' attempting to use datastore for type '+type+' and id '+id+' typeof = '+(typeof id)
        @getDataStore().then (store)=>
          #if debug then console.log 'DB.get calling datastore '+store
          store.get(type, id, (result) =>
            if not result
              if debug
                console.log 'DB.get for type '+type+' and id '+id+' got back '+result
                console.dir result
            else
              #if !Array.isArray(result)
                #console.dir result
                #if debug then console.log 'result is not array, so putting it into one..'
                #result = [result]
              @lru.set(id, result)
              #console.log 'DB.get resolving '+result
            q.resolve(result)
            )
    return q

  @set: (type, obj, cb) =>
    if obj
      @lru.set(obj.id, obj)
      @getDataStore().then (store)=>
        store.set type, obj, (res) ->
          if debug then console.log 'DB.set got back '+res
          cb(res)
    else
      cb()

  @remove: (obj, cb) =>
    @lru.del obj.id
    @getDataStore().then (store)=> store.remove obj.type, obj, (res) ->
      if cb then cb(res)


module.exports = DB
