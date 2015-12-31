defer           = require('node-promise').defer

uuid            = require('node-uuid')
error           = require('./Error').error

debug     = process.env["DEBUG"]

class OStore

  @objects:       []
  @types:         []
  @listeners:     []
  @objectsByType: []
  @blackList:     ['id', 'createdAt', 'createdBy', 'updatedAt', 'admin']
  @outstandingUpates = []
  @updateQueue = []

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
      if debug then console.log 'storeObject storing '+obj.id+' with rev '+obj.rev+" and _rev "+obj._rev
      @sendUpdatesFor(obj, true)

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

  @updateObj = (record, force) ->
    if debug then console.log '+ oStore.updateObj called for obj '+record.id
    #console.log 'updateObj '+record
    #console.dir record
    obj = OStore.objects[record.id]
    if obj
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
              if obj[pp] != record[pp] or (record[pp] and obj[pp].length and obj[pp].length != record[pp].length) or force == true
                clean = @makeClean(record[pp])
                if clean
                  diff[pp] = clean
                  changed = true
                  obj[pp] = clean
                  if debug then console.log '** updating property "'+pp+'" on '+obj.type+' id '+record.id+' to '+record[pp]

      OStore.objects[record.id] = obj
      if not OStore.outstandingUpates[obj.id]
        OStore.outstandingUpates[obj.id] = obj
        OStore.sendUpdatesFor(obj, changed)
    else
      console.log 'OStore: tried to update an object which we did not have in cache!'

  @makeClean: (property) ->
    rv = ""
    if property and property isnt null and property isnt "undefined" and property isnt "null"
      if property.filter
        rv = property.filter (item)-> item and item isnt null and item isnt "undefined" and item isnt "null"
      else
        rv = property
    rv

  @sendUpdatesFor: (obj, changed) =>
    if debug then console.log 'sendUpdatesFor called for obj '+obj.id+' changed = '+changed+', OStore.outstandingUpates[obj.id] = '+OStore.outstandingUpates[obj.id]
    if not OStore.outstandingUpates[obj.id] and changed
      OStore.outstandingUpates[obj.id] = obj
      #console.log 'adding obj to updateQueue..'
      #console.dir obj
      OStore.updateQueue.push obj

  @sendAllUpdatesFor: (obj, changed) =>
    sendobj = {id: obj.id, type:obj.type, list:[], toClient: () -> {id: obj.id, type:obj.type, list:sendobj.list}}
    count = obj.list.length
    obj.list.forEach (id) =>
      OStore.getObject(id, obj.type).then (o) =>
        if debug then console.log 'sendAllUpdatesFor adding list object '+id
        #if debug then console.dir o
        sendobj.list.push o.toClient()
        if --count == 0
          if changed
            OStore.updateQueue.push sendobj

  @addListenerFor:(id, type, cb) =>
    #console.log 'OStore::addListenerFor called with type:'+type+' id '+id
    list = OStore.listeners[id] or []
    listenerId = uuid.v4()
    list[listenerId] = cb
    OStore.listeners[id] = list
    #console.log 'listeners list is now'
    #console.dir OStore.listeners[id]
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
    if debug then console.log 'removing listener for object '+id
    if debug then console.log 'listeners list is now'
    if debug then console.dir OStore.listeners[id]

  @sendAtInterval: () =>
    #console.log '-------------------------------------------------------sendAtInterval called '
    #console.dir OStore.updateQueue
    if OStore.updateQueue.length > 0
      #console.log 'queue length = '+OStore.updateQueue.length
      l = if OStore.updateQueue.length > 100 then 100 else OStore.updateQueue.length
      count = 0
      while count < l
        count++
        obj = OStore.updateQueue.shift()
        last = obj._lastUpdate or 0
        diff = Date.now() - last
        obj._lastUpdate = Date.now()
        if(diff > 100)
          #console.dir OStore.listeners
          listeners = OStore.listeners[obj.id] or []
          for lid of listeners
            #console.log 'sending to listener '+lid+' -> '+listeners[lid]
            listeners[lid](obj)
          delete OStore.outstandingUpates[obj.id]
      #console.log 'queue length after send = '+OStore.updateQueue.length
    setTimeout(@sendAtInterval,100)

  @sendAtInterval()

module.exports = OStore
