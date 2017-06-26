util            = require('util')
defer           = require('node-promise').defer
SuperModel      = require('./SuperModel')
e               = require('./EventManager')
DB              = require('./DB')
ClientEndpoints = require('./ClientEndpoints')
objStore        = require('./OStore')
error           = require('./Error').error
ResolveModule   = require('./ResolveModule')
uuid            = require('node-uuid')

debug = process.env["DEBUG"]

class ObjectManager


  constructor: (@messageRouter) ->
   @updateObjectHooks = []
   @populationListeners = []
   SuperModel.onCreate (newmodel)=>
     #if debug then console.log 'ObjectManager got onCreate event'
     #if debug then console.dir newmodel

     #if debug then console.dir @populationListeners
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

  getTypes: ()=>
    types = []
    for k,v of ResolveModule.modulecache
      types.push k.toLowerCase()
    types  

  onListTypes: (msg) =>
    types = []
    for k,v of ResolveModule.modulecache
      types.push k
    msg.replyFunc({status: e.general.SUCCESS, info: 'list types', payload: types})

  onGetAccessTypesFor: (msg) =>
    if msg.modelname
      rv =
        create: @messageRouter.authMgr.canUserCreateThisObject(msg.modelname, msg.user, msg.sessionId)
        read:   @messageRouter.authMgr.canUserReadFromThisObject(msg.modelname, msg.user, msg.sessionId)
        write:  @messageRouter.authMgr.canUserWriteToThisObject(msg.modelname, msg.user, msg.sessionId)
        list:   @messageRouter.authMgr.canUserListTheseObjects(msg.modelname, msg.user, msg.sessionId)

      msg.replyFunc({status: e.general.SUCCESS, info: 'access types for '+msg.modelname, payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "getAccessTypesFor missing parameter", payload: null})

  onGetModelFor: (msg) =>
    if msg.modelname
      @messageRouter.resolver.resolve msg.modelname, (path) =>
        if debug then console.log 'onGetModelFor '+msg.modelname+' got back require path '+path
        rv = @getModelFor(msg.modelname)
        msg.replyFunc({status: e.general.SUCCESS, info: 'get model', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "getModelFor missing parameter", payload: null})

  getModelFor:(modelname)=>
    model = ResolveModule.modulecache[modelname] or ResolveModule.modulecache[modelname.toLowerCase()]
    #console.log '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ got model for '+modelname+' resolved to '+model
    if not model
      for k,v of ResolveModule.modulecache
        console.log '------- model in modulecache : '+k
    rv = []
    model.model.forEach (property) -> if property.public then rv.push(property)
    rv

  #---------------------------------------------------------------------------------------------------------------------
  _createObject: (msg) =>
    console.log 'objmgr.createObject called'
    if msg.obj and msg.obj.type
      if msg.obj.type.toLowerCase() in @getTypes()
        if @messageRouter.authMgr.canUserCreateThisObject(msg.obj.type, msg.user, msg.sessionId)
          if debug then console.dir msg
          msg.obj.createdAt = Date.now()
          msg.obj.modifiedAt = Date.now()
          msg.obj.createdBy = msg.user.id
          msg.obj.userRef = msg.user.id
          #console.log 'objmgr.createObject called. record is now'
          #console.dir msg.obj
          SuperModel.resolver.createObjectFrom(msg.obj).then (o) =>
            o.serialize().then () =>
              @messageRouter.gaugeMetric('create',1,{type:  msg.obj.type,'username': msg.user.name, 'useremail': msg.user.email, 'provider': msg.user.provider, 'organization': msg.user.organization})
              msg.replyFunc({status: e.general.SUCCESS, info: 'new '+msg.obj.type, payload: o})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to create objects of that type', payload: msg.obj.type})
      else
        msg.replyFunc({status: e.general.FAILURE, info: 'unkown model type', payload: msg.obj.type })
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_createObject missing parameter', payload: null })

  _deleteObject: (msg) =>
    #console.log 'delete called'
    if msg.obj and msg.obj.type and msg.obj.id
      console.log 'delete got type '+msg.obj.type+', and id '+msg.obj.id
      if msg.obj.type.toLowerCase() in @getTypes()
        #objStore.getObject(msg.obj.id, msg.obj.type).then (obj) =>
        @getObjectPullThrough(msg.obj.id, msg.obj.type).then (obj) =>
          #console.log 'got object form objstore -> '+obj
          if obj
            if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user, msg.obj, msg.sessionId)
              #console.log 'user could write this object'
              #console.dir obj
              DB.remove obj, (removestatus) =>
                @messageRouter.gaugeMetric('delete', 1, {type:  msg.obj.type, 'username': msg.user.name, 'useremail': msg.user.email, 'provider': msg.user.provider, 'organization': msg.user.organization})
                #console.log 'object removed callback'
                sublist = @populationListeners[msg.type] or {}
                for k,client of sublist
                  if ClientEndpoints.exists(client)
                    #console.log 'updating population changes callback'
                    ClientEndpoints.sendToEndpoint(client, {status: e.general.SUCCESS, info: 'POPULATION_UPDATE', payload: { removed: obj.toClient() } })
                objStore.removeObject(obj)
                #console.log 'object removed from objstore'
                msg.replyFunc({status: e.general.SUCCESS, info: 'delete object', payload: obj.id})
            else
              msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to delete object', payload: msg.obj.id})
          else
            console.log 'No object found with id '+msg.obj.id
            console.dir objStore.objects.map (o) -> o.type == msg.obj.type
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
      else
        msg.replyFunc({status: e.general.FAILURE, info: 'unkown model type', payload: msg.obj.type })
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_deleteObject missing parameter', payload: null })

  _updateObject: (msg) =>
    @onUpdateObject(msg)

  _getObject: (msg) =>
    #if debug then console.log '_getObject called for type '+msg.type
    #if debug then console.dir msg.obj
    if msg.type and ((msg.obj and msg.obj.id) or msg.id)
      if msg.type.toLowerCase() in @getTypes()
        id = msg.id or msg.obj.id
        if id.indexOf and id.indexOf('all_') > -1
          @getAggregateObjects(msg)
        else
          #if debug then console.log '_getObject calling getObjectPullThrough for type '+msg.type
          if typeof id isnt 'object'
            @getObjectPullThrough(id, msg.type).then (obj) =>
              #console.log '_getObject got back obj from getObjectPullThrough: '
              #console.dir obj
              if obj
                if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user, msg.sessionId)
                  tc = obj.toClient()
                  @messageRouter.gaugeMetric('get', 1, {type:msg.type,'username': msg.user.name, 'useremail': msg.user.email, 'provider': msg.user.provider, 'organization': msg.user.organization})
                  if @messageRouter.authMgr.filterOutgoing
                    @messageRouter.authMgr.filterOutgoing(tc, msg.user).then (ftc)=>
                      if ftc
                        if debug then console.log '_getObject for filteroutgoing  '+msg.type+' returns '+JSON.stringify(tc)
                        msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: ftc})
                      else
                        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to read from that object', payload: obj.id, statuscode: 403})
                  else
                    if debug then console.log '_getObject for '+msg.type+' returns '+JSON.stringify(tc)
                    #console.dir tc
                    msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: tc})
                else
                  console.log '_getObject got NOT ALLOWED for user '+msg.user.id+' for '+msg.type+' id '+obj.id
                  msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to read from that object', payload: id, statuscode: 403})
              else
                console.log '_getObject No object found with id '+id+' of type '+msg.type
                msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'no such object', payload: id, statuscode: 404})
          else
            console.log '_getObject provided id '+id+' of type '+msg.type+' is an object!!'
            console.dir id
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'id value is an object!!!', payload: id, statuscode: 400})
      else
        msg.replyFunc({status: e.general.FAILURE, info: 'unkown model type', payload: msg.obj.type, statuscode: 417 })
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_getObject for '+msg.type+' missing parameter', payload: null, statuscode: 417 })

  getAggregateObjects: (msg) =>
    if not @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user, msg.sessionId)
      msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
    else
      rv = objStore.listObjectsByType(msg.obj.type)
      obj = {id: msg.obj.id, list: rv}
      msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj})

  _listObjects: (msg) =>
    #console.log 'listObjects called for type '+msg.type
    #console.dir msg
    if typeof msg.type != 'undefined'
      if msg.type.toLowerCase() in @getTypes()
        if @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user, msg.sessionId) == no
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
        msg.replyFunc({status: e.general.FAILURE, info: 'unkown model type', payload: msg.obj.type })
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_listObjects missing parameter', payload: null })

  _countObjects: (msg) =>
    console.log 'countObjects called for type '+msg.type
    if typeof msg.type != 'undefined'
      if msg.type.toLowerCase() in @getTypes()
        if @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user, msg.sessionId) == no
          @messageRouter.gaugeMetric('count', 1, {type: msg.type, 'username': msg.user.name, 'useremail': msg.user.email, 'provider': msg.user.provider, 'organization': msg.user.organization})
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to count objects of type '+msg.type, payload: msg.type})
        else
          DB.count(msg.type).then (v)=>
            msg.replyFunc({status: e.general.SUCCESS, info: 'count objects', payload: v})
      else
        msg.replyFunc({status: e.general.FAILURE, info: 'unknown model type', payload: msg.type })
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_listObjects missing parameter', payload: null })

  parseList: (_records, msg) =>
    #console.log 'parseList for records..'
    #console.dir _records
    @messageRouter.gaugeMetric('list', 1, {type: msg.type, 'username': msg.user.name, 'useremail': msg.user.email, 'provider': msg.user.provider, 'organization': msg.user.organization})
    checkFinish = (rv)=>
      if --count == 0
        if debug then console.log 'ObjectManager.parseList returns '+rv.length+' records'
        #if debug then console.log JSON.stringify(rv)
        msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})

    count = _records.length
    if debug then console.log 'ObjectManager.parseList resolving '+count+' records'
    if count == 0
      if debug then console.log 'ObjectManager.parseList -- returning empty set'
      msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: []})
    else
      rv = []
      _records.forEach (r) =>
        if debug then console.log 'ObjectManager.parseList calling DB.get for id '+r.id
        DB.get(r.type, [r.id]).then (record) =>
         # if debug then console.log 'ObjectManager.parseList --- result of getting record '+r.type+' id '+r.id+' is '+record
          if record and record[0]
            #if debug then console.dir record[0]
            tc = record[0]
            if @messageRouter.authMgr.filterOutgoing
               @messageRouter.authMgr.filterOutgoing(tc, msg.user).then (tres)=>
                 if debug then console.log 'parseList got reply from filterOutgoing and it was a '+tres+' count = '+count
                 if debug then console.dir tres
                 if tres then rv.push(tres)
                 checkFinish(rv)
            else
              rv.push tc
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
      #console.log 'expose update got message'
      #console.dir msg
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
                #if debug then console.dir oo
                q.resolve(oo)
        else
          #if debug then console.log '- getObjectPullThrough found object in objStore'
          q.resolve(o)
    return q

  onUpdateObject: (msg) =>
    #console.log 'onUpdateObject called for '+msg
    #console.dir msg.obj
    if msg.obj and msg.obj.type and msg.obj.id
      if msg.obj.type.toLowerCase() in @getTypes()
        DB.getFromStoreOrDB(msg.obj.type, msg.obj.id).then( (obj) =>
          #console.log 'onUpdateObject getFromStoreOrDB returned '+obj
          #console.dir obj
          if obj
            #console.log 'have an object'
            canwrite = @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user, msg.obj, msg.sessionId)
            if canwrite
              #console.log 'can write'
              # Make sure to resolve object references in arrays and hashtables
              if not @areDataTrashed(msg.obj)
                @persistUpdates(obj, msg.obj).then (res)=>
                  if not res
                    msg.replyFunc({status: e.general.FAILURE, info: 'db error for object update', payload: msg.obj.id})
                  else
                    @messageRouter.gaugeMetric('update', 1, {type: msg.obj.type,'username': msg.user.name, 'useremail': msg.user.email, 'provider': msg.user.provider, 'organization': msg.user.organization})
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
        msg.replyFunc({status: e.general.FAILURE, info: 'missing parameter(s) for object update', payload: msg.obj})
    else
      console.log 'onUpdateObject got wrong or missing parameters'
      console.dir msg.obj
      msg.replyFunc({status: e.general.FAILURE, info: 'missing parameter(s) for object update', payload: msg.obj})

  persistUpdates: (obj, robj, force)=>
    q = defer()
    #console.log 'persistUpdates for record'
    #console.dir robj
    #console.log '..and old object'
    #console.dir obj
    model = @getModelFor(obj.type)
    borked = false
    model.forEach (row)=>
      if row.array and robj[row.name] and not Array.isArray(robj[row.name])
        console.log 'BORK detected for property '+row.name
        borked = true
    if borked
      console.log 'borketh object entered. scalar where there should be an array..'
      console.log '---------------------------------------------------------------'
      console.dir robj
      q.resolve(false)
    else
      obj.record = {}
      model.forEach (m)=>
        k = m.name
        v = robj[k]
        if k isnt 'id' and k isnt 'type'and k isnt 'createdAt' and k isnt 'modifiedAt'
          add = true
          #if Array.isArray(v) and v.length == 0 then add = false
          if not v then add = false
          if add
            #console.log '---- setting obj prop '+k+' to -> '+v
            obj.record[k] = v
      #console.log 'record is now'
      #console.dir obj.record
      obj.loadFromIds(obj.constructor.model).then () =>
        #console.log 'setting OStore '+obj.id+' to obj '+obj
        objStore.storeObject(obj)
        objStore.updateObj(obj, force)
        if debug then console.log 'persisting '+obj.id+' type '+obj.type+' in db. modifiedAt = '+obj.modifiedAt+' createdAt = '+obj.createdAt
        obj.serialize(robj).then (res) =>
          if not res
            console.log 'persisting failed'
            console.dir obj
            q.resolve(false)
          else
            record = obj.toClient()
            @updateObjectHooks.forEach (hook) => hook(record)
            #console.log 'persisting succeeded'
            #console.dir record
            q.resolve(true)
    return q
      
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

  #---------------------------------------------------------------------------------------------------------------------

  onRegisterForUpdatesOn: (msg) =>
    #if debug then console.dir msg
    if msg.obj or not msg.obj.id or not msg.obj.type
      if debug then console.log 'onRegisterForUpdatesOn  called for '+msg.obj.type+' '+msg.obj.id
      DB.getFromStoreOrDB(msg.obj.type, msg.obj.id).then( (obj) =>
        if obj && obj.id
          if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user, msg.sessionId)
            rememberedListenerId = undefined
            listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) =>
              #console.log '--------------------- onRegisterForUpdates on callback sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
              #console.dir uobj
              toclient = uobj.toClient()
              if debug then console.dir(toclient)
              if ClientEndpoints.exists(msg.client)
                ClientEndpoints.sendToEndpoint(msg.client, {status: e.general.SUCCESS, info: 'OBJECT_UPDATE', payload: toclient })
              else
                console.log 'removing dangling endpoint from object updates for obj id '+msg.id+' and listenerId '+rememberedListenerId
                objStore.removeListenerFor(msg.id, rememberedListenerId)
            )
            rememberedListenerId = listenerId
            ClientEndpoints.onDisconnect (adr) =>
              if adr == msg.client then objStore.removeListenerFor(msg.obj.id, listenerId)

            #if debug then console.log 'listenerid '+listenerId+' added for updates on object '+obj.name+' ['+obj.id+']'
            msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.REGISTER_UPDATES, payload: listenerId})
          else
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'Not allowed to register for updates on that object', payload: msg.obj.id })
        else
          if debug then console.log 'Could not find object: '+msg.obj.type+' id '+msg.obj.id
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
      , error)

    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForUpdatesOn missing parameter', payload: null })

  onDeregisterForUpdatesOn: (msg) =>
    if debug then console.log 'onDeregisterForUpdatesOn called for id '+msg.id+' and listener id '+msg.listenerid
    if msg.id and msg.listenerid and msg.type
      objStore.removeListenerFor(msg.id, msg.listenerid)
      msg.replyFunc({status: e.general.SUCCESS, info: 'deregistered listener for object', payload: msg.id })
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onDeregisterForUpdatesOn missing parameter', payload: null })

  onRegisterForPopulationChanges: (msg) =>
    if msg.type
      if msg.type.toLowerCase() in @getTypes()
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
        msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForPopulationChanges unknown type', payload: msg.type })
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForPopulationChanges missing parameter', payload: null })

  onDeregisterForPopulationChanges: (msg) =>
    if msg.type and msg.listenerid
      sublist = @populationListeners[msg.type] or {}
      delete sublist[poplistenid]
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onDeregisterForPopulationChanges missing parameter', payload: null })


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
        if debug then console.log '======================================== going through hashtable property '+property.name
        #console.dir record[property.name]
        resolvedhash = {}
        if record[property.name]
          harr = record[property.name] or []
          if not harr.length then harr = []
          if debug then console.dir harr
          if typeof harr == 'string' then harr = [harr]
          hcount = harr.length
          if !hcount or hcount == 0
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


module.exports = ObjectManager
