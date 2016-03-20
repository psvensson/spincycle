

window.spinc = {

  subscribers         : []
  objsubscribers      : []
  objectsSubscribedTo : []

  outstandingMessages : []
  modelcache          : []
  rightscache          : []

  io                  : null
  sessionId           : null
  objects             : []
  failureMessage      : undefined

  failed: (msg)->
    console.log 'spinclient message failed!! '+msg

  setSessionId: (id) ->
    if(id)
      console.log '++++++++++++++++++++++++++++++++++++++ spinclient setting session id to '+id
      service.sessionId = id

  dumpOutstanding: ()->
#console.log '-------------------------------- '+service.outstandingMessages.length+' outstanding messages ---------------------------------'
#service.outstandingMessages.forEach (os)->
#  console.log os.messageId+' -> '+os.target+' - '+os.d
#console.log '-----------------------------------------------------------------------------------------'

  setWebSocketInstance: (io) =>
    service.io = io

    service.io.on 'message', (reply) ->
      status = reply.status
      message = reply.payload
      info = reply.info
      #console.log 'got reply messageId ' + reply.messageId + ' status ' + status + ', info ' + info + ' data ' + message + ' outstandingMessages = '+service.outstandingMessages.length
      service.dumpOutstanding()
      #console.dir reply
      index = -1
      if reply.messageId
        i = 0
        while i < service.outstandingMessages.length
          detail = service.outstandingMessages[i]
          if detail.messageId == reply.messageId
            if reply.status == 'FAILURE'
              console.log 'spinclient message FAILURE'
              console.dir reply
              service.failuremessage = reply.info
              service.infomessage = ''
              detail.d.reject reply
              break
            else
#console.log 'delivering message '+message+' reply to '+detail.target+' to '+reply.messageId
              service.infomessage = reply.info
              service.failuremessage = ''
              detail.d.resolve(message)
              index = i
              break
          i++
        if index > -1
#console.log 'removing outstanding reply'
          service.outstandingMessages.splice index, 1
      else
        subscribers = service.subscribers[info]
        if subscribers
          subscribers.forEach (listener) ->
#console.log("sending reply to listener");
            listener message
        else
          console.log 'no subscribers for message ' + message
          console.dir reply

  registerListener: (detail) ->
    console.log 'spinclient::registerListener called for '+detail.message
    subscribers = service.subscribers[detail.message] or []
    subscribers.push detail.callback
    service.subscribers[detail.message] = subscribers

  registerObjectSubscriber: (detail) ->
    d = $q.defer()
    sid = uuid4.generate()
    localsubs = service.objectsSubscribedTo[detail.id]
    #console.log 'registerObjectSubscriber localsubs is'
    #console.dir localsubs
    if not localsubs
      localsubs = []
      #console.log 'no local subs, so get the original server-side subscription for id '+detail.id
      # actually set up subscription, once for each object
      service._registerObjectSubscriber({id: detail.id, type: detail.type, cb: (updatedobj) ->
#console.log '-- registerObjectSubscriber getting obj update callback for '+detail.id
        lsubs = service.objectsSubscribedTo[detail.id]
        #console.dir(lsubs)
        for k,v of lsubs
          if (v.cb)
#console.log '--*****--*****-- calling back object update to local sid --****--*****-- '+k
            v.cb updatedobj
      }).then (remotesid) ->
        localsubs['remotesid'] = remotesid
        localsubs[sid] = detail
        #console.log '-- adding local callback listener to object updates for '+detail.id+' local sid = '+sid+' remotesid = '+remotesid
        service.objectsSubscribedTo[detail.id] = localsubs
        d.resolve(sid)
    return d.promise

  _registerObjectSubscriber: (detail) ->
    d = $q.defer()
    #console.log 'message-router registering subscriber for object ' + detail.id + ' type ' + detail.type
    subscribers = service.objsubscribers[detail.id] or []

    service.emitMessage({target: 'registerForUpdatesOn', obj: {id: detail.id, type: detail.type} }).then(
      (reply)->
#console.log 'server subscription id for id '+detail.id+' is '+reply
        subscribers[reply] = detail.cb
        service.objsubscribers[detail.id] = subscribers
        d.resolve(reply)
    ,(reply)->
      service.failed(reply)
    )
    return d.promise


  deRegisterObjectSubscriber: (sid, o) =>
    localsubs = service.objectsSubscribedTo[o.id] or []
    if localsubs[sid]
      console.log 'deregistering local updates for object '+o.id
      delete localsubs[sid]
      count = 0
      for k,v in localsubs
        count++
      if count == 1 # only remotesid property left
        service._deRegisterObjectSubscriber('remotesid', o)

  _deRegisterObjectSubscriber: (sid, o) =>
    subscribers = service.objsubscribers[o.id] or []
    if subscribers and subscribers[sid]
      delete subscribers[sid]
      service.objsubscribers[o.id] = subscribers
      service.emitMessage({target: 'deRegisterForUpdatesOn', id:o.id, type: o.type, listenerid: sid } ).then (reply)->
        console.log 'deregistering server updates for object '+o.id

  emitMessage : (detail) ->
    d = $q.defer()
    try
      detail.messageId = uuid4.generate()
      detail.sessionId = service.sessionId
      detail.d = d
      service.outstandingMessages.push detail
      #console.log 'saving outstanding reply to messageId '+detail.messageId+' and sessionId '+detail.sessionId
      service.io.emit 'message', JSON.stringify(detail)
    catch e
      console.log 'spinclient emitMessage ERROR: '+e

    return d.promise

# ------------------------------------------------------------------------------------------------------------------

  getModelFor: (type) ->
    d = $q.defer()
    if service.modelcache[type]
      d.resolve(service.modelcache[type])
    else
      service.emitMessage({target:'getModelFor', modelname: type}).then((model)->
        service.modelcache[type] = model
        d.resolve(model))
    return d.promise

  getRightsFor: (type) ->
    d = $q.defer()
    if service.rightscache[type]
      d.resolve(service.rightscache[type])
    else
      service.emitMessage({target:'getAccessTypesFor', modelname: type}).then((rights)->
        service.rightscache[type] = rights
        d.resolve(rights))
    return d.promise

  listTargets: () ->
    d = $q.defer()
    service.emitMessage({target:'listcommands'}).then((targets)-> d.resolve(targets))
    return d.promise

  flattenModel: (model) ->
    rv = {}
    for k,v of model
      if angular.isArray(v)
        rv[k] = v.map (e) -> e.id
      else
        rv[k] = v
    return rv
}

window.spinc.subscribers['OBJECT_UPDATE'] = [ (obj) ->
#console.log 'spinclient +++++++++ obj update message router got obj'
#console.dir(obj);
  subscribers = service.objsubscribers[obj.id] or []
  for k,v of subscribers
#console.log 'updating subscriber to object updates on id '+k
    if not service.objects[obj.id]
      service.objects[obj.id] = obj
    else
      o = service.objects[obj.id]
      for prop, val of obj
        o[prop] = val
    v obj
]
