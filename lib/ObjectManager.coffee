util            = require('util')
defer           = require('node-promise').defer
SuperModel      = require('./SuperModel')
e               = require('./EventManager')
DB              = require('./DB')
ClientEndpoints = require('./ClientEndpoints')
objStore        = require('./OStore')
error           = require('./Error').error

debug = process.env["DEBUG"]

class ObjectManager

  constructor: (@messageRouter) ->
   @updateObjectHooks = []
   @populationListeners = []
   SuperModel.onCreate (newmodel)=>
     @populationListeners.forEach (client) =>
       if ClientEndpoints.exists(client)
         ClientEndpoints.sendToEndpoint(client, {status: e.general.SUCCESS, info: 'POPULATION_UPDATE', payload: { added: newmodel.toClient() } })


  setup: () =>
    @messageRouter.addTarget('registerForUpdatesOn',  'obj', @onRegisterForUpdatesOn)
    @messageRouter.addTarget('deRegisterForUpdatesOn',  'id,listenerid', @onDeregisterForUpdatesOn)
    @messageRouter.addTarget('updateObject',          'obj', @onUpdateObject)
    @messageRouter.addTarget('listTypes',             '<noargs>', @onListTypes)
    @messageRouter.addTarget('getModelFor',             'modelname', @onGetModelFor)
    @messageRouter.addTarget('getAccessTypesFor',             'modelname', @onGetAccessTypesFor)
    @messageRouter.addTarget('registerForPopulationChangesFor', 'type', @onRegisterForPopulationChanges)

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
        #if debug then console.log 'onGetModelFor '+msg.modelname+' got back require path '+path
        model = require(path)
        #if debug then console.log 'got model resolved to'
        #if debug then console.dir model.model
        rv = []
        model.model.forEach (property) -> if property.public then rv.push(property)
        msg.replyFunc({status: e.general.SUCCESS, info: 'get model', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "getModelFor missing parameter", payload: null})

  #---------------------------------------------------------------------------------------------------------------------
  _createObject: (msg) =>
    if msg.obj.type
      if @messageRouter.authMgr.canUserCreateThisObject(msg.obj.type, msg.user)
        #console.dir msg
        msg.obj.createdAt = Date.now()
        msg.obj.createdBy = msg.user.id
        console.log 'objmgr.createObject called'
        SuperModel.resolver.createObjectFrom(msg.obj).then (o) =>
          o.serialize()
          msg.replyFunc({status: e.general.SUCCESS, info: 'new '+msg.obj.type, payload: o})
      else
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to create objects of that type', payload: msg.obj.type})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_createObject missing parameter', payload: null })

  _deleteObject: (msg) =>
    console.log 'delete called'
    if msg.obj and msg.obj.type and msg.obj.id
      console.log 'delete got type'+msg.obj.type+', and id '+msg.obj.id
      objStore.getObject(msg.obj.id, msg.obj.type).then (obj) =>
        console.log 'got object form objstore -> '+obj
        if obj
          if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
            console.log 'user could write this object'
            DB.remove obj, (removestatus) =>
              console.log 'object removed callback'
              @populationListeners.forEach (client) =>
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
    if debug then console.dir msg
    if msg.type and msg.obj.id
      id = msg.obj.id
      if id.indexOf and id.indexOf('all_') > -1
        @getAggregateObjects(msg)
      else
        @getObjectPullThrough(id, msg.type).then (obj) =>
          if obj
            if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
              msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj.toClient()})
            else
              console.log '_getObject got NOT ALLOWED for user '+msg.user.id+' for '+msg.type+' id '+obj.id
              msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to read from that object', payload: id})
          else
            console.log 'No object found with id '+id
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
        #rv = objStore.listObjectsByType(msg.type)
        if msg.query
          if debug then console.log 'executing query for property '+msg.query.property+', value '+msg.query.value
          #if msg.query.wildcard
          #  DB.search(msg.type, msg.query.property, msg.query.value).then (records) => @parseList(records, msg)
          if msg.query.limit or msg.query.skip or msg.query.sort or msg.query.wildcard
            if msg.query.value
              DB.findQuery(msg.type, msg.query).then (records) => @parseList(records, msg)
            else
              DB.all(msg.type, (records) => @parseList(records, msg))
          else
            DB.findMany(msg.type, msg.query.property, msg.query.value).then (records) => @parseList(records, msg)
        else
          DB.all(msg.type, (records) => @parseList(records, msg))
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

  parseList: (records, msg) =>
    rv = []
    #console.log 'found '+records.length+' objects to return'
    count = records.length
    if debug then console.dir records
    if count == 0
      msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})
    else
      records.forEach (record) =>
        objStore.getObject(record.id, record.type).then (oo) =>
          if oo
            if debug then console.log 'found list object in OStore'
            if debug then console.dir(oo.toClient())
            rv.push(oo.toClient())
            if --count == 0
              msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})
          else
            @messageRouter.resolver.createObjectFrom(record).then (o) =>
              if debug then console.log 'resolved object '+o.id+' count = '+count
              console.log 'created list object from resolver'
              console.dir(o.toClient())
              rv.push(o.toClient())
              if --count == 0
                msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})
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
    if debug then console.log 'getObjectPullThrough for id '
    if debug then console.dir id
    q = defer()
    if not type
      console.log 'Objectmanager::getObjectPullThrough called with null type.'
      q.resolve(null)
    if not id or id == null or id == 'null'
      console.log 'Objectmanager::getObjectPullThrough called with null id.'
      q.resolve(null)
    else
      objStore.getObject(id, type).then (o) =>
        if not o
          if debug then console.log 'getObjectPullThrough did not find object type '+type+' id '+id+' in ostore, getting from db'
          DB.get(type, [id]).then (record) =>
            #console.log 'getting record from db'
            #console.dir record
            @messageRouter.resolver.createObjectFrom(record).then (oo) =>
              q.resolve(oo)
        else
          q.resolve(o)
    return q

  onUpdateObject: (msg) =>
    console.log 'onUpdateObject called for '+msg.obj.type+' - '+msg.obj.id
    if msg.obj and msg.obj.id
      objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
        if obj
          if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
            if debug then console.log 'can write'
            # Make sure to resolve object references in arrays and hashtables
            for k,v of msg.obj
              obj[k] = v if k isnt 'id'
            @resolveReferences(obj, obj.constructor.model).then (robj)=>
              if debug then console.log 'found object'
              #objStore.updateObj(robj)
              objStore[robj.id] = robj
              if debug then console.log 'persisting '+obj.id+' type '+obj.type+' in db. modifiedAt = '+obj.modifiedAt
              obj.serialize(robj).then () =>
                record = obj.getRecord()
                @updateObjectHooks.forEach (hook) => hook(record)
                msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.UPDATE_OBJECT_SUCCESS, payload: msg.obj.id})
          else
            console.log 'object update fail: could not find any object'
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_OBJECT_FAIL, payload: msg.obj.id})
        else
          console.log 'No object of type '+msg.obj.type+' found with id '+msg.obj.id
          #console.dir objStore.objects.map (o) -> o.type == msg.obj.type
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
      )
    else
      console.log 'onUpdateObject got wrong or missing parameters'
      console.dir msg.obj
      msg.replyFunc({status: e.general.FAILURE, info: 'missing parameter(s) for object update', payload: msg.obj.id})

  resolveReferences: (record, model) =>
    if debug then console.log 'resolveReferences model is '
    if debug then console.dir model
    rv = {id: record.id}
    q = defer()
    count = model.length

    checkFinished = () ->
      #if debug then console.log 'checkFinished count = '+count
      #console.dir rv
      if --count == 0
        #console.log 'resolving back object'
        q.resolve(rv)

    model.forEach (property) =>
      #if debug then console.log 'going through array property '+property.name
      if property.array
        resolvedarr = []
        arr = record[property.name] or []
        arr = arr.filter (el) -> el and el isnt null and el isnt 'null' and el isnt 'undefined'
        if debug then console.dir arr
        acount = arr.length
        if acount == 0
          rv[property.name] = []
          checkFinished()
        else
          arr.forEach (idorobj) =>
            #if debug then console.log 'resolving array'
            #if debug then console.dir arr
            if idorobj and typeof idorobj == 'object' then id = idorobj.id else id = idorobj
            #if debug then console.log 'attempting to get array name '+property.name+' object type '+property.type+' id '+id
            @getObjectPullThrough(id, property.type).then (o)=>
              #console.log ' we got object '+o
              #console.dir o
              resolvedarr.push(o)
              #if debug then console.log 'adding array reference '+o.id+' name '+o.name
              if --acount == 0
                rv[property.name] = resolvedarr
                checkFinished()
      else if property.hashtable
        #if debug then console.log 'going through hashtable property '+property.name
        resolvedhash = {}
        if record[property.name] and record[property.name].length
          harr = record[property.name] or []
          hcount = harr.length
          if hcount == 0
            rv[property.name] = []
            checkFinished()
          else
            harr.forEach (id) =>
              @getObjectPullThrough(id, property.type).then (o)=>
                resolvedhash[o.name] = o
                #if debug then console.log 'adding hashtable reference '+o.id+' name '+o.name
                if --hcount == 0
                  rv[property.name] = resolvedhash
                  checkFinished()
        else
          rv[property.name] = record[property.name]
      else
        #if debug then console.log 'resolveReference adding direct reference '+property.name
        rv[property.name] = record[property.name]
        checkFinished()

    return q

  #---------------------------------------------------------------------------------------------------------------------

  onRegisterForUpdatesOn: (msg) =>
    #if debug then console.dir msg
    if msg.obj or not msg.obj.id or not msg.obj.type
      if debug then console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
      objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
        if obj && obj.id
          if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
            rememberedListenerId = undefined
            listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
              if debug then console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
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
          if debug then console.log 'User mot allowed getting updates (read) object:'
          if debug then console.dir obj
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
      , error)

    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForUpdatesOn missing parameter', payload: null })

  onDeregisterForUpdatesOn: (msg) =>
    if debug then console.log 'onDeregisterForUpdatesOn called for id '+msg.id+' and listener id '+msg.listenerid
    if msg.id and msg.listenerid and msg.type
      objStore.removeListenerFor(msg.id, msg.listenerid)
      msg.replyFunc({status: e.general.SUCCESS, info: 'deregistered listener for obejct', payload: msg.id })
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onDeregisterForUpdatesOn missing parameter', payload: null })

  onRegisterForPopulationChanges: (msg) =>
    if msg.type
      @populationListeners.push msg.client
      msg.replyFunc({status: e.general.SUCCESS, info: 'registered for population changes for type '+msg.type, payload: type})
      ClientEndpoints.onDisconnect (adr) =>
        if adr == msg.client
          idx = -1
          @populationListeners.forEach (client, i) =>
            if client == msg.client then idx = i
          @populationListeners.splice(i, 1)
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForPopulationChanges missing parameter', payload: null })

module.exports = ObjectManager
