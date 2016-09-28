SpinCycle       = require('../lib/MessageRouter')

AuthenticationManager = require('./AuthenticationManager')
SampleLogic = require('./SampleLogic')
serveStatic     = require('serve-static')
express         = require("express")
bodyParser      = require("body-parser")
session = require('express-session')
cors            = require('cors')
app             = express()
server          = require("http").createServer(app)

_log = console.log
console.log = (msg)->
  ts = new Date()+""
  _log ts+' - '+msg

port = process.env.PORT or 6602

#app.use express.static("app")
app.use(cors)

app.use(session({ secret: 'shhhhhhhhh' }));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

"""
setTimeout(
  ()=>
    app.use(serveStatic(__dirname + '/app'))
  ,2000
)
"""

app.use(cors())

server.listen port, ->
  console.log "---*** Server listening at port %d",port

#--------------------------------------------------> Set up Message Router
authMgr         = new AuthenticationManager(app)
messageRouter   = new SpinCycle(authMgr, null, 1000, app, 'mongodb')
#--------------------------------------------------> Express Routing
new SpinCycle.HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new SpinCycle.WsMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
# Adding sample logic
logic = new SampleLogic(messageRouter)



