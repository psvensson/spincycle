promise         = require('node-promise').Promise
all             = require('node-promise').all
uuid            = require('node-uuid')
LRU             = require('lru-cache')

#GDS            = require('./gds')
#Roach          = require('./cockroach')
Couch           = require('./CouchPersistence')

class DB

  @lru: LRU()
  @lrudiff: LRU()


  @getDataStore: () =>
    if not @DataStore
      #@DataStore = new GDS()
      #@DataStore = new Roach()
      @DataStore = new Couch()
      @DataStore.connect()

    @DataStore

  @createDatabases:(dblist) =>
    dblist.forEach (dbname) =>
      @DataStore.getDbFor(dbname)

  @all: (type, cb) =>
    store = @getDataStore()
    if store.all
      store.all(type, cb)
    else
      console.log 'DB.all: All not implemented in underlying persistence logic'
      cb []

  @get: (type, ids) =>
    #console.log 'DB.get called for type "'+type+'" and ids "'+ids+'"'
    q = new promise()
    all(ids.map((id) =>
      rv = @lru.get id
      p = new promise()
      #console.log 'DB found in lru: '+rv
      if not rv
        #console.log ' attempting to use datastore'
        @getDataStore().get type, id, (result) =>
          @lru.set(id, result)
          p.resolve(result)
      else
        p.resolve(rv)
      return p
    )).then((result) ->
      #console.log 'DB.get resolving ->'
      #console.dir result
      q.resolve(result)
    )
    return q

  @set: (type, obj, cb) =>
    #console.log 'DB.set called for type "'+type+'" and obj "'+obj.id+'"'
    @lru.set(obj.id, obj)
    @getDataStore().set type, obj, (res) ->
      if cb then cb()


module.exports = DB
