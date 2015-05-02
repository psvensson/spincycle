IO              = require("socket.io")
uuid            = require('node-uuid')
ClientEndpoints = require('./ClientEndpoints')

class WsMethod

  @wsroutes = []

  constructor:(@messageRouter, server)->
    io = IO(server)
    io.set( 'origins', '*:*' )

    io.on "connection", (socket) ->
      ip    = socket.request.connection.remoteAddress
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
          socket.emit('message', replydata)

        fn = WsMethod.wsroutes[data.target]
        fn?(data)

      # when the user disconnects.. perform this
      socket.on "disconnect", ->
        adr = ip+':'+port
        console.log 'client at '+adr+' disconnected'
        ClientEndpoints.removeEndpoint(adr)

    @messageRouter.addMethod 'ws', @

  registrationFunc: (targetName, targetFunc) ->
    #console.log 'ws registering route for target '+targetName
    WsMethod.wsroutes[targetName] = targetFunc

  expose: (type) =>
    @messageRouter.addTarget '_create'+type, 'obj', (msg) =>
      msg.type = type
      @messageRouter.objectManager._createObject(msg)
    # TODO: delete object hierarchy as well? Maybe also check for other objects referencing this, disallowing if so
    @messageRouter.addTarget '_delete'+type, 'obj', (msg) =>
      msg.type = type
      @messageRouter.objectManager._deleteObject(msg)
    @messageRouter.addTarget '_update'+type, 'obj', (msg) =>
      msg.type = type
      @messageRouter.objectManager._updateObject(msg)
    @messageRouter.addTarget '_get'+type, 'obj', (msg) =>
      msg.type = type
      @messageRouter.objectManager._getObject(msg)
    @messageRouter.addTarget '_list'+type+'s', '<noargs>', (msg) =>
      msg.type = type
      #console.log 'calling _listObjects from WsMethod with type '+type
      @messageRouter.objectManager._listObjects(msg)

module.exports = WsMethod
