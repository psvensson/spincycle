define('spinclient', ['Q', 'uuid4', 'io'], (q, uuid4, io) =>

  spinc =
  {
    subscribers: []
    objsubscribers: []
    objectsSubscribedTo: []
    outstandingMessages: []
    modelcache: []
    rightscache: []

    io: io()

    sessionId: null
    objects: []
    failureMessage: undefined

    failed: (msg)->
      console.log 'spinclient message failed!! ' + msg

    setSessionId: (id) ->
      if(id)
        console.log '++++++++++++++++++++++++++++++++++++++ spinclient setting session id to ' + id
        spinc.sessionId = id

    dumpOutstanding: ()->
      #console.log '-------------------------------- '+spinc.outstandingMessages.length+' outstanding messages ---------------------------------'
      #spinc.outstandingMessages.forEach (os)->
      #  console.log os.messageId+' -> '+os.target+' - '+os.d
      #console.log '-----------------------------------------------------------------------------------------'

    setWebSocketInstance: (io) =>
      spinc.io = io

      spinc.io.on 'message', (reply) ->
        status = reply.status
        message = reply.payload
        info = reply.info
        #console.log 'got reply messageId ' + reply.messageId + ' status ' + status + ', info ' + info + ' data ' + message + ' outstandingMessages = '+spinc.outstandingMessages.length
        spinc.dumpOutstanding()
        #console.dir reply
        index = -1
        if reply.messageId
          i = 0
          while i < spinc.outstandingMessages.length
            detail = spinc.outstandingMessages[i]
            if detail.messageId == reply.messageId
              if reply.status == 'FAILURE'
                console.log 'spinclient message FAILURE'
                console.dir reply
                spinc.failuremessage = reply.info
                spinc.infomessage = ''
                detail.d.reject reply
                break
              else
                #console.log 'delivering message '+message+' reply to '+detail.target+' to '+reply.messageId
                spinc.infomessage = reply.info
                spinc.failuremessage = ''
                detail.d.resolve(message)
                index = i
                break
            i++
          if index > -1
            #console.log 'removing outstanding reply'
            spinc.outstandingMessages.splice index, 1
        else
          subscribers = spinc.subscribers[info]
          if subscribers
            subscribers.forEach (listener) ->
              console.log("sending reply to listener");
              console.dir listener
              listener message
          else
            console.log 'no subscribers for message ' + message
            console.dir reply

    registerListener: (detail) ->
      console.log 'spinclient::registerListener called for ' + detail.message
      subscribers = spinc.subscribers[detail.message] or []
      subscribers.push detail.callback
      spinc.subscribers[detail.message] = subscribers

    registerObjectSubscriber: (detail) ->
      d = q.defer()
      sid = uuid4.generate()
      localsubs = spinc.objectsSubscribedTo[detail.id]
      #console.log 'registerObjectSubscriber localsubs is'
      #console.dir localsubs
      if not localsubs
        localsubs = []
        #console.log 'no local subs, so get the original server-side subscription for id '+detail.id
        # actually set up subscription, once for each object
        spinc._registerObjectSubscriber({
          id: detail.id, type: detail.type, cb: (updatedobj) ->
#console.log '-- registerObjectSubscriber getting obj update callback for '+detail.id
            lsubs = spinc.objectsSubscribedTo[detail.id]
            #console.dir(lsubs)
            for k,v of lsubs
              if (v.cb)
#console.log '--*****--*****-- calling back object update to local sid --****--*****-- '+k
                v.cb updatedobj
        }).then (remotesid) ->
          localsubs['remotesid'] = remotesid
          localsubs[sid] = detail
          #console.log '-- adding local callback listener to object updates for '+detail.id+' local sid = '+sid+' remotesid = '+remotesid
          spinc.objectsSubscribedTo[detail.id] = localsubs
          d.resolve(sid)
      return d.promise

    _registerObjectSubscriber: (detail) ->
      d = q.defer()
      #console.log 'message-router registering subscriber for object ' + detail.id + ' type ' + detail.type
      subscribers = spinc.objsubscribers[detail.id] or []

      spinc.emitMessage({target: 'registerForUpdatesOn', obj: {id: detail.id, type: detail.type}}).then(
        (reply)->
#console.log 'server subscription id for id '+detail.id+' is '+reply
          subscribers[reply] = detail.cb
          spinc.objsubscribers[detail.id] = subscribers
          d.resolve(reply)
      , (reply)->
        spinc.failed(reply)
      )
      return d.promise


    deRegisterObjectSubscriber: (sid, o) =>
      localsubs = spinc.objectsSubscribedTo[o.id] or []
      if localsubs[sid]
        console.log 'deregistering local updates for object ' + o.id
        delete localsubs[sid]
        count = 0
        for k,v in localsubs
          count++
        if count == 1 # only remotesid property left
          spinc._deRegisterObjectSubscriber('remotesid', o)

    _deRegisterObjectSubscriber: (sid, o) =>
      subscribers = spinc.objsubscribers[o.id] or []
      if subscribers and subscribers[sid]
        delete subscribers[sid]
        spinc.objsubscribers[o.id] = subscribers
        spinc.emitMessage({target: 'deRegisterForUpdatesOn', id: o.id, type: o.type, listenerid: sid}).then (reply)->
          console.log 'deregistering server updates for object ' + o.id

    emitMessage: (detail) ->
      d = q.defer()
      try
        detail.messageId = uuid4.generate()
        detail.sessionId = spinc.sessionId
        detail.d = d
        spinc.outstandingMessages.push detail
        #console.log 'saving outstanding reply to messageId '+detail.messageId+' and sessionId '+detail.sessionId
        spinc.io.emit 'message', JSON.stringify(detail)
      catch e
        console.log 'spinclient emitMessage ERROR: ' + e

      return d.promise

# ------------------------------------------------------------------------------------------------------------------

    getModelFor: (type) ->
      d = q.defer()
      if spinc.modelcache[type]
        d.resolve(spinc.modelcache[type])
      else
        spinc.emitMessage({target: 'getModelFor', modelname: type}).then((model)->
          spinc.modelcache[type] = model
          d.resolve(model))
      return d.promise

    getRightsFor: (type) ->
      d = q.defer()
      if spinc.rightscache[type]
        d.resolve(spinc.rightscache[type])
      else
        spinc.emitMessage({target: 'getAccessTypesFor', modelname: type}).then((rights)->
          spinc.rightscache[type] = rights
          d.resolve(rights))
      return d.promise

    listTargets: () ->
      d = q.defer()
      spinc.emitMessage({target: 'listcommands'}).then((targets)-> d.resolve(targets))
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

  spinc.subscribers['OBJECT_UPDATE'] = [(obj) ->
    subscribers = spinc.objsubscribers[obj.id] or []
    for k,v of subscribers
      if not spinc.objects[obj.id]
        spinc.objects[obj.id] = obj
      else
        o = spinc.objects[obj.id]
        for prop, val of obj
          o[prop] = val
      v obj
  ]
  spinc
)
