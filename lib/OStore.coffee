defer           = require('node-promise').defer

DB              = require('./DB')
uuid            = require('node-uuid')
error           = require('./Error').error

class OStore

  @objects: []
  @listeners: []

  @storeObject: (obj) =>
    OStore.objects[obj.id] = obj
    #console.log 'storeObject storing '+obj.id+' with rev '+obj.rev+" and _rev "+obj._rev
    list = OStore.listeners[obj.id] or []
    for lid, listener of list
      listener(obj)

  @getObject: (id, type) =>
    q = defer()
    obj = OStore.objects[id]
    #console.log 'getObject getting '+obj.id+' with rev '+obj.rev+" and _rev "+obj._rev
    q.resolve(obj)
    return q

  @updateObj = (record) ->
    console.log 'oStore.updateObj called for obj '+record.id
    #console.log 'updateObj '+record
    #console.dir record
    obj = OStore.objects[record.id]
    whitelist = obj.getRecord()
    for p of whitelist
      #console.log 'checking whitelist property '+p
      for pp of record
        #console.log '  comparing to incoming property '+pp
        if pp is p
          #console.log '    match!'
          obj[pp] = record[pp]
    OStore.objects[record.id] = obj
    listeners = OStore.listeners[obj.id] or []
    for lid of listeners
      listeners[lid](obj)

  @addListenerFor:(id, type, cb) =>
    list = OStore.listeners[id] or []
    listenerId = uuid.v4()
    list[listenerId] = cb
    OStore.listeners[id] = list
    @getObject(id, type).then((result) ->
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
