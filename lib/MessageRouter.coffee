ObjectManager   = require('./ObjectManager')
error           = require('./Error').error
HttpMethod      = require('./HttpMethod');
WsMethod        = require('./WsMethod');
RedisMethod     = require('./RedisMethod')
DB              = require('./DB')
EventManager    = require('./EventManager')
SuperModel      = require('./SuperModel')
SpinModule      = require('./SpinModule')
SpinApp         = require('./SpinApp')
SpinFunction    = require('./SpinFunction')
SpinTag         = require('./SpinTag')
ClientEndpoints = require('./ClientEndpoints')
OStore          = require('./OStore')
ResolveModule   = require('./ResolveModule')
RateLimiter     = require('limiter').RateLimiter
e               = require('./EventManager')
express         = require("express")
path            = require('path')
defer           = require('node-promise').defer
serveStatic     = require('serve-static')
colors          = require('colors/safe')
DDAPI           = require('./DDAPI')
StatsD          = require('node-statsd').StatsD
Taginator       = require('./Taginator')
SpinMeta        = require('./SpinMeta')

# The MessageRouter registers names on which messages can be sent.
# The idea is to abstract away different messaging methods (WS, WebRTC, HTTP) from the logic

class MessageRouter

  @HttpMethod = HttpMethod
  @WsMethod = WsMethod
  @RedisMethod = RedisMethod
  @DB = DB
  @SpinMeta = SpinMeta
  @EventManager = EventManager
  @SuperModel = SuperModel
  @ObjectManager = ObjectManager
  @ClientEndpoints = ClientEndpoints
  @OStore = OStore
  @ResolveModule = ResolveModule
  @status = 'closed'
  @dogstatsd = undefined

  debug = process.env["DEBUG"]

  constructor: (@authMgr, dburl, msgPS, @app, dbtype = 'mongodb', @datadogOptions) ->
    q = defer()
    #console.log 'MessageRouter dbtype = '+dbtype
    # console.dir arguments
    MessageRouter.DB.dburl = dburl
    MessageRouter.DB.dbname = dbtype
    @resolver = new ResolveModule()
    ResolveModule.modulecache['SpinModule'] = SpinModule
    ResolveModule.modulecache['SpinFunction'] = SpinFunction
    ResolveModule.modulecache['SpinApp'] = SpinApp
    ResolveModule.modulecache['SpinTag'] = SpinTag
    ResolveModule.modulecache['SpinMeta'] = SpinMeta
    DB.getDataStore(dbtype).then ()=>
      pjson = require('../package.json');
      @messagesPerSecond = msgPS or 100
      console.log colors.blue.inverse('-----------------------------------------------------------------------------------------------')
      console.log colors.blue.bold.inverse(' SpinCycle messageRouter constructor. Version - '+pjson.version+' messages per user per second limit = '+@messagesPerSecond+' ')
      console.log colors.blue.inverse('-----------------------------------------------------------------------------------------------')
      if @datadogOptions
        console.log 'datadog options are'
        console.dir @datadogOptions
        @dogstatsd  = new StatsD()
        DDAPI.init(@datadogOptions)
        #DDAPI.writePoint('swkjekjewjoew', 17, {xyz:42, abc:4711}, 'gauge')
      #console.dir @authMgr
      @authMgr.messagerouter = @

      @targets  = []
      @debugtargets  = []
      @args     = []
      @methods  = []
      #@authMgr  = AuthenticationManager
      @objectManager = new ObjectManager(@)
      @objectManager.setup()
      if @authMgr.setup then @authMgr.setup(@)
      @DB = DB
      @setup()
      q.resolve(@)

    return q

  setup: () =>
    @addTarget 'listcommands', '<noargs>', (msg) =>
      #console.log 'listCommands  called'
      rv = {listcommands: '<noarg>'}
      for name, target of @targets
        #console.log 'adding target '+name
        rv[name] = @args[name]
      msg.replyFunc({status: EventManager.general.SUCCESS, info: 'list of available targets', payload: rv})
    if @datadogOptions
      @addTarget 'ddapi', 'metric,value,tags', (msg) =>
        console.log 'ddapi got call'
        console.dir msg
        if msg.metric and msg.value
          if typeof msg.tags == 'string'
            try
              msg.tags = JSON.parse(msg.tags)
            catch err
              msg.replyFunc({status: 'FAILURE', info: 'lossy JSON format of tags', payload: msg.metric})
              return
          @gaugeMetric(msg.metric, msg.value, msg.tags or {})
          msg.replyFunc({status: 'SUCCESS', info: 'datadog metric sent', payload: msg.metric})
        else
          msg.replyFunc({status: 'FAILURE', info: 'missing parameter(s)', payload: msg.metric})
    setTimeout @addServicePage.bind(@),1

  #---------------------------------------------------------------------------------------------------------------------

  addServicePage: () =>
    #p = path.join(__dirname, 'spin')
    p = __dirname + '/spin'
    if @app
      console.log('**************** addServicePage called -> '+p)
      @app.use '/spin',express.static(p)
      @app.use '/spin/bower_components',express.static(p+'/bower_components')
      #if debug then console.dir @app._router
    else
      console.log 'no app  argument provided to MessageRouter! Unable to set up /spin route'

    console.log('**************** exposing SpinModule and SpinFunction')
    DB.createDatabases(['SpinModule', 'SpinFunction', 'SpinApp', 'SpinTag']).then ()=>
      console.log ' DB init done..'
      @objectManager.expose 'SpinModule'
      @objectManager.expose 'SpinFunction'
      @objectManager.expose 'SpinApp'
      @objectManager.expose 'SpinMeta'
      @makeRESTful('SpinModule')
      @makeRESTful('SpinFunction')
      @makeRESTful('SpinApp')
      @makeRESTful('SpinMeta')

  #---------------------------------------------------------------------------------------------------------------------

  register:(types)=>
    q = defer()
    typenames = []
    types.forEach (type)=>
      typenames.push type.name
      ResolveModule.modulecache[type.name] = type.module
      @objectManager.expose type.name
      @makeRESTful(type.name)
    DB.createDatabases(typenames).then ()=>
      q.resolve()
    return q

  expose: (type) =>
    for name, method of @methods
      method.expose(type)

  makeRESTful: (type) =>
    for name, method of @methods
      if name == 'express' then method.makeRESTful(type)

  open: () =>
    MessageRouter.status = 'open'
    console.log colors.inverse.green(' * opening message router * ')

  close: () =>
    MessageRouter.status = 'closed'
    console.log 'closing message router'

  # All messaging method adds their function for registering new paths or whatnot here
  # So for example for express you could add a method which makes sure the target name
  # can be reached by the url ../<targetName>
  addMethod: (methodName, method) =>
    console.log 'addMethod called for "'+methodName+'"'
    @methods[methodName] = method
    for targetName of @targets
      #console.log 'registering target '+targetName+' on method '+methodName
      method.registrationFunc(targetName, @routeMessage)

  addTarget: (targetName, args, targetFunc, props) =>
    #console.log 'adding route target for "'+targetName+'" args = '+args
    @targets[targetName] = targetFunc
    @args[targetName] = args
    for name,method of @methods
      #console.log 'registering target '+targetName+' on method '+name
      if method.registrationFunc
        method.registrationFunc(targetName, @routeMessage, props)
      else
        console.log 'Spincycle did NOT find target for '+targetName
        console.log '----------------methods-------------------'
        console.dir @methods

  removeTarget: (targetName) =>
    @targets[targetName] = null

  # Message format is {messageId: i, client: <ip:port>, messageTarget: t, replyFunction: r, messageBody: {b}}
  # TODO: don't start serving messages until an explicit open call is issued from the owner
  routeMessage: (message) =>
    if MessageRouter.status isnt 'open'
      message.replyFunc({status: e.general.NOT_ALLOWED, info: 'Message router is not yet open', payload: {error: 'ERRCHILLMAN'}})
    else
      fn = @targets[message.target]
      #if debug then console.log 'routeMessage called for "'+message.target+'"'
      #if debug then console.dir @targets
      if fn
        @authMgr.decorateMessageWithUser(message).then( (m)=>
          if not m.user
            console.log '** SpinCycle did not get message decorated with user property from AuthenticationManager **'
            exit( -1)
          #console.log 'user found. now calling handler'
          if not m.user.limiter
            #console.log '--- creating new rate limiter for user '+m.user.id+' max request = '+parseInt(@messagesPerSecond)
            m.user.limiter = new RateLimiter(parseInt(@messagesPerSecond), 1000)
          #console.log 'remaining tokens before call is '+m.user.limiter.getTokensRemaining()
          if m.user.limiter and m.user.limiter.removeTokens
            m.user.limiter.removeTokens 1, (err, remainingRequests) =>
              #console.log 'messageRouter::routeMessage remaining requests for user is '+remainingRequests+' err = '+err
              if parseInt(remainingRequests) < 1
                m.replyFunc({status: e.general.NOT_ALLOWED, info: 'packets over '+@messagesPerSecond+'/s dropped. Have a nice day.', payload: {error: 'TOOMANYPACKETSPERSECOND'}})
              else
                fn(m) # With a player object that matches the session cookies or whatnot in the message
          else
            console.log '** user '+m.user.name+' have no ratelimiter or at least not one with a removeToken function!!!'
            console.dir m.user
        )
      else
        console.log '--- could not find registered target for message! ---'

  incrementMetric: (metric, tags) =>
    if @datadogOptions
      DDAPI.writePoint(metric, tags, 'increment')
      #@dogstatsd.increment(metric, tags)

  gaugeMetric: (metric, val, tags) =>
    if @datadogOptions
      DDAPI.writePoint(metric, val, tags, 'gauge')
      #@dogstatsd.gauge(metric, val, tags)

  uniqueMetric: (metric, val, tags) =>
    if @datadogOptions
      DDAPI.writePoint(metric, val, tags, 'unique')

  setTag: (type, id, tag) =>
    q = defer()
    DB.getDataStore().then (store)=>
      Taginator.setTag(store, type, id, tag).then (value)=>
        q.resolve(value)
    return q

  getTagsFor: (type, id) =>
    q = defer()
    DB.getDataStore().then (store)=>
      Taginator.getTagsFor(store, type, id).then (value)=>
        q.resolve(value)
    return q

  searchForTags: (type, tags) =>
    q = defer()
    DB.getDataStore().then (store)=>
      Taginator.searchForTags(store, type, tags).then (value)=>
        q.resolve(value)
    return q


module.exports = MessageRouter



