uuid            = require('node-uuid')
url             = require('url')
basicAuth       = require('basic-auth')
cookie         = require('cookie')
bodyParser = require('body-parser')

debug = process.env["DEBUG"]

class HttpMethod

  @httproutes = []
  @props = {}

  constructor: (messageRouter, app, basePath) ->
    #console.log 'HttpMethod called for path '+basePath'
    @app = app
    app.use(bodyParser.json())
    @restPath = '/rest/'

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
      cookies = cookie.parse(req.headers.cookie or '')

      #console.dir req.query
      target = HttpMethod.httproutes[req.query.target]
      if target
        console.log 'Express request from '+ip+':'+port+' target is "'+req.query.target+'" cookies are '+req.headers.cookie
        message = { client: ip+':'+port, target: req.query.target, messageId: url_parts.messageId || uuid.v4(), sessionId: cookies.sid }
        for p, part of url_parts
          message[p] = part # TODO: Guard against hax0r dataz
        #console.log 'message is now'
        #console.dir message
        message.replyFunc = (reply) ->
          if reply.statuscode then res.status(reply.statuscode)
          res.json(reply)
          if debug then console.log 'HttpMethod calling target '+target
        target(message)
      else
        res.json({error:'target not found'})
    @doSend = doSend

    app.get basePath, (req, res) ->
      url_parts = req.query
      doSend(req, res, url_parts)

    app.post basePath, (req, res) ->
      url_parts = req.body
      doSend(req, res, url_parts)

    """
    app.put basePath, (req, res) ->
      if debug then console.log 'Alternate PUT handler. params are'
      if debug then console.dir req.params
      if debug then console.log 'query is'
      if debug then console.dir req.query
      url_parts = req.body
      doSend(req, res, url_parts)
    """
    messageRouter.addMethod 'express', @


  registrationFunc: (targetName, targetFunc, @props) ->
    #console.log 'express registering http route for target '+targetName
    HttpMethod.httproutes[targetName] = targetFunc

  makeRESTful: (type) =>
    #console.log 'HttpMethod.makeRESTful called for type '+type+' restpath is '+@restPath

    listall = (req,res) =>
      #console.log 'listall'
      url_parts = req.query
      req.query.type = type
      req.query.target = '_list'+type+'s'
      @doSend(req, res, url_parts)

    createone = (req,res) =>
      #console.log 'createone'
      url_parts = req.query
      req.query.type = type
      req.query.obj = {type: req.query.type}
      req.query.target = '_create'+type
      @doSend(req, res, url_parts)

    getone = (req,res) =>
      #console.log 'getone'
      url_parts = req.query
      req.query.id = req.params.id
      req.query.type = type
      req.query.target = '_get'+type
      @doSend(req, res, url_parts)

    updateone = (req,res) =>
      #console.log 'updateone'
      if debug then console.log 'PUT handler. params are'
      if debug then console.dir req.params
      if debug then console.log 'query is'
      if debug then console.dir req.query
      if debug then console.log 'body is'
      if debug then console.dir req.body
      #console.dir req
      url_parts = req.body
      #console.dir url_parts
      req.query.id = req.params.id
      url_parts.apitoken = req.query.apitoken
      url_parts.sessionId = req.query.sessionId
      req.query.type = type
      req.query.obj = req.body.obj
      if typeof url_parts.obj == 'string' then url_parts.obj = JSON.parse(url_parts.obj)
      req.query.target = '_update'+type
      @doSend(req, res, url_parts)

    deleteone = (req,res) =>
      #console.log 'deleteone'
      url_parts = req.query
      req.query.id = req.params.id
      req.query.type = type
      req.query.obj = {id: req.query.id, type: req.query.type}
      req.query.target = '_delete'+type
      @doSend(req, res, url_parts)

    console.log 'adding REST paths for "'+(@restPath+type)+'"'
    @app.route(@restPath+type).get(listall).post(createone)
    @app.route(@restPath+type+'/:id').get(getone)
    @app.route(@restPath+type+'/:id').put(updateone)
    @app.route(@restPath+type+'/:id').delete(deleteone)

    @app.get('/foo', (req,res,next)->
      console.log 'foo'
      ,(req,res,next)->
        console.log 'reject foo'
    )

module.exports = HttpMethod
