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
    @messageRouter.addTarget('updateObject',          'obj', @onUpdateObject)
    @messageRouter.addTarget('listTypes',             '<noargs>', @onListTypes)

  registerUpdateObjectHook: (hook) =>
    @updateObjectHooks.push hook

  onListTypes: (msg) =>
    msg.replyFunc({status: e.general.SUCCESS, info: 'list types', payload: objStore.listTypes()})

  #---------------------------------------------------------------------------------------------------------------------
  expose: (type) =>
    objStore.types[type] = type
    @messageRouter.addTarget '_create'+type, 'obj', (msg) =>
      console.dir msg
      if msg.odata.type == type and @messageRouter.authMgr.canUserCreateThisObject(msg.odata, msg.user)
        SuperModel.resolver.createObjectFrom(msg.odata).then (o) =>
          msg.replyFunc({status: e.general.SUCCESS, info: 'new '+type, payload: o.id})

    # TODO: delete object hierarchy as well? Maybe also check for other objects referencing this, disallowing if so
    @messageRouter.addTarget '_delete'+type, 'obj', (msg) =>
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

    @messageRouter.addTarget '_update'+type, 'obj', (msg) =>
        @onUpdateObject(msg)

    @messageRouter.addTarget '_get'+type, 'obj', (msg) =>
      objStore.getObject msg.obj.id, msg.obj.type.then (obj) =>
        if obj
          msg.replyFunc({status: e.general.SUCCESS, info: 'get object', payload: obj.toClient()})
        else
          console.log 'No object found with id '+msg.obj.id
          console.dir objStore.objects.map (o) -> o.type == msg.obj.type
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})

    @messageRouter.addTarget '_list'+type+'s', '<noargs>', (msg) =>
      if not @messageRouter.authMgr.canUserListTheseObjects(msg.type, msg.user)
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: 'not allowed to list objects of type '+msg.type, payload: msg.type})
      else
        rv = objStore.listObjectsByType(msg.type)
        msg.replyFunc({status: e.general.SUCCESS, info: 'list objects', payload: rv})

  onUpdateObject: (msg) =>
    console.log 'onUpdateObject called for '+msg.obj.type+' - '+msg.obj.id
    objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj
        if @messageRouter.authMgr.canUserWriteToThisObject(obj, msg.user)
          objStore.updateObj(msg.obj)
          console.log 'persisiting '+obj.id+' rev '+obj._rev+' in db'
          record = obj._getRecord()
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
  # TODO: Add removeListener as well..

  onRegisterForUpdatesOn: (msg) =>
    console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
    objStore.getObject(msg.obj.id, msg.obj.type).then( (record) =>
      if record
        if @messageRouter.authMgr.canUserReadFromThisObject(record, msg.user)
          listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
            console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
            #console.dir uobj
            ClientEndpoints.sendToEndpoint(msg.client, {status: e.general.SUCCESS, info: e.gamemanager.OBJECT_UPDATE, payload: uobj.toClient() })
          )
          msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.REGISTER_UPDATES, payload: listenerId})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_REGISTER_FAIL, payload: msg.obj.id })
      else
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
    , error)


module.exports = ObjectManager
