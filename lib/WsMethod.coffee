IO              = require("socket.io")
uuid            = require('node-uuid')
ClientEndpoints = require('./ClientEndpoints')

class WsMethod

  @wsroutes = []

  constructor:(server, messageRouter)->
    io = IO(server)

    io.on "connection", (socket) ->
      ip    = socket.request.connection.remoteAddress
      port  = socket.request.connection.remotePort
      console.log 'new ws connection from '+ip+':'+port
      ClientEndpoints.registerEndpoint ip+':'+port, (msg) ->
        socket.emit('message', msg)

      # when the client emits 'message', this listens and executes
      socket.on "message", (datastring) ->
        console.log 'got new message "'+datastring+'"'
        data = JSON.parse(datastring) # TODO: Guard against hax0r dataz

        data.client    = ip+':'+port
        data.messageId = data.messageId || uuid.v4()
        data.replyFunc = (replydata) ->
          reply =
            messageId: data.messageId
            data: replydata

          socket.emit('message', reply)
        WsMethod.wsroutes[data.target]?(data)

      # when the user disconnects.. perform this
      socket.on "disconnect", ->
        adr = ip+':'+port
        console.log 'client at '+adr+' disconnected'
        ClientEndpoints.removeEndpoint(adr)

    messageRouter.addMethod 'ws', (targetName, targetFunc) ->
      #console.log 'ws registering route for target '+targetName
      WsMethod.wsroutes[targetName] = targetFunc

module.exports = WsMethod
