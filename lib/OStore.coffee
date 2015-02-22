defer           = require('node-promise').defer

DB              = require('./DB')
uuid            = require('node-uuid')
error           = require('./Error').error

class OStore

  @objects: []
  @listeners: []

  @storeObject: (obj) =>
    OStore.objects[obj.id] = obj

    list = OStore.listeners[obj.id] or []
    for lid, listener of list
      listener(obj.toClient())

  @getObject: (id, type) =>
    q = defer()
    q.resolve(OStore.objects[id])
    return q

  @updateObj = (record) ->
    console.log 'oStore.updateObj called for obj '+record
    obj = OStore.objects[record.id]
    console.log 'updateObj '+record
    console.dir record

    whitelist = obj.getRecord()
    for p of whitelist
      #console.log 'checking whitelist property '+p
      for pp of record
        #console.log '  comparing to incoming property '+pp
        if pp is p
          #console.log '    match!'
          obj[pp] = record[pp]
    OStore.objects[record.id] = obj
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
