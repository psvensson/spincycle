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
    @messageRouter.addTarget('registerForPopulationChangesFor', 'type', @onRegisterForPopulationChanges)

  registerUpdateObjectHook: (hook) =>
    @updateObjectHooks.push hook

  onListTypes: (msg) =>
    msg.replyFunc({status: e.general.SUCCESS, info: 'list types', payload: objStore.listTypes()})

  onGetModelFor: (msg) =>
    if msg.modelname
      @messageRouter.resolver.resolve msg.modelname, (path) =>
        if debug then console.log 'onGetModelFor '+msg.modelname+' got back require path '+path
        model = require(path)
        if debug then console.log 'got model resolved to'
        if debug then console.dir model
        rv = []
        model.model.forEach (property) -> if property.public then rv.push(property)
        msg.replyFunc({status: e.general.SUCCESS, info: 'get model', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "missing parameter", payload: null})

  #---------------------------------------------------------------------------------------------------------------------
  _createObject: (msg) =>
    if msg.obj.type
      if @messageRouter.authMgr.canUserCreateThisObject(msg.obj.type, msg.user)
        #console.dir msg
        msg.obj.createdAt = Date.now()
        msg.obj.createdBy = msg.user.id
        SuperModel.resolver.createObjectFrom(msg.obj).then (o) =>
          objStore.getObject('all_'+msg.obj.type, msg.obj.type).then (oo) =>
            objStore.sendAllUpdatesFor(oo, true)
            o.serialize()
            msg.replyFunc({status: e.general.SUCCESS, info: 'new '+msg.obj.type, payload: o})
      else
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to create objects of that type', payload: msg.obj.type})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_createObject missing parameter', payload: null })

  _deleteObject: (msg) =>
    if msg.obj and msg.obj.type and msg.obj.id
      objStore.getObject(msg.obj.id, msg.obj.type).then (obj) =>
        if obj
          if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
            DB.remove obj, (removestatus) =>
              @populationListeners.forEach (client) =>
                if ClientEndpoints.exists(client)
                  ClientEndpoints.sendToEndpoint(client, {status: e.general.SUCCESS, info: 'POPULATION_UPDATE', payload: { removed: obj.toClient() } })
              objStore.getObject('all_'+msg.obj.type, msg.obj.type).then (oo) =>
                if debug then console.log 'exposed object removed through _delete'+msg.obj.type
                oo.list = oo.list.filter (id) =>  id != obj.id
                if debug then console.log 'resulting list is'
                if debug then console.dir oo.list
                objStore.removeObject(obj)
                objStore.sendAllUpdatesFor(oo, true)
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
    if msg.type and msg.obj.id
      id = smg.obj.id
      if id.indexOf and id.indexOf('all_') > -1
        @getAggregateObjects(msg)
      else
        @getObjectPullThrough(id, msg.obj.type).then (obj) =>
          if obj
            if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
              msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj.toClient()})
            else
              console.log '_getObject got NOT ALLOWED for user '+msg.user.id+' for '+msg.type+' id '+obj.id
              msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to read from that object', payload: id})
          else
            console.log 'No object found with id '+id
            console.dir objStore.objects.map (o) -> o.type == msg.obj.type
            msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'no such object', payload: msg.obj.id})
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_getObject missing parameter', payload: null })

  getAggregateObjects: (msg) =>
    if not @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user)
      msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
    else
      rv = objStore.listObjectsByType(msg.obj.type)
      obj = {id: msg.obj.id, list: rv}
      msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj})

  _listObjects: (msg) =>
    console.log 'listObjects called for type '+msg.type
    if typeof msg.type != 'undefined'
      if @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user) == no
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
      else
        #rv = objStore.listObjectsByType(msg.type)
        DB.all(msg.type, (records) =>
          rv = []
          console.log 'found '+records.length+' objects to return'
          count = records.length
          records.forEach (record) =>
            @messageRouter.resolver.createObjectFrom(record).then (o) =>
              if debug then console.log 'resolved object '+o.id+' count = '+count
              rv.push(o.toClient())
              if --count == 0
                msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})
        )
    else
      msg.replyFunc({status: e.general.FAILURE, info: '_listObjects missing parameter', payload: null })

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

  getObjectPullThrough: (id, type) =>
    q = defer()
    if not type
      console.log 'Objectmanager::getObjectPullThrough called with null type.'
      q.resolve(null)
    else
      objStore.getObject(id, type).then (o) =>
        if not o
          console.log 'did not find object i ostore, getting from db'
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
    objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj
        if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
          if debug then console.log 'can write'
          # Make sure to resolve object references in arrays and hashtables
          @resolveReferences(msg.obj, obj.constructor.model).then (robj)=>
            if debug then console.log 'found object'
            #objStore.updateObj(robj)
            if debug then console.log 'persisting '+obj.id+' type '+obj.type+' in db. modifiedAt = '+obj.modifiedAt
            obj.serialize(robj).then () =>
              record = obj.getRecord()
              @updateObjectHooks.forEach (hook) => hook(record)
              msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.UPDATE_OBJECT_SUCCESS, payload: msg.obj.id})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_OBJECT_FAIL, payload: msg.obj.id})
      else
        console.log 'Not object found with id '+msg.obj.id
        console.dir objStore.objects.map (o) -> o.type == msg.obj.type
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
    )

  resolveReferences: (record, model) =>
    if debug then console.log 'resolveReferences model is '
    if debug then console.dir model
    rv = {id: record.id}
    q = defer()
    count = model.length

    checkFinished = () ->
      if debug then console.log 'checkFinished count = '+count
      #console.dir rv
      if --count == 0
        #console.log 'resolving back object'
        q.resolve(rv)

    model.forEach (property) =>
      #console.log 'going through property '+property.name
      if property.array
        resolvedarr = []
        arr = record[property.name] or []
        acount = arr.length
        if acount == 0
          rv[property.name] = []
          checkFinished()
        else
          arr.forEach (id) =>
            if debug then console.log 'attempting to get object type '+property.type+' id '+id
            @getObjectPullThrough(id, property.type).then (o)=>
              #console.log ' we got object '+o
              #console.dir o
              resolvedarr.push(o)
              if debug then console.log 'adding array reference '+o.id+' name '+o.name
              if --acount == 0
                rv[property.name] = resolvedarr
                checkFinished()
      else if property.hashtable
        resolvedhash = {}
        harr = record[property.name] or []
        hcount = harr.length
        if hcount == 0
          rv[property.name] = []
          checkFinished()
        else
          harr.forEach (id) =>
            @getObjectPullThrough(id, property.type).then (o)=>
              resolvedhash[o.name] = o
              if debug then console.log 'adding hashtable reference '+o.id+' name '+o.name
              if --hcount == 0
                rv[property.name] = resolvedhash
                checkFinished()
      else
        if debug then console.log 'resolveReference adding direct reference '+property.name
        rv[property.name] = record[property.name]
        checkFinished()

    return q

  #---------------------------------------------------------------------------------------------------------------------

  onRegisterForUpdatesOn: (msg) =>
    if debug then console.dir msg
    if msg.obj or not msg.obj.id or not msg.obj.type
      if debug then console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
      if typeof msg.obj.id is 'string'
        objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
          if obj && obj.id
            if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
              rememberedListenerId = undefined
              listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
                if debug then console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
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
        msg.replyFunc({status: e.general.FAILURE, info: 'onRegisterForUpdatesOn wrong parameter format', payload: 'id' })
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
