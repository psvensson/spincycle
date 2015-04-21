ObjectManager   = require('./ObjectManager')
error           = require('./Error').error
HttpMethod      = require('./HttpMethod');
WsMethod        = require('./WsMethod');
DB              = require('./DB')
EventManager    = require('./EventManager')
SuperModel      = require('./SuperModel')
ClientEndpoints = require('./ClientEndpoints')
OStore          = require('./OStore')
ResolveModule   = require('./ResolveModule')

# The MessageRouter registers names on which messages can be sent.
# The idea is to abstract away different messaging methods (WS, WebRTC, HTTP) from the logic

class MessageRouter

  @HttpMethod = HttpMethod
  @WsMethod = WsMethod
  @DB = DB
  @EventManager = EventManager
  @SuperModel = SuperModel
  @DB = DB
  @ObjectManager = ObjectManager
  @ClientEndpoints = ClientEndpoints
  @OStore = OStore
  @ResolveModule = ResolveModule
  @debug = no

  constructor: (@authMgr, debug) ->
    console.log 'messageRouter constructor'
    console.dir @authMgr
    MessageRouter.debug = debug

    @targets  = []
    @args     = []
    @methods  = []
    #@authMgr  = AuthenticationManager
    @objectManager = new ObjectManager(@)
    @objectManager.setup()

    @setup()

  setup: () =>
    @addTarget 'listcommands', '<noargs>', (msg) =>
      console.log 'listCommands called'
      rv = {listcommands: '<noarg>'}
      for name, target of @targets
        console.log 'adding target '+name
        rv[name] = @args[name]
      msg.replyFunc({status: EventManager.general.SUCCESS, info: 'list of available targets', payload: rv})

  # All messaging method adds their function for registering new paths or whatnot here
  # So for example for express you could add a method which makes sure the target name
  # can be reached by the url ../<targetName>
  addMethod: (methodName, registrationFunc) =>
    #console.log 'addMethod called for "'+methodName+'"'
    @methods[methodName] = registrationFunc
    for targetName of @targets
      #console.log 'registering target '+targetName+' on method '+methodName
      registrationFunc(targetName, @routeMessage)

  addTarget: (targetName, args, targetFunc) =>
    console.log 'adding route target for "'+targetName+'"'
    @targets[targetName] = targetFunc
    @args[targetName] = args
    for method, registrationFunc of @methods
      #console.log 'registering target '+targetName+' on method '+method
      registrationFunc(targetName, @routeMessage)

  removeTarget: (targetName) =>
    @targets[targetName] = null

  # Message format is {messageId: i, client: <ip:port>, messageTarget: t, replyFunction: r, messageBody: {b}}
  routeMessage: (message) =>
    fn = @targets[message.target]
    console.log 'routeMessage called for "'+message.target+'"'
    if fn
      @authMgr.decorateMessageWithUser(message).then( (m)->
        if not m.user
          console.log '** SpinCycle did not get message decorated with user property from AuthenticationManager **'
          exit( -1)
        fn(m) # With a player object that matches the session cookies or whatnot in the message
      )
    else
      console.log '--- could not find registered target for message! ---'

module.exports = MessageRouter



