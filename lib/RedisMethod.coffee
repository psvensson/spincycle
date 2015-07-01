uuid            = require('node-uuid')
redis           = require('redis')

class RedisMethod



  constructor: (messageRouter, app, basePath) ->
    @redisroutes = []
    @listenclient = redis.createClient()
    @sendclient = redis.createClient()

    @listenclient.subscribe('spinchannel')
    @listenclient.on('message', @onChannelMessage)
    messageRouter.addMethod 'redis', @

  onChannelMessage: (channel, message) ->
    console.log 'redismethod got channel '+channel+' message '+message
    console.dir channel
    console.log '-------------------------------------------------------------------'
    msg = JSON.parse(message)
    console.dir msg
    clientChannel = msg.channelId
    #
    # TODO:
    #
    # Since redis pubsub is stateless, we must remember the client backchannels for some time but cull them after a time limit, in ClientEndpoints
    #
    #
    target = @redisroutes[msg.target]
    if target
      msg.client    = ip+':'+port
      msg.messageId = data.messageId || uuid.v4()
      msg.replyFunc = (replydata) ->
        replydata.messageId = data.messageId
        @sendclient.publisht(clientChannel, replydata)


  registrationFunc: (targetName, targetFunc) ->
    #console.log 'express registering redis route for target '+targetName
    @redisroutes[targetName] = targetFunc

  expose: (type) =>
    console.log 'RedisMethod::Expose called for type '+type+' (unimplemented)'

module.exports = RedisMethod
