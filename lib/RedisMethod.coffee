uuid            = require('node-uuid')
redis           = require('redis')
ClientEndpoints = require('./ClientEndpoints')

debug = process.env["DEBUG"]

class RedisMethod

  constructor: (messageRouter, app, dbUrl) ->
    @redisroutes = []

    if debug then console.log 'RediMethod dbUrl = '+dbUrl
    rhost = dbUrl or process.env['REDIS_PORT_6379_TCP_ADDR'] or '127.0.0.1'
    rport = process.env['REDIS_PORT_6379_TCP_PORT'] or '6379'
    if debug then console.log 'RedisMethod rhost = '+rhost+', rport = '+rport

    @listenclient = redis.createClient(rport, rhost)
    @sendclient = redis.createClient(rport, rhost)

    @listenclient.subscribe('spinchannel')
    @listenclient.on('message', @onChannelMessage)
    messageRouter.addMethod 'redis', @


  onChannelMessage: (channel, message) =>
    if debug then console.log 'redismethod got channel '+channel+' message '+message
    #console.dir channel
    #console.log '-------------------------------------------------------------------'
    msg = JSON.parse(message)
    #console.dir msg
    clientChannel = msg.channelID
    msg.client    = msg.channelID
    if clientChannel then ClientEndpoints.registerEndpoint msg.channelID, (sendmsg) =>
      #console.log '******************* sending backchannel message through redis channel .'+clientChannel
      #console.dir sendmsg
      @sendclient.publish(clientChannel, JSON.stringify(sendmsg))
    #
    # TODO:
    #
    # Since redis pubsub is stateless, we must remember to cull client backchannels from ClientEndpoints now and then !!!!
    #
    #
    target = @redisroutes[msg.target]
    if target
      msg.messageId = msg.messageId || uuid.v4()
      msg.replyFunc = (_replydata) =>
        if not _replydata.payload
          if debug then console.log 'message lacked payload, so creating proper message object with payload around it..'
          replydata = {status: 'SUCCESS', info: 'reply', payload: _replydata}
        else
          replydata = _replydata
        console.log 'redismethod replying to target '+msg.target+' message '+msg.messageId+' on channel '+clientChannel
        #console.dir message
        #console.log '---------------------replydata is-------------------------'
        #console.dir replydata
        replydata.messageId = msg.messageId
        @sendclient.publish(clientChannel, JSON.stringify(replydata))
      target(msg)
    else
      console.log 'RedisMethod: could not find target "'+msg.target+'" sending failure back to channel "'+clientChannel+'"'
      @sendclient.publish(clientChannel, JSON.stringify({messageId : msg.messageId , status: 'FAILURE', info: 'could not find target "'+msg.target+'"', payload: null }))


  registrationFunc: (targetName, targetFunc) =>
    #console.log 'express registering redis route for target '+targetName
    @redisroutes[targetName] = targetFunc


module.exports = RedisMethod
