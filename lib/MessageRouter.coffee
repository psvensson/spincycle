ObjectManager   = require('./ObjectManager')
error           = require('./Error').error
HttpMethod      = require('./HttpMethod');
WsMethod        = require('./WsMethod');
RedisMethod     = require('./RedisMethod')
DB              = require('./DB')
EventManager    = require('./EventManager')
SuperModel      = require('./SuperModel')
ClientEndpoints = require('./ClientEndpoints')
OStore          = require('./OStore')
ResolveModule   = require('./ResolveModule')
RateLimiter     = require('limiter').RateLimiter
e               = require('./EventManager')

# The MessageRouter registers names on which messages can be sent.
# The idea is to abstract away different messaging methods (WS, WebRTC, HTTP) from the logic

class MessageRouter

  @HttpMethod = HttpMethod
  @WsMethod = WsMethod
  @RedisMethod = RedisMethod
  @DB = DB
  @EventManager = EventManager
  @SuperModel = SuperModel
  @ObjectManager = ObjectManager
  @ClientEndpoints = ClientEndpoints
  @OStore = OStore
  @ResolveModule = ResolveModule

  debug = process.env["DEBUG"]

  constructor: (@authMgr, dburl, msgPS) ->
    MessageRouter.DB.dburl = dburl
    pjson = require('../package.json');
    console.log 'SpinCycle messageRouter constructor. Version - '+pjson.version
    #console.dir @authMgr
    @authMgr.messagerouter = @
    @resolver = new ResolveModule()
    @targets  = []
    @messagesPerSecond = msgPS or 10
    @debugtargets  = []
    @args     = []
    @methods  = []
    #@authMgr  = AuthenticationManager
    @objectManager = new ObjectManager(@)
    @objectManager.setup()
    if @authMgr.setup then @authMgr.setup(@)

    @setup()

  setup: () =>
    @addTarget 'listcommands', '<noargs>', (msg) =>
      console.log 'listCommands called'
      rv = {listcommands: '<noarg>'}
      for name, target of @targets
        console.log 'adding target '+name
        rv[name] = @args[name]
      msg.replyFunc({status: EventManager.general.SUCCESS, info: 'list of available targets', payload: rv})

  expose: (type) =>
    for name, method of @methods
      method.expose(type)


  # All messaging method adds their function for registering new paths or whatnot here
  # So for example for express you could add a method which makes sure the target name
  # can be reached by the url ../<targetName>
  addMethod: (methodName, method) =>
    console.log 'addMethod called for "'+methodName+'"'
    @methods[methodName] = method
    for targetName of @targets
      #console.log 'registering target '+targetName+' on method '+methodName
      method.registrationFunc(targetName, @routeMessage)

  addTarget: (targetName, args, targetFunc) =>
    #console.log 'adding route target for "'+targetName+'" args = '+args
    @targets[targetName] = targetFunc
    @args[targetName] = args
    for name,method of @methods
      #console.log 'registering target '+targetName+' on method '+name
      if method.registrationFunc
        method.registrationFunc(targetName, @routeMessage)
      else
        console.log 'Spincycle did NOT find target for '+targetName
        console.log '----------------methods-------------------'
        console.dir @methods

  removeTarget: (targetName) =>
    @targets[targetName] = null

  # Message format is {messageId: i, client: <ip:port>, messageTarget: t, replyFunction: r, messageBody: {b}}
  routeMessage: (message) =>
    fn = @targets[message.target]
    #if debug then console.log 'routeMessage called for "'+message.target+'"'
    #if debug then console.dir @targets
    if fn
      @authMgr.decorateMessageWithUser(message).then( (m)->
        if not m.user
          console.log '** SpinCycle did not get message decorated with user property from AuthenticationManager **'
          exit( -1)
        #console.log 'user found. now calling handler'
        if not m.limiter then m.limiter = new RateLimiter(@messagesPerSecond, 1000)
        limiter.removeTokens 1, (err, remainingRequests) =>
          if err
            m.replyFunc({status: e.general.NOT_ALLOWED, info: 'packets over '+@messagesPerSecond+' dropped. Have a nice day.', payload: {error: 'TOOMANYPACKETSPERSECOND'}})
          else
            fn(m) # With a player object that matches the session cookies or whatnot in the message
      )
    else
      console.log '--- could not find registered target for message! ---'

module.exports = MessageRouter



