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
      #console.log 'checking whitelist property '+p
      for pp of record
        #console.log '  comparing to incoming property '+pp
        if pp is p
          #console.log '    match!'
          if obj[pp] != record[pp] and pp not in OStore.blackList
            diff[pp] = record[pp]
            changed = true
            obj[pp] = record[pp]
            console.log 'updating property "'+pp+'" on '+obj.type+' id '+record.id+' to '+record[pp]

    OStore.objects[record.id] = obj
    listeners = OStore.listeners[obj.id] or []
    console.log 'there are '+listeners.length+' listeners for object updates. changed = '+changed
    if changed
      for lid of listeners
        listeners[lid](obj)

  @addListenerFor:(id, type, cb) =>
    list = OStore.listeners[id] or []
    listenerId = uuid.v4()
    list[listenerId] = cb
    OStore.listeners[id] = list
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
