SpinCycle       = require('../lib/MessageRouter')

AuthenticationManager = require('./AuthenticationManager')
SampleLogic = require('./SampleLogic')

express         = require("express")
cors            = require('cors')
app             = express()
server          = require("http").createServer(app)

port = process.env.PORT or 3003
server.listen port, ->
  console.log "Server listening at port %d", port
  return

app.use express.static("app")
app.use(cors)
app.options('*', cors())

#--------------------------------------------------> Set up Message Router
authMgr         = new AuthenticationManager()
messageRouter   = new SpinCycle(authMgr, null, 10, app, 'mongodb')
#--------------------------------------------------> Express Routing
new SpinCycle.HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new SpinCycle.WsMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
#--------------------------------------------------> WS Routing
new SpinCycle.RedisMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
# Adding sample logic
logic = new SampleLogic(messageRouter)
