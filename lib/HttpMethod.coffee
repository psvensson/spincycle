uuid            = require('node-uuid')
url             = require('url')

debug = process.env["DEBUG"]

class HttpMethod

  @httproutes = []

  constructor: (messageRouter, app, basePath) ->
    #console.log 'HttpMethod called for path '+basePath
    app.get basePath, (req, res) ->
      ip    = req.connection.remoteAddress
      port  = req.connection.remotePort
      #console.log 'express request from '+ip+':'+port+' target is "'+req.query.target+'"'
      #console.dir req.query
      target = HttpMethod.httproutes[req.query.target]
      if target
        url_parts = url.parse(req.url, true)
        message = { client: ip+':'+port, target: req.query.target, messageId: url_parts.messageId || uuid.v4() }
        for p, part of req.query
          message[p] = part # TODO: Guard against hax0r dataz
        #console.log 'message is now'
        #console.dir message
        message.replyFunc = (reply) ->
          res.json(reply)
          if debug then console.log 'HttpMethod calling target '+target
        target(message)

    messageRouter.addMethod 'express', @


  registrationFunc: (targetName, targetFunc) ->
    #console.log 'express registering http route for target '+targetName
    HttpMethod.httproutes[targetName] = targetFunc



module.exports = HttpMethod
