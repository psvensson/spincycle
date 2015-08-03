uuid            = require('node-uuid')
redis           = require('redis')
ClientEndpoints = require('./ClientEndpoints')

class RedisMethod

  constructor: (messageRouter, app, basePath) ->
    @redisroutes = []

    rhost = process.env['REDIS_PORT_6379_TCP_ADDR'] or '127.0.0.1'
    rport = process.env['REDIS_PORT_6379_TCP_PORT'] or '6379'

    @listenclient = redis.createClient(rport, rhost)
    @sendclient = redis.createClient(rport, rhost)

    @listenclient.subscribe('spinchannel')
    @listenclient.on('message', @onChannelMessage)
    messageRouter.addMethod 'redis', @

  onChannelMessage: (channel, message) =>
    #console.log 'redismethod got channel '+channel+' message '+message
    #console.dir channel
    #console.log '-------------------------------------------------------------------'
    msg = JSON.parse(message)
    console.dir msg
    clientChannel = msg.channelID
    if clientChannel then ClientEndpoints.registerEndpoint msg.channelID, (msg) ->
      @sendclient.publish(clientChannel, JSON.stringify(msg))
    #
    # TODO:
    #
    # Since redis pubsub is stateless, we must remember to cull client backchannels from ClientEndpoints now and then !!!!
    #
    #
    target = @redisroutes[msg.target]
    if target
      msg.client    = msg.channelId
      msg.messageId = msg.messageId || uuid.v4()
      msg.replyFunc = (replydata) =>
        replydata.messageId = msg.messageId
        @sendclient.publish(clientChannel, JSON.stringify(replydata))
    else
      console.log 'RedisMethod: could not find target "'+msg.target+'" sending failure back to channel "'+clientChannel+'"'
      @sendclient.publish(clientChannel, JSON.stringify({messageId : msg.messageId , status: 'FAILURE', info: 'could not find target "'+msg.target+'"', payload: null }))


  registrationFunc: (targetName, targetFunc) =>
    #console.log 'express registering redis route for target '+targetName
    @redisroutes[targetName] = targetFunc


module.exports = RedisMethod
