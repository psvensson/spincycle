SpinCycle       = require('./lib/MessageRouter')

AuthenticationManager = require('./example/AuthenticationManager')

express         = require("express")
cors            = require('cors')
app             = express()
server          = require("http").createServer(app)

port = process.env.PORT or 3003 
server.listen port, ->
  console.log "Server listening at port %d", port
  return

#app.use express.static("lib")
app.use(cors())
app.options('*', cors())

#--------------------------------------------------> Set up Message Router
authMgr         = new AuthenticationManager()
messageRouter   = new SpinCycle(authMgr, null, null, app, 'rethinkdb')
#--------------------------------------------------> Express Routing
new SpinCycle.HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new SpinCycle.WsMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
messageRouter.open()

