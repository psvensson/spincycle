SpinCycle       = require('../lib/MessageRouter')

AuthenticationManager = require('./AuthenticationManager')
SampleLogic = require('./SampleLogic')

express         = require("express")
app             = express()
server          = require("http").createServer(app)

HttpMethod      = require('../lib/HttpMethod')
WsMethod        = require('../lib/WsMethod')

port = process.env.PORT or 3003
server.listen port, ->
  console.log "Server listening at port %d", port
  return

app.use express.static("app")
#--------------------------------------------------> Set up Message Router
authMgr = new AuthenticationManager()
messageRouter   = new SpinCycle(authMgr)
#--------------------------------------------------> Express Routing
new HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new WsMethod(server, messageRouter)
#<-------------------------------------------------- WS Routing
# Adding sample logic
logic = new SampleLogic(messageRouter)
