#uuid = require('node-uuid')
#$q = require('node-promise')
#lru = require('lru')
$q = Q
#debug = process.env['DEBUG']

opts =
  max: 1000
  maxAgeInMilliseconds: 1000 * 60 * 60 * 24 * 4 # 4 days timeout of objects no matter what

debug = true
uuid = UUID4

class spinpolymer

  constructor: (@dbUrl) ->
    @open = false
    @subscribers = {}
    @objsubscribers = []
    @popsubscribers = {}
    @populationsubscribers = {}
    @objectsSubscribedTo = []

    @outstandingMessages = []
    @modelcache = []

    @seenMessages = []
    @sessionId = null
    @objects = new LRUCache(opts)

    @failure = false
    @failureMessage = ''

    @savedMessagesInCaseOfRetries = new LRUCache({max:1000, maxAgeInMilliseconds: 5000})

    if debug then console.log 'polymer-spincycle dbUrl = ' + @dbUrl

    @subscribers['OBJECT_UPDATE'] = [(obj) =>
      console.log 'spinpolymer +++++++++ obj update message router got obj '+obj.id+' of type '+obj.type
      #console.dir(obj);
      #console.dir(@objsubscribers)
      objsubs = @objsubscribers[obj.id] or []
      for k,v of objsubs
#console.log 'updating subscriber to @objects updates on id '+k
        if not @objects.get(obj.id)
          @objects.set(obj.id, obj)
        else
          o = @objects.get(obj.id)
          for prop, val of obj
            o[prop] = val
        v obj
    ]

    @subscribers['POPULATION_UPDATE'] = [(update) =>
      console.log 'spinpolymer +++++++++ population update message router got update'
      #console.dir update
      obj = update.added or update.deleted
      if obj
        objsubs = @populationsubscribers[obj.type] or {}
        for k,v of objsubs
          if v.cb then v.cb obj
    ]

    @setup()

  failed: (msg)->
    console.log 'spinclient message failed!! ' + msg
    if @onFailure then @onFailure msg.info

  setSessionId: (id) ->
    if(id)
      console.log '++++++++++++++++++++++++++++++++++++++ spinclient setting session id to ' + id
      @sessionId = id

  dumpOutstanding: ()->
    console.log '-------------------------------- ' + @outstandingMessages.length + ' outstanding messages ---------------------------------'
    @outstandingMessages.forEach (os)->
      console.log os.messageId + ' -> ' + os.target + ' - ' + os.d
    console.log '-----------------------------------------------------------------------------------------'

  emit: (message) =>
    @_emit(message)

  _emit:(message)=>
    #console.log 'emitting message '+message
    #console.dir message
    @savedMessagesInCaseOfRetries.set(message.messageId, message)
    @socket.emit('message', JSON.stringify(message))

  setup: () =>
    console.log '..connecting to '+@dbUrl
    @socket = io(@dbUrl,{path: @dbUrl+'/socket.io'})
    @socket.on 'connect', ()=>
      @emit({target:'listcommands'})

    @socket.on 'message', (reply) =>
      #console.log '***** got message ******'
      #console.dir reply
      
      status = reply.status
      message = reply.payload
      info = reply.info

      isNew = not @hasSeenThisMessage reply.messageId
      isPopulationUpdate = (reply.info == 'POPULATION_UPDATE')

      #console.log 'info = '+info

      if info == 'list of available targets'
        console.log 'Spincycle server channel is up and awake'
        @open = true
      else
        if message and message.error and message.error == 'ERRCHILLMAN'
          oldmsg = @savedMessagesInCaseOfRetries[reply.messageId]
          if oldmsg
            console.log 'got ERRCHILLMAN from spinycle service, preparing to retry sending message...'
            setTimeout(
              ()=>
                console.log 'resending message '+oldmsg.messageId+' due to target endpoint not open yet'
                @emit(oldmsg)
            ,250
            )

        else if isNew
          @savedMessagesInCaseOfRetries.remove(reply.messageId)
          if reply.messageId and reply.messageId isnt 'undefined' then @seenMessages.push(reply.messageId)
          if @seenMessages.length > 10 then @seenMessages.shift()
          index = -1
          if reply.messageId
            i = 0
            while i < @outstandingMessages.length
              index = i
              detail = @outstandingMessages[i]
              if detail and not detail.delivered and detail.messageId == reply.messageId
                if reply.status == 'FAILURE' or reply.status == 'NOT_ALLOWED'
                  console.log 'spinclient message FAILURE'
                  console.dir reply
                  @failure = true
                  @failureMessage = reply.info
                  console.log '--- initial message was'
                  console.dir detail
                  @failed(reply)
                  detail.d.reject reply
                  break
                else
                  #console.log 'delivering message '+message+' reply to '+detail.target+' to '+reply.messageId
                  detail.d.resolve(message)
                  break
                detail.delivered = true
              i++
            if index > -1
              @outstandingMessages.splice index, 1
          else
            subs = @subscribers[info]
            if subs
              subs.forEach (listener) ->
                listener message
            else
              if debug then console.log 'no subscribers for message ' + message
              if debug then console.dir reply
        else
          if debug then console.log '-- skipped resent message ' + reply.messageId

  hasSeenThisMessage: (messageId) =>
    @seenMessages.some (mid) -> messageId == mid

  registerListener: (detail) =>
