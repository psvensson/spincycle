AuthenticationManager = require('./AuthenticationManager')

express         = require("express")
app             = express()
server          = require("http").createServer(app)

HttpMethod      = require('./server/SpinCycle/HttpMethod')
WsMethod        = require('./server/SpinCycle/WsMethod')

port = process.env.PORT or 3000
server.listen port, ->
  console.log "Server listening at port %d", port
  return

app.use express.static("app")
#--------------------------------------------------> Set up Message Router
authMgr = new AuthenticationManager()
messageRouter   = new MessageRouter(authMgr)
#--------------------------------------------------> Express Routing
new HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new WsMethod(server, messageRouter)
#<-------------------------------------------------- WS Routing