uuid            = require('node-uuid')
url             = require('url')
basicAuth       = require('basic-auth')

debug = process.env["DEBUG"]

class HttpMethod

  @httproutes = []
  @props = {}

  constructor: (messageRouter, app, basePath) ->
    #console.log 'HttpMethod called for path '+basePath

    doSend = (req, res, url_parts)->
      user  = basicAuth(req)
      if user
        console.log 'basic auth user detected'
        console.dir user
        if HttpMethod.props and HttpMethod.props.user and HttpMethod.props.user.name
          if HttpMethod.props.user.name isnt user.name and HttpMethod.props.user.pass isnt user.pass
            console.log 'wrong username or password provided'
            res.json({status: e.general.NOT_ALLOWED, info: 'wrong basic auth username or pass.', payload: {error: 'Basic Auth Failure'}})
            return
      ip    = req.connection.remoteAddress
      port  = req.connection.remotePort
      #console.log 'express request from '+ip+':'+port+' target is "'+req.query.target+'"'
      #console.dir req.query
      target = HttpMethod.httproutes[req.query.target]
      if target
        message = { client: ip+':'+port, target: req.query.target, messageId: url_parts.messageId || uuid.v4() }
        for p, part of req.query
          message[p] = part # TODO: Guard against hax0r dataz
        #console.log 'message is now'
        #console.dir message
        message.replyFunc = (reply) ->
          res.json(reply)
          if debug then console.log 'HttpMethod calling target '+target
        target(message)

    app.get basePath, (req, res) ->
      url_parts = url.parse(req.url, true)
      doSend(req, res, url_parts)

    app.post basePath, (req, res) ->
      url_parts = req.body
      doSend(req, res, url_parts)

    messageRouter.addMethod 'express', @


  registrationFunc: (targetName, targetFunc, @props) ->
    #console.log 'express registering http route for target '+targetName
    HttpMethod.httproutes[targetName] = targetFunc



module.exports = HttpMethod
