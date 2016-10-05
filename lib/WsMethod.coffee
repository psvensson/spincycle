IO              = require("socket.io")
uuid            = require('node-uuid')
ClientEndpoints = require('./ClientEndpoints')

debug = process.env["DEBUG"]

class WsMethod

  @wsroutes = []

  constructor:(@messageRouter, server)->
    io = IO(server)
    io.set( 'origins', '*:*' )

    io.on "connection", (socket) ->
      ip    = socket.handshake.address
      port  = socket.request.connection.remotePort
      adr = ip+':'+port 
      console.log 'new ws connection from '+adr
      ClientEndpoints.registerEndpoint adr, (msg) ->
        socket.emit('message', msg)

      # when the client emits 'message', this listens and executes
      socket.on "message", (datastring) ->
        console.log 'got new message "'+datastring+'" ['+(typeof datastring)+']'
        if typeof datastring == "string"
          data = JSON.parse(datastring)
        else
          #console.dir datastring
          data = datastring # TODO: Guard against hax0r dataz

        data.client    = ip+':'+port
        data.messageId = data.messageId || uuid.v4()
        data.replyFunc = (replydata) ->
          replydata.messageId = data.messageId
          #if debug then console.log 'replyFunc replying with'
          #if debug then console.dir replydata
          socket.emit('message', replydata)

        fn = WsMethod.wsroutes[data.target]
        if fn then fn(data) else console.log '*********** Could not find registered target for '+data.target

      # when the user disconnects.. perform this
      socket.on "disconnect", ->
        adr = ip+':'+port
        console.log 'client at '+adr+' disconnected'
        ClientEndpoints.removeEndpoint(adr)

    @messageRouter.addMethod 'ws', @

  registrationFunc: (targetName, targetFunc) ->
    #console.log 'ws registering route for target '+targetName
    WsMethod.wsroutes[targetName] = targetFunc



module.exports = WsMethod
