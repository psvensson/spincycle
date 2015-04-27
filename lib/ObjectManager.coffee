util            = require('util')
defer           = require('node-promise').defer
SuperModel      = require('./SuperModel')
e               = require('./EventManager')
DB              = require('./DB')
ClientEndpoints = require('./ClientEndpoints')
objStore        = require('./OStore')
error           = require('./Error').error


class ObjectManager

  constructor: (@messageRouter) ->
   @updateObjectHooks = []

  setup: () =>
    @messageRouter.addTarget('registerForUpdatesOn',  'obj', @onRegisterForUpdatesOn)
    @messageRouter.addTarget('deRegisterForUpdatesOn',  'id,listenerid', @onRegisterForUpdatesOn)
    @messageRouter.addTarget('updateObject',          'obj', @onUpdateObject)
    @messageRouter.addTarget('listTypes',             '<noargs>', @onListTypes)
    @messageRouter.addTarget('getModelFor',             'modelname', @onGetModelFor)

  registerUpdateObjectHook: (hook) =>
    @updateObjectHooks.push hook

  onListTypes: (msg) =>
    msg.replyFunc({status: e.general.SUCCESS, info: 'list types', payload: objStore.listTypes()})


  #
  # -- Fix this! Resolver needs to be instantied with dirname. Move all stuff to ResolveModule
  #
  onGetModelFor: (msg) =>
    if msg.modelname
      @messageRouter.ResolveModule.resolve msg.modelname, (model) =>
        rv = model.model.map (property) -> property.public
        msg.replyFunc({status: e.general.SUCCESS, info: 'get model', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "missing parameter", payload: null})

  #---------------------------------------------------------------------------------------------------------------------
  _createObject: (msg) =>
    if @messageRouter.authMgr.canUserCreateThisObject(msg.obj.type, msg.user)
      console.dir msg
      SuperModel.resolver.createObjectFrom(msg.obj).then (o) =>
        msg.replyFunc({status: e.general.SUCCESS, info: 'new '+msg.obj.type, payload: o.id})
    else
      msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to create objects of that type', payload: msg.obj.type})

  _deleteObject: (msg) =>
    objStore.getObject msg.obj.id, msg.obj.type.then (obj) =>
      if obj
        if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
          DB.remove obj, (removestatus) =>
            console.log 'exposed object removed through _delete'+type
            objStore.removeObject(obj)
            msg.replyFunc({status: e.general.SUCCESS, info: 'delete object', payload: obj.id})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to delete object', payload: msg.obj.id})
      else
        console.log 'No object found with id '+msg.obj.id
        console.dir objStore.objects.map (o) -> o.type == msg.obj.type
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})

  _updateObject: (msg) =>
    @onUpdateObject(msg)

  _getObject: (msg) =>
    objStore.getObject msg.obj.id, msg.obj.type.then (obj) =>
      if obj
        if @messageRouter.authMgr.canUserReadFromThisbject(obj, msg.user)
          msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj.toClient()})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to read from that object', payload: msg.obj.id})
      else
        console.log 'No object found with id '+msg.obj.id
        console.dir objStore.objects.map (o) -> o.type == msg.obj.type
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})

  _listObjects: (msg) =>
    if not @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user)
      msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
    else
      rv = objStore.listObjectsByType(msg.type)
      msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})

  #---------------------------------------------------------------------------------------------------------------------

  expose: (type) =>
    objStore.types[type] = type
    @messageRouter.expose(type)

  onUpdateObject: (msg) =>
    console.log 'onUpdateObject called for '+msg.obj.type+' - '+msg.obj.id
    objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj
        if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
          objStore.updateObj(msg.obj)
          console.log 'persisiting '+obj.id+' type '+obj.type+' in db'
          record = obj.getRecord()
          DB.set(obj.type, record)
          @updateObjectHooks.forEach (hook) => hook(record)
          msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.UPDATE_OBJECT_SUCCESS, payload: msg.obj.id})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_OBJECT_FAIL, payload: msg.obj.id})
      else
        console.log 'No object found with id '+msg.obj.id
        console.dir objStore.objects.map (o) -> o.type == msg.obj.type
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
    )
  #---------------------------------------------------------------------------------------------------------------------

  onRegisterForUpdatesOn: (msg) =>
    console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
    objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj && obj.id
        if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
          listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
            console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
            #console.dir uobj
            ClientEndpoints.sendToEndpoint(msg.client, {status: e.general.SUCCESS, info: e.gamemanager.OBJECT_UPDATE, payload: uobj.toClient() })
          )
          msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.REGISTER_UPDATES, payload: listenerId})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_REGISTER_FAIL, payload: msg.obj.id })
      else
        console.dir obj
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
    , error)

  onDeregisterForUpdatesOn: (msg) =>
    console.log 'onDeregisterForUpdatesOn called for id '+msg.id+' and listener id '+msg.listenerid
    objStore.removeListenerFor(msg.id, msg.obj.listenerid)
    msg.replyFunc({status: e.general.SUCCESS, info: 'deregistered listener for obejct', payload: msg.id })


module.exports = ObjectManager