#console.log 'spinclient::registerListener called for ' + detail.message
    subs = @subscribers[detail.message] or []
    subs.push detail.callback
    @subscribers[detail.message] = subs

  deRegisterPopulationChangesSubscriber: (detail) =>
    sid = detail.listenerid
    type = detail.type
    localsubs = @populationsubscribers[type]
    if localsubs[sid]
      console.log 'deregistering local updates for model type ' + type
      delete localsubs[sid]
      count = 0
      for k,v in localsubs
        count++
      if count == 1 # only remotesid property left
        @_deRegisterPopulationChangesSubscriber('remotesid', type)

  _deRegisterPopulationChangesSubscriber: (sid, type) =>
    subs = @popsubscribers[type] or []
    if subs and subs[sid]
      delete subs[sid]
      @popsubscribers[type] = subs
      @emitMessage({target: 'deRegisterForPopulationChangesFor', type: type, listenerid: sid}).then (reply)->
        console.log 'deregistering server updates for population changes for '+type


  registerPopulationChangeSubscriber: (detail) =>
    #console.log 'registerPopulationChangeSubscriber called for '+detail.type
    d = $q.defer()
    sid = uuid.generate()
    localsubs = @populationsubscribers[detail.type]
    if not localsubs
      localsubs = {}
      @_registerPopulationSubscriber(
        {
          type: detail.type
          cb: (updatedobj) =>
            lsubs = @populationsubscribers[detail.type]
            for k,v of lsubs
              if (v.cb)
                v.cb updatedobj
        }).then( (remotesid) =>
          localsubs['remotesid'] = remotesid
          localsubs[sid] = detail
          @populationsubscribers[detail.type] = localsubs
          d.resolve(sid)
        ,(rejection)=>
          console.log 'spinpolymer registerPopulationSubscriber rejection: '+rejection
          console.dir rejection
      )
    else
      localsubs[sid] = detail
    return d.promise

  _registerPopulationSubscriber: (detail) =>
    d = $q.defer()
    subs = @popsubscribers[detail.type] or {}
    #console.log '_registerPopulationChangeSubscriber called for '+detail.type
    @emitMessage({target: 'registerForPopulationChangesFor', type: detail.type}).then(
      (reply)=>
        subs[reply] = detail.cb
        @popsubscribers[detail.type] = subs
        d.resolve(reply)
    , (reply)=>
      @failed(reply)
    )
    return d.promise

  registerObjectSubscriber: (detail) =>
    d = $q.defer()
    sid = uuid.generate()
    localsubs = @objectsSubscribedTo[detail.id]
    if not localsubs
      localsubs = []
      @_registerObjectSubscriber({
        id: detail.id, type: detail.type, cb: (updatedobj) =>
          lsubs = @objectsSubscribedTo[detail.id]
          for k,v of lsubs
            if (v.cb)
              v.cb updatedobj
      }).then( (remotesid) =>
        localsubs['remotesid'] = remotesid
        localsubs[sid] = detail
        @objectsSubscribedTo[detail.id] = localsubs
        d.resolve(sid)
      ,(rejection)=>
        console.log 'spinpolymer registerObjectSubscriber rejection: '+rejection
        console.dir rejection
      )
    else
      localsubs[sid] = detail
    return d.promise

  _registerObjectSubscriber: (detail) =>
    d = $q.defer()
    subs = @objsubscribers[detail.id] or []
    @emitMessage({target: 'registerForUpdatesOn', obj: {id: detail.id, type: detail.type}}).then(
      (reply)=>
        subs[reply] = detail.cb
        @objsubscribers[detail.id] = subs
        d.resolve(reply)
    , (reply)=>
      @failed(reply)
    )
    return d.promise

  deRegisterObjectsSubscriber: (sid, o) =>
    localsubs = @objectsSubscribedTo[o.id] or []
    if localsubs[sid]
      console.log 'deregistering local updates for @objects ' + o.id
      delete localsubs[sid]
      count = 0
      for k,v in localsubs
        count++
      if count == 1 # only remotesid property left
        @_deRegisterObjectsSubscriber('remotesid', o)

  _deRegisterObjectsSubscriber: (sid, o) =>
    subs = @objsubscribers[o.id] or []
    if subs and subs[sid]
      delete subs[sid]
      @objsubscribers[o.id] = subs
      @emitMessage({target: 'deRegisterForUpdatesOn', id: o.id, type: o.type, listenerid: sid}).then (reply)->
        console.log 'deregistering server updates for @objects ' + o.id

  emitMessage: (detail) =>
#if debug then console.log 'emitMessage called'
#if debug then console.dir detail
    d = $q.defer()
    detail.messageId = uuid.generate()
    detail.sessionId = detail.sessionId or @sessionId
    detail.d = d
    #console.log '------------------> EmitMessage sessionId = '+detail.sessionId
    @outstandingMessages.push detail
    #if debug then console.log 'saving outstanding reply to messageId ' + detail.messageId + ' and @sessionId ' + detail.sessionId
    @emit detail
    

    return d.promise

# ------------------------------------------------------------------------------------------------------------------

  getModelFor: (type) =>
    d = $q.defer()
    if @modelcache[type]
      d.resolve(@modelcache[type])
    else
      @emitMessage({target: 'getModelFor', modelname: type}).then((model)->
        @modelcache[type] = model
        d.resolve(model)
      ,(rejection)=>
        console.log 'spinpolymer getModelFor rejection: '+rejection
        console.dir rejection
      )
    return d.promise

  listTargets: () =>
    d = $q.defer()
    @emitMessage({target: 'listcommands'}).then((targets)->
      d.resolve(targets)
    ,(rejection)->
      console.log 'spinpolymer listTargets rejection: '+rejection
      console.dir rejection
    )
    return d.promise

  flattenModel: (model) =>
    rv = {}
    for k,v of model
      if angular.isArray(v)
        rv[k] = v.map (e) -> e.id
      else
        rv[k] = v
    return rv

window.SpinClient = spinpolymer