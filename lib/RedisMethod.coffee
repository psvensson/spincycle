uuid            = require('node-uuid')
redis           = require('redis')

class RedisMethod

  @redisroutes = []
  @client = redis.createClient()

  constructor: (messageRouter, app, basePath) ->
    @client.subscribe('spinchannel')
    @client.on('message', RedisMethod.onChannelMessage)
    messageRouter.addMethod 'redis', @

  onChannelMessage: (channel, message) ->
    console.log 'redismethod got channel '+channel+' message '+message
    console.dir channel
    console.lo '-------------------------------------------------------------------'
    console.dir messages


  registrationFunc: (targetName, targetFunc) ->
    #console.log 'express registering redis route for target '+targetName
    RedisMethod.redisroutes[targetName] = targetFunc

  expose: (type) =>
    console.log 'RedisMethod::Expose called for type '+type+' (unimplemented)'

module.exports = RedisMethod
