defer           = require('node-promise').defer

uuid            = require('node-uuid')
error           = require('./Error').error

debug = process.env["DEBUG"]

class OStore

  @objects:       []
  @types:         []
  @listeners:     []
  @objectsByType: []
  @blackList:     ['id', 'createdAt', 'createdBy', 'updatedAt', 'admin']

  @listObjectsByType: (type) =>
    rv = []
    if debug then console.log 'OStore::listObjectsByType called for type '+type
    v = @objectsByType[type]
    for kk,vv of v
      if vv
        rv.push vv
        if debug then console.log 'adding '+vv.name
    return rv

  @listTypes: () =>
    rv = []
    console.log 'listTypes called'
    console.dir @types
    for k,v of @types
      rv.push v
    return rv

  @storeObject: (obj) =>
    if obj
      OStore.objects[obj.id] = obj
      OStore.types[obj.type] = obj.type
      objs = OStore.objectsByType[obj.type] or []
      objs[obj.id] = obj
      OStore.objectsByType[obj.type] = objs
      #console.log 'storeObject storing '+obj.id+' with rev '+obj.rev+" and _rev "+obj._rev
      list = OStore.listeners[obj.id] or []
      for lid, listener of list
        listener(obj)

  @getObject: (id, type) =>
    q = defer()
    obj = OStore.objects[id]
    if obj
      #console.log 'getObject getting '+obj.id+' with rev '+obj.rev+" and _rev "+obj._rev
    else
      #console.log '-- * -- getObject could not find object type '+type+' with id '+id
    q.resolve(obj)
    return q

  @removeObject: (obj) =>
    if obj and obj.id
      delete OStore.objects[obj.id]
      objs = @objectsByType[obj.type] or []
      if objs[obj.id] then delete objs[obj.id]
      OStore.objectsByType[obj.type] = obj

  @updateObj = (record) ->
    console.log 'oStore.updateObj called for obj '+record.id
    #console.log 'updateObj '+record
    #console.dir record
    obj = OStore.objects[record.id]
    whitelist = obj.getRecord() #FFS
    delete whitelist.id
    diff = {}
    changed = false;
    record.modifiedAt = Date.now()
    for p of whitelist
      #if debug then console.log 'checking whitelist property '+p
      for pp of record
        #if debug then console.log '  comparing to incoming property '+pp
        if pp is p
          #if debug then console.log '    match!'
          if pp not in OStore.blackList
            if debug then console.log 'not in blacklist. obj prop is'
            if debug then console.dir obj[pp]
            if debug then console.log 'record prop is'
            if debug then console.dir record[pp]
            if obj[pp] != record[pp] or (record[pp] and obj[pp].length and obj[pp].length != record[pp].length)
              diff[pp] = record[pp]
              changed = true
              obj[pp] = record[pp]
              console.log 'updating property "'+pp+'" on '+obj.type+' id '+record.id+' to '+record[pp]

    OStore.objects[record.id] = obj
    OStore.sendUpdatesFor(obj, changed)

  @sendUpdatesFor: (obj, changed) =>
    listeners = OStore.listeners[obj.id] or []
    if changed
      for lid of listeners
        listeners[lid](obj)

  @sendAllUpdatesFor: (obj, changed) =>
    sendobj = {id: obj.id, type:obj.type, list:[], toClient: () -> {id: obj.id, type:obj.type, list:sendobj.list}}
    count = obj.list.length
    obj.list.forEach (id) =>
      OStore.getObject(id, obj.type).then (o) =>
        if debug then console.log 'sendAllUpdatesFor adding list object '+id
        if debug then console.dir o
        sendobj.list.push o.toClient()
        if --count == 0
          listeners = OStore.listeners[obj.id] or []
          if changed
            for lid of listeners
              listeners[lid](sendobj)

  """

    !!!!!!!!!!!!!!!!!!!!!!!!  FFS !!!!!!!!!!!!!!!!
    MAKE SURE TO REMOVE LISTENERES WHEN CLIENTENDPOINTS DROPS OUT

  """
  @addListenerFor:(id, type, cb) =>
    console.log 'OStore::addListenerFor called with type:'+type+' id '+id
    list = OStore.listeners[id] or []
    listenerId = uuid.v4()
    list[listenerId] = cb
    OStore.listeners[id] = list
    console.log 'listeners list is now'
    console.dir OStore.listeners[id]
    #@getObject(id, type).then((result) ->
    #  cb(result)
    #, error)
    return listenerId

  @removeListenerFor: (id, listenerId) =>
    list = OStore.listeners[id] or []
    delete list[listenerId]
    tmp = []
    for i, cb of list
      tmp[i] = cb if cb
    OStore.listeners[id] = tmp

module.exports = OStore
