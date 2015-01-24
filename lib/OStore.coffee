defer           = require('node-promise').defer

DB              = require('./DB')
uuid            = require('node-uuid')
error           = require('./Error').error

class OStore

  @objects: []
  @listeners: []

  @storeObj: (obj) =>
    OStore.objects[obj.id] = obj

    list = OStore.listeners[obj.id] or []
    for lid, listener of list
      listener(diff)

  @getObj: (id, type) =>
    q = defer()
    q.resolve(OStore.objects[id])
    return q

  @updateObj = (kv) ->
    obj = OStore.objects[kv.id]
    #console.log 'updateObj '+
    whitelist = obj.getRecord()
    for p of whitelist
      for pp of kv
        if pp is p
          obj[pp] = kv[pp]
    list = OStore.listeners[obj.id] or []
    for lid of list
      listener = list[lid]
      listener(obj)
    return

  @addListenerFor:(id, type, cb) =>
    list = OStore.listeners[id] or []
    listenerId = uuid.v4()
    list[listenerId] = cb
    OStore.listeners[id] = list
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
