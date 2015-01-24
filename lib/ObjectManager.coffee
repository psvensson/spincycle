util            = require('util')
defer           = require('node-promise').defer

e               = require('./EventManager')
DB              = require('./DB')
ClientEndpoints = require('./ClientEndpoints')
objStore        = require('./OStore')
error           = require('./Error').error


class ObjectManager

  constructor: (@messageRouter) ->
    @games = []

  setup: () =>
    @messageRouter.addTarget('registerForUpdatesOn',  'obj', @onRegisterForUpdatesOn)
    @messageRouter.addTarget('updateObject',          'obj', @onUpdateObject)


  onUpdateObject: (msg) =>
    console.log 'onUpdateObject called for '+msg.obj.type+' - '+msg.obj.id
    objStore.getObj(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj
        if @messageRouter.authMgr.canPlayerWriteToThisObject(obj, msg.player)
          objStore.updateObj(msg.obj)
          DB.set(obj.type, objStore.get(msg.obj.id))
          msg.replyFunc(e.event(e.general.SUCCESS, 0, e.gamemanager.UPDATE_OBJECT_SUCCESS, msg.obj.id))
        else
          msg.replyFunc(e.event(e.general.NOT_ALLOWED, 0, e.gamemanager.UPDATE_OBJECT_FAIL, msg.obj.id))
      else
        msg.replyFunc(e.event(e.general.NOT_ALLOWED, 0, e.gamemanager.NO_SUCH_OBJECT, msg.obj.id))
    )

  # TODO: Add removeListener as well..

  onRegisterForUpdatesOn: (msg) =>
    console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
    console.dir msg

    objStore.getObj(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj
        if @messageRouter.authMgr.canPlayerReadFromThisObject(obj, msg.player)
          listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
            console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
            if not uobj then console.dir uobj
            ClientEndpoints.sendToEndpoint(msg.client, e.event(e.general.SUCCESS, 0, e.gamemanager.OBJECT_UPDATE, uobj.toClient()))
          )
          msg.replyFunc(e.event(e.general.SUCCESS, 0, e.gamemanager.REGISTER_UPDATES, listenerId))
        else
          msg.replyFunc(e.event(e.general.NOT_ALLOWED, 0, e.gamemanager.UPDATE_REGISTER_FAIL, obj.name))
      else
        msg.replyFunc(e.event(e.general.NOT_ALLOWED, 0, e.gamemanager.NO_SUCH_OBJECT, msg.obj.id))
    , error)


module.exports = ObjectManager
