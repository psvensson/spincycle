uuid            = require('node-uuid')
redis           = require('redis')

class RedisMethod



  constructor: (messageRouter, app, basePath) ->
    @redisroutes = []
    @listenclient = redis.createClient()

    @listenclient.subscribe('spinchannel')
    @listenclient.on('message', @onChannelMessage)
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
