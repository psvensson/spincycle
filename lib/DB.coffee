defer           = require('node-promise').defer
all             = require('node-promise').all
uuid            = require('node-uuid')
LRU             = require('lru-cache')

OStore          = require('./OStore')

#GDS            = require('./gds')
#Roach          = require('./cockroach')
Couch           = require('./CouchPersistence')
Mongo           = require('./MongoPersistence')

debug = process.env["DEBUG"]

class DB

  @lru: LRU()
  @lrudiff: LRU()

  @getDataStore: (name) =>
    if not @DataStore
      #@DataStore = new GDS()
      #@DataStore = new Roach()
      if not name
        @DataStore = new Mongo()
      else if name == 'couchdb'
        @DataStore = new Couch()
      else if name == 'mogodbdb'
        @DataStore = new Mongo()
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
        console.log 'DB.get find type '+type+', property '+property+', value '+value+' got back '+result
      else
        @lru.set(id, result)
      q.resolve(result)
    return q

  @get: (type, ids) =>
    #if debug then console.log 'DB.get called for type "'+type+'" and ids "'+ids+'"'
    if not ids.length then ids = [ids]
    q = defer()
    all(ids.map(
      (id) =>
        rv = @lru.get id
        p = defer()
        #console.log 'DB found in lru: '+rv
        if not rv
          #if debug then console.log ' attempting to use datastore for '
          @getDataStore().get(type, id, (result) =>
            if not result then console.log 'DB.get for type '+type+' and id '+id+' got back '+result
            @lru.set(id, result)
            p.resolve(result)
          )
        else
          p.resolve(rv)
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
