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
ddoptions = {
  api_key: "8a8c68a6193ac76c501f49b08e3a105f",
  app_key: "1b9c45f6638bd01d8ef4c474ec87e15487f644a2",
  #api_version: 'v1.5',
  api_host: 'app.datadoghq.com'
}


#--------------------------------------------------> Set up Message Router
authMgr         = new AuthenticationManager()
messageRouter   = new SpinCycle(authMgr, null, null, app, 'rethinkdb', ddoptions)
#--------------------------------------------------> Express Routing
new SpinCycle.HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new SpinCycle.WsMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
messageRouter.open()

