util            = require('util')
defer           = require('node-promise').defer
SuperModel      = require('./SuperModel')
e               = require('./EventManager')
DB              = require('./DB')
ClientEndpoints = require('./ClientEndpoints')
objStore        = require('./OStore')
error           = require('./Error').error
uuid            = require('node-uuid')

debug = process.env["DEBUG"]

class ObjectManager

  constructor: (@messageRouter) ->
   @updateObjectHooks = []
   @populationListeners = []
   SuperModel.onCreate (newmodel)=>
     if debug then console.log 'ObjectManager got onCreate event'
     if debug then console.dir newmodel
     if debug then console.dir @populationListeners
     sublist = @populationListeners[newmodel.type] or {}
     #console.log 'sublist for population updtaes is'
     #console.sublist
     for k,client of sublist
       if ClientEndpoints.exists(client)
         console.log 'sending population update create to client '+client
         ClientEndpoints.sendToEndpoint(client, {status: e.general.SUCCESS, info: 'POPULATION_UPDATE', payload: { added: newmodel.toClient() } })


  setup: () =>
    @messageRouter.addTarget('registerForUpdatesOn',  'obj', @onRegisterForUpdatesOn)
    @messageRouter.addTarget('deRegisterForUpdatesOn',  'id,listenerid', @onDeregisterForUpdatesOn)
    @messageRouter.addTarget('updateObject',          'obj', @onUpdateObject)
    @messageRouter.addTarget('listTypes',             '<noargs>', @onListTypes)
    @messageRouter.addTarget('getModelFor',             'modelname', @onGetModelFor)
    @messageRouter.addTarget('getAccessTypesFor',             'modelname', @onGetAccessTypesFor)
    @messageRouter.addTarget('registerForPopulationChangesFor', 'type', @onRegisterForPopulationChanges)
    @messageRouter.addTarget('deRegisterForPopulationChangesFor', 'id,listenerid', @onDeregisterForPopulationChanges)

  registerUpdateObjectHook: (hook) =>
    @updateObjectHooks.push hook

  onListTypes: (msg) =>
    msg.replyFunc({status: e.general.SUCCESS, info: 'list types', payload: objStore.listTypes()})

  onGetAccessTypesFor: (msg) =>
    if msg.modelname
      rv =
        create: @messageRouter.authMgr.canUserCreateThisObject(msg.modelname, msg.user)
        read:   @messageRouter.authMgr.canUserReadFromThisObject(msg.modelname, msg.user)
        write:  @messageRouter.authMgr.canUserWriteToThisObject(msg.modelname, msg.user)
        list:   @messageRouter.authMgr.canUserListTheseObjects(msg.modelname, msg.user)

      msg.replyFunc({status: e.general.SUCCESS, info: 'access types for '+msg.modelname, payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "getAccessTypesFor missing parameter", payload: null})

  onGetModelFor: (msg) =>
    if msg.modelname
      @messageRouter.resolver.resolve msg.modelname, (path) =>
        if debug then console.log 'onGetModelFor '+msg.modelname+' got back require path '+path
        model = require(path)
        if debug then console.log 'got model resolved to'
        if debug then console.dir model.model
        rv = []
        model.model.forEach (property) -> if property.public then rv.push(property)
        msg.replyFunc({status: e.general.SUCCESS, info: 'get model', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "getModelFor missing parameter", payload: null})

  #---------------------------------------------------------------------------------------------------------------------
  _createObject: (msg) =>
    if msg.obj and msg.obj.type
      if @messageRouter.authMgr.canUserCreateThisObject(msg.obj.type, msg.user)
        if debug then console.log 'objmgr.createObject called'
        if debug then console.dir msg
        msg.obj.createdAt = Date.now()
        msg.obj.modifiedAt = Date.now()
        msg.obj.createdBy = msg.user.id
        if debug then console.log 'objmgr.createObject called. record is now'
        if debug then console.dir msg.obj
        SuperModel.resolver.createObjectFrom(msg.obj).then (o) =>
          o.serialize().then () =>
            msg.replyFunc({status: e.general.SUCCESS, info: 'new '+msg.obj.type, payload: o})
      else
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to create objects of that type', payload: msg.obj.type})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_createObject missing parameter', payload: null })

  _deleteObject: (msg) =>
    console.log 'delete called'
    if msg.obj and msg.obj.type and msg.obj.id
      console.log 'delete got type '+msg.obj.type+', and id '+msg.obj.id
      objStore.getObject(msg.obj.id, msg.obj.type).then (obj) =>
        console.log 'got object form objstore -> '+obj
        if obj
          if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user, msg.obj)
            #console.log 'user could write this object'
            #console.dir obj
            DB.remove obj, (removestatus) =>
              console.log 'object removed callback'
              sublist = @populationListeners[msg.type] or {}
              for k,client of sublist
                if ClientEndpoints.exists(client)
                  console.log 'updating population changes callback'
                  ClientEndpoints.sendToEndpoint(client, {status: e.general.SUCCESS, info: 'POPULATION_UPDATE', payload: { removed: obj.toClient() } })
              objStore.removeObject(obj)
              console.log 'object removed from objstore'
              msg.replyFunc({status: e.general.SUCCESS, info: 'delete object', payload: obj.id})
          else
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to delete object', payload: msg.obj.id})
        else
          console.log 'No object found with id '+msg.obj.id
          console.dir objStore.objects.map (o) -> o.type == msg.obj.type
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_deleteObject missing parameter', payload: null })

  _updateObject: (msg) =>
    @onUpdateObject(msg)

  _getObject: (msg) =>
    if debug then console.log '_getObject called for type '+msg.type
    if debug then console.dir msg.obj
    if msg.type and msg.obj and msg.obj.id
      id = msg.obj.id
      if id.indexOf and id.indexOf('all_') > -1
        @getAggregateObjects(msg)
      else
        if debug then console.log '_getObject calling getObjectPullThrough for type '+msg.type
        @getObjectPullThrough(id, msg.type).then (obj) =>
          if debug then '_getObject got back obj from getObjectPullThrough: '
          if debug then console.dir obj
          if obj
            if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
              tc = obj.toClient()
              if debug then console.log '_getObject for '+msg.type+' returns'
              if debug then console.dir tc
              msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: tc})
            else
              console.log '_getObject got NOT ALLOWED for user '+msg.user.id+' for '+msg.type+' id '+obj.id
              msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to read from that object', payload: id})
          else
            console.log '_getObject No object found with id '+id+' of type '+msg.obj.type
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'no such object', payload: msg.obj.id})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_getObject for '+msg.type+' missing parameter', payload: null })

  getAggregateObjects: (msg) =>
    if not @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user)
      msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
    else
      rv = objStore.listObjectsByType(msg.obj.type)
      obj = {id: msg.obj.id, list: rv}
      msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj})

  _listObjects: (msg) =>
    if debug then console.log 'listObjects called for type '+msg.type
    if typeof msg.type != 'undefined'
      if @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user) == no
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
      else
        if msg.query
          if debug then console.log 'executing query for property '+msg.query.property+', value '+msg.query.value
          if msg.query.limit or msg.query.skip or msg.query.sort or msg.query.wildcard
            if msg.query.value and msg.query.value != ''
              DB.findQuery(msg.type, msg.query).then (records) => @parseList(records, msg)
            else
              DB.all(msg.type, msg.query, (records) => @parseList(records, msg))
          else
            DB.findMany(msg.type, msg.query.property, msg.query.value).then (records) => @parseList(records, msg)
        else
          DB.all(msg.type, msg.query, (records) => @parseList(records, msg))
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_listObjects missing parameter', payload: null })

  _countObjects: (msg) =>
    console.log 'countObjects called for type '+msg.type
    if typeof msg.type != 'undefined'
      if @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user) == no
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to count objects of type '+msg.type, payload: msg.type})
      else
        DB.count(msg.type).then (v)=>
          msg.replyFunc({status: e.general.SUCCESS, info: 'count objects', payload: v})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_listObjects missing parameter', payload: null })

  parseList: (_records, msg) =>

    checkFinish = (rv)=>
      if --count == 0
        if debug then console.log 'ObjectManager.parseList returns '+rv.length+' records'
        if debug then console.dir rv
        msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})

    count = _records.length
    if debug then console.log 'ObjectManager.parseList resolving '+count+' records'
    if count == 0
      if debug then console.log 'ObjectManager.parseList -- returning empty set'
      msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: []})
    else
      rv = []
      _records.forEach (r) =>
        DB.get(r.type, [r.id]).then (record) =>
          if debug then console.log 'ObjectManager.parseList -- result of getting record '+r.type+' id '+r.id+' is '+record
          if debug then console.dir record
          if record and record[0]
            @messageRouter.resolver.createObjectFrom(record[0]).then (o) =>
              #console.log '----- resolved object for record '+r.id
              rv.push o.toClient()
              objStore.storeObject o,false
              checkFinish(rv)
          else
            if debug then console.log ' empty records for '+r.id
            checkFinish(rv)
  #---------------------------------------------------------------------------------------------------------------------

  expose: (type) =>
    objStore.types[type] = type
    @messageRouter.addTarget '_create'+type, 'obj', (msg) =>
      msg.type = type 
      @_createObject(msg)

    # TODO: delete object hierarchy as well? Maybe also check for other objects referencing this, disallowing if so
    @messageRouter.addTarget '_delete'+type, 'obj', (msg) =>
      msg.type = type
      @_deleteObject(msg)

    @messageRouter.addTarget '_update'+type, 'obj', (msg) =>
      msg.type = type
      @_updateObject(msg)

    @messageRouter.addTarget '_get'+type, 'obj', (msg) =>
      msg.type = type
      @_getObject(msg)

    @messageRouter.addTarget '_list'+type+'s', '<noargs>', (msg) =>
      msg.type = type
      #console.log 'calling _listObjects from WsMethod with type '+type
      @._listObjects(msg)

    @messageRouter.addTarget '_count'+type+'s', '<noargs>', (msg) =>
      msg.type = type
      @._countObjects(msg)

  getObjectPullThrough: (id, type) =>
    #if debug then console.log '- getObjectPullThrough for id '+id+' and type '+type
    #if debug then console.dir id
    q = defer()
    if not type
      console.log '- Objectmanager::getObjectPullThrough called with null type.'
      q.resolve()
    else if not id or id == null or id == 'null'
      console.log '- Objectmanager::getObjectPullThrough called with null id for type '+type
      q.resolve()
    else
      objStore.getObject(id, type).then (o) =>
        if not o
          if debug then console.log '- getObjectPullThrough did not find object type '+type+' id '+id+' in ostore, getting from db'
          DB.get(type, [id]).then (record) =>
            if debug then console.log '- getObjectPullThrough getting record from db'
            if debug then console.dir record
            if not record or not record[0] or record[0] == null
              if debug then console.log '- getObjectPullThrough got null record. resolving null'
              q.resolve null
            else
              @messageRouter.resolver.createObjectFrom(record).then (oo) =>
                if debug then console.log '- getObjectPullThrough got object '+oo.id+'  '+oo.type
                if debug then console.dir oo
                q.resolve(oo)
        else
          if debug then console.log '- getObjectPullThrough found object in objStore'
          q.resolve(o)
    return q

  onUpdateObject: (msg) =>
    #console.log 'onUpdateObject called for '+msg.obj.type+' - '+msg.obj.id
    if msg.obj and msg.obj.id
      DB.getFromStoreOrDB(msg.obj.type, msg.obj.id).then( (obj) =>
        #console.log 'onUpdateObject getFromStoreOrDB returned '+obj
        #console.dir obj
        if obj
          #console.log 'have an object'
          canwrite = @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user, msg.obj)
          if canwrite
            #console.log 'can write'
            # Make sure to resolve object references in arrays and hashtables
            if not @areDataTrashed(obj)
              for k,v of msg.obj
                obj[k] = v if k isnt 'id'
              @resolveReferences(obj, obj.constructor.model).then (robj)=>
                #console.log '++++++++++++++++++++++++++++++++++++++++++++++ onUpdateObject after resolveReferences:'
                objStore.updateObj(robj)
                objStore[robj.id] = obj
                if debug then console.log 'persisting '+obj.id+' type '+obj.type+' in db. modifiedAt = '+obj.modifiedAt
                obj.serialize(robj).then (res) =>
                  if not res
                    msg.replyFunc({status: e.general.FAILURE, info: 'db error for object update', payload: msg.obj.id})
                  else
                    record = obj.getRecord()
                    #objStore.sendUpdatesFor(obj, true)
                    #console.log 'final object update result------>'
                    #console.log record
                    @updateObjectHooks.forEach (hook) => hook(record)
                    msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.UPDATE_OBJECT_SUCCESS, payload: msg.obj.id})
            else
              console.log 'object update fail: data is TRASHED!!!!'
              msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'one or more arrays have ben contaminated with null values', payload: msg.obj.id})
          else
            console.log 'object update fail: not allowed to write'
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_OBJECT_FAIL, payload: msg.obj.id})
        else
          console.log 'No object of type '+msg.obj.type+' found with id '+msg.obj.id
          #console.dir objStore.objects.map (o) -> o.type == msg.obj.type
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
      )
    else
      console.log 'onUpdateObject got wrong or missing parameters'
      console.dir msg.obj
      msg.replyFunc({status: e.general.FAILURE, info: 'missing parameter(s) for object update', payload: msg.obj})

  areDataTrashed: (obj) ->
    trashed = false
    for k of obj
      v = obj[k]
      if Array.isArray(v)
        v.forEach (el) ->
          if el == null or !el
            trashed = true
          return
    trashed

  resolveReferences: (record, model) =>
    rv = {id: record.id}
    q = defer()
    count = model.length

    checkFinished = (pname) ->
      #if debug then console.log 'checkFinished for property '+pname+' count = '+count
      #console.dir rv
      if --count == 0
        #if debug then console.log 'Objectmanager.resolveReferences resolving back object'
        #console.dir(rv)
        q.resolve(rv)

    model.forEach (property) =>
      #if debug then console.log 'going through array property '+property.name
      #console.dir property
      if property.array
        #console.log 'going through array property '+property.name
        resolvedarr = []
        arr = record[property.name] or []
        arr = arr.filter (el) -> el and el isnt null and el isnt 'null' and el isnt 'undefined'
        acount = arr.length
        #console.log 'acount = '+acount
        if acount == 0
          rv[property.name] = []
          checkFinished(property.name)
        else
          arr.forEach (idorobj) =>
            id = idorobj
            if typeof idorobj == 'object' then id = idorobj.id
            #if debug then console.log 'attempting to get array name '+property.name+' object type '+property.type+' id '+id
            @getObjectPullThrough(id, property.type).then (o)=>
              if o then resolvedarr.push(o)
              #if debug then console.log 'adding array reference '+o.id+' name '+o.name+' acount = '+acount
              if --acount == 0
                rv[property.name] = resolvedarr
                checkFinished(property.name)
      else if property.hashtable
        #console.log '======================================== going through hashtable property '+property.name
        #console.dir record[property.name]
        resolvedhash = {}
        if record[property.name] and record[property.name]
          harr = record[property.name] or []
          if not harr.length then harr = []
          hcount = harr.length
          if hcount == 0
            rv[property.name] = []
            checkFinished(property.name)
          else
            harr.forEach (id) =>
              @getObjectPullThrough(id, property.type).then (o)=>
                if o then resolvedhash[o.name] = o
                #console.log 'adding hashtable reference '+o.id+' name '+o.name
                if --hcount == 0
                  rv[property.name] = resolvedhash
                  checkFinished(property.name)
        else
          rv[property.name] = []
          checkFinished(property.name)
      else
        # test for direct reference!
        if property.type and property.value
          #console.log property.name+' = direct ref'
          @getObjectPullThrough(record[property.name], property.type).then (o)=>
            rv[property.name] = o
            checkFinished(property.name)
        else
          #console.log property.name+' = scalar'
          rv[property.name] = record[property.name]
          checkFinished(property.name)


    return q

  #---------------------------------------------------------------------------------------------------------------------

  onRegisterForUpdatesOn: (msg) =>
    #if debug then console.dir msg
    if msg.obj or not msg.obj.id or not msg.obj.type
      if debug then console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
      DB.getFromStoreOrDB(msg.obj.type, msg.obj.id).then( (obj) =>
        if obj && obj.id
          if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
            rememberedListenerId = undefined
            listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) =>
              #console.log '--------------------- onRegisterForUpdates on callback sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
              #console.dir uobj
              if @isAlreadyToCliented(uobj)
                toclient = uobj
              else
                toclient = uobj.toClient()
              #if debug then console.dir(toclient)
              if ClientEndpoints.exists(msg.client)
                ClientEndpoints.sendToEndpoint(msg.client, {status: e.general.SUCCESS, info: 'OBJECT_UPDATE', payload: toclient })
              else
                console.log 'removing dangling endpoint from object updates for obj id '+msg.id+' and listenerId '+rememberedListenerId
                objStore.removeListenerFor(msg.id, rememberedListenerId)
            )
            rememberedListenerId = listenerId
            ClientEndpoints.onDisconnect (adr) =>
              if adr == msg.client then objStore.removeListenerFor(msg.obj.id, listenerId)

            if debug then console.log 'listenerid '+listenerId+' added for updates on object '+obj.name+' ['+obj.id+']'
            msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.REGISTER_UPDATES, payload: listenerId})
          else
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_REGISTER_FAIL, payload: msg.obj.id })
        else
          if debug then console.log 'Could not find object: '+msg.obj.type+' id '+msg.obj.id
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
      , error)

    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForUpdatesOn missing parameter', payload: null })

  isAlreadyToCliented:(o)=>
    rv = false
    for k,v of o
      if Array.isArray(v)
        v.forEach (el)->
          if (el.length and el.length == 36) then rv = true
    rv

  onDeregisterForUpdatesOn: (msg) =>
    if debug then console.log 'onDeregisterForUpdatesOn called for id '+msg.id+' and listener id '+msg.listenerid
    if msg.id and msg.listenerid and msg.type
      objStore.removeListenerFor(msg.id, msg.listenerid)
      msg.replyFunc({status: e.general.SUCCESS, info: 'deregistered listener for object', payload: msg.id })
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onDeregisterForUpdatesOn missing parameter', payload: null })

  onRegisterForPopulationChanges: (msg) =>
    if msg.type
      poplistenid = uuid.v4()
      sublist = @populationListeners[msg.type] or {}
      sublist[poplistenid] = msg.client
      @populationListeners[msg.type] = sublist
      msg.replyFunc({status: e.general.SUCCESS, info: 'registered for population changes for type '+msg.type, payload: poplistenid})
      ClientEndpoints.onDisconnect (adr) =>
        if adr == msg.client
          sublist = @populationListeners[msg.type] or {}
          delete sublist[poplistenid]
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForPopulationChanges missing parameter', payload: null })

  onDeregisterForPopulationChanges: (msg) =>
    if msg.type and msg.listenerid
      sublist = @populationListeners[msg.type] or {}
      delete sublist[poplistenid]
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onDeregisterForPopulationChanges missing parameter', payload: null })

module.exports = ObjectManager
