defer           = require('node-promise').defer
all             = require('node-promise').all
uuid            = require('node-uuid')
LRU             = require('lru-cache')

#GDS            = require('./gds')
#Roach          = require('./cockroach')
Couch           = require('./CouchPersistence')

debug = process.env["DEBUG"]

class DB

  @lru: LRU()
  @lrudiff: LRU()

  @getDataStore: () =>
    if not @DataStore
      #@DataStore = new GDS()
      #@DataStore = new Roach()
      @DataStore = new Couch()
      @DataStore.connect()
    return @DataStore

  @createDatabases:(dblist) =>
    store = @getDataStore()
    q = defer()
    promises = []
    dblist.forEach (dbname) =>
      promises.push store.getDbFor(dbname)
    all(promises).then (results) =>
      q.resolve(results)

    return q

  @all: (type, cb) =>
    store = @getDataStore()
    if store.all
      store.all(type, cb)
    else
      console.log 'DB.all: All not implemented in underlying persistence logic'
      cb []

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
