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
    @messageRouter.addTarget('deRegisterForUpdatesOn',  'id,listenerid', @onDeregisterForUpdatesOn)
    @messageRouter.addTarget('updateObject',          'obj', @onUpdateObject)
    @messageRouter.addTarget('listTypes',             '<noargs>', @onListTypes)
    @messageRouter.addTarget('getModelFor',             'modelname', @onGetModelFor)

  registerUpdateObjectHook: (hook) =>
    @updateObjectHooks.push hook

  onListTypes: (msg) =>
    msg.replyFunc({status: e.general.SUCCESS, info: 'list types', payload: objStore.listTypes()})

  onGetModelFor: (msg) =>
    if msg.modelname
      @messageRouter.resolver.resolve msg.modelname, (path) =>
        console.log 'onGetModelFor '+msg.modelname+' got back require path '+path
        model = require(path)
        console.log 'got model resolved to'
        console.dir model
        rv = model.model.map (property) -> property if property.public
        msg.replyFunc({status: e.general.SUCCESS, info: 'get model', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: "missing parameter", payload: null})

  #---------------------------------------------------------------------------------------------------------------------
  _createObject: (msg) =>
    if @messageRouter.authMgr.canUserCreateThisObject(msg.obj.type, msg.user)
      console.dir msg
      SuperModel.resolver.createObjectFrom(msg.obj).then (o) =>
        o.serialize()
        msg.replyFunc({status: e.general.SUCCESS, info: 'new '+msg.obj.type, payload: o})
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
    @getObjectPullThrough(msg.obj.id, msg.obj.type).then (obj) =>
      if obj
        if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
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

  getObjectPullThrough: (id, type) =>
    q = defer()
    objStore.getObject(id, type).then (o) =>
      if not o
        DB.get(type, [id]).then (record) =>
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
          # Make sure to resolve object references in arrays and hashtables
          @resolveReferences(msg.obj, obj.constructor.model).then (robj)=>
            objStore.updateObj(robj)
            console.log 'persisting '+obj.id+' type '+obj.type+' in db'
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

  resolveReferences: (record, model) =>
    console.log 'resolveReferences model is '
    console.dir model
    rv = {id: record.id}
    q = defer()
    count = model.length

    checkFinished = () ->
      #console.log 'checkFinished count = '+count
      #console.dir rv
      if --count == 0
        #console.log 'resolving back object'
        q.resolve(rv)

    model.forEach (property) =>
      console.log 'going through property '+property
      if property.array
        resolvedarr = []
        arr = record[property.name] or []
        acount = arr.length
        arr.forEach (id) =>
          console.log 'attempting to get object type '+property.type+' id '+id
          @getObjectPullThrough(id, property.type).then (o)=>
            #console.log ' we got object '+o
            #console.dir o
            resolvedarr.push(o)
            console.log 'adding array reference '+o.id+' name '+o.name
            if --acount == 0
              rv[property.name] = resolvedarr
              checkFinished()
      else if property.hashtable
        resolvedhash = {}
        harr = record[property.name] or []
        hcount = harr.length
        harr.forEach (id) =>
          @getObjectPullThrough(id, property.type).then (o)=>
            resolvedhash[o.name] = o
            console.log 'adding hashtable reference '+o.id+' name '+o.name
            if --hcount == 0
              rv[property.name] = resolvedhash
              checkFinished()
      else
        rv[property.name] = record[property.name]
        checkFinished()

    return q

  #---------------------------------------------------------------------------------------------------------------------

  onRegisterForUpdatesOn: (msg) =>
    console.dir msg
    console.log 'onRegisterForUpdatesOn called for '+msg.obj.type+' '+msg.obj.id
    objStore.getObject(msg.obj.id, msg.obj.type).then( (obj) =>
      if obj && obj.id
        if @messageRouter.authMgr.canUserReadFromThisObject(obj, msg.user)
          listenerId = objStore.addListenerFor(msg.obj.id, msg.obj.type, (uobj) ->
            console.log '--------------------- sending update of object '+msg.obj.id+' type '+msg.obj.type+' to client'
            #console.dir uobj
            ClientEndpoints.sendToEndpoint(msg.client, {status: e.general.SUCCESS, info: e.gamemanager.OBJECT_UPDATE, payload: uobj.toClient() })
          )
          console.log 'listenerid '+listenerId+' added for updates on object '+obj.name+' ['+obj.id+']'
          msg.replyFunc({status: e.general.SUCCESS, info: e.gamemanager.REGISTER_UPDATES, payload: listenerId})
        else
          msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.UPDATE_REGISTER_FAIL, payload: msg.obj.id })
      else
        console.dir obj
        msg.replyFunc({status: e.general.NOT_ALLOWED, info: e.gamemanager.NO_SUCH_OBJECT, payload: msg.obj.id })
    , error)

  onDeregisterForUpdatesOn: (msg) =>
    console.log 'onDeregisterForUpdatesOn called for id '+msg.id+' and listener id '+msg.listenerid
    if msg.id and msg.listenerid and msg.type
      objStore.removeListenerFor(msg.id, msg.listenerid)
      msg.replyFunc({status: e.general.SUCCESS, info: 'deregistered listener for obejct', payload: msg.id })
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'missing parameter', payload: null })

module.exports = ObjectManager
