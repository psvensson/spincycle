#Game            = require('./models/Game')
#Entity          = require('./models/Entity')
#Player          = require('./models/Player')
#Thing           = require('./models/Thing')
#Tile            = require('./models/Tile')
#Zone            = require('./models/Zone')
defer           = require('node-promise').defer

DB              = require('./DB')
uuid            = require('node-uuid')
error           = require('./../Error').error

class OStore

  @objects: []
  @listeners: []

  @storeObj: (obj) =>
    #console.log 'storeObj called for'
    #console.dir obj

    OStore.objects[obj.id] = obj

    list = OStore.listeners[obj.id] or []
    if obj.type is 'entity' then console.log 'oMgr::storeObj there are '+list.length+' listener for '+obj.type+' '+obj.id
    for lid, listener of list
      console.log '+ DB.set sending update for id '+obj.id
      listener(diff)

  @getObj: (id, type) =>
    q = defer()

    resolve = (obj) =>
      @storeObj(obj)
      q.resolve(obj)

    q.resolve(OStore.objects[id])
    ###rv = OStore.objects[id]
    if rv
      q.resolve(rv)
    else
      DB.get(id, type).then (record) =>
        switch type
          when 'game'   then new Game(record).then((gobj)     => resolve(gobj))
          when 'zone'   then new Zone(record).then((zobj)     => resolve(zobj))
          when 'entity' then new Entity(record).then((eobj)   => resolve(eobj))
          when 'player' then new Player(record).then((pobj)   => resolve(pobj))
          when 'thing'  then new Thing(record).then((tobj)    => resolve(tobj))
          when 'tile'   then new Tile(record).then((tobj)     => resolve(tobj))###
    return q

  @updateObj = (kv) ->
    obj = OStore.objects[kv.id]
    #console.log 'updateObj '+
    whitelist = obj.getRecord()
    for p of whitelist
      for pp of kv
        #console.log ' comparing if whitelist '+p+' is incoming property '+pp
        if pp is p
          console.log '  object update property '+p+' was in whitelist'
          obj[pp] = kv[pp]
    list = OStore.listeners[obj.id] or []
    console.log "-- oMgr::storeObj there are " + list.length + " listener for " + obj.type + " " + obj.id
    for lid of list
      listener = list[lid]
      console.log "--  oMgr.set sending update for id " + obj.id
      listener(obj)
    return

  @addListenerFor:(id, type, cb) =>
    list = OStore.listeners[id] or []
    listenerId = uuid.v4()
    list[listenerId] = cb
    OStore.listeners[id] = list
    console.log('--  oMgr adding listener for id '+id)
    console.log '-- sending first update of object as baseline..'
    @getObj(id, type).then((result) ->
      cb(result)
    , error)
    return listenerId

  @removeListenerFor: (id, listenerId) =>
    list = OStore.listeners[id] or []
    delete list[listenerId]
    tmp = []
    for i, cb of list
      tmp[i] = cb if cb
    OStore.listeners[id] = tmp

module.exports = OStore
