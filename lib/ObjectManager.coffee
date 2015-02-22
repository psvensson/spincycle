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
    objStore.getObject(msg.obj.id, msg.obj.type).then( (record) =>
      if record
        if @messageRouter.authMgr.canUserWriteToThisObject(record, msg.user)
          objStore.updateObj(msg.obj)
          DB.set(record.type, objStore.getObject(msg.obj.id))
          msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.UPDATE_OBJECT_SUCCESS, payload: msg.obj.id})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_OBJECT_FAIL, payload: msg.obj.id})
      else
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id})
    )

  # TODO: Add removeListener as well..

  onRegisterForUpdatesOn: (msg) =>
    console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
    #console.dir msg

    objStore.getRecord(msg.obj.id, msg.obj.type).then( (record) =>
      if record
        if @messageRouter.authMgr.canUserReadFromThisObject(record, msg.user)
          listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
            console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
            if not uobj then console.dir uobj
            ClientEndpoints.sendToEndpoint(msg.client, {status: e.general.SUCCESS, info: e.gamemanager.OBJECT_UPDATE, payload: uobj.toClient() })
          )
          msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.REGISTER_UPDATES, payload: listenerId})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_REGISTER_FAIL, payload: obj.id })
      else
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
    , error)


module.exports = ObjectManager
