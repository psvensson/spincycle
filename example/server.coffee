SpinCycle       = require('../lib/MessageRouter')

AuthenticationManager = require('./AuthenticationManager')
SampleLogic = require('./SampleLogic')

express         = require("express")
bodyParser      = require("body-parser")
session = require('express-session')
cors            = require('cors')
app             = express()
server          = require("http").createServer(app)


app.use express.static("app")
app.use(cors)

app.use(session({ secret: 'shhhhhhhhh' }));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

#--------------------------------------------------> Set up Message Router
authMgr         = new AuthenticationManager()
messageRouter   = new SpinCycle(authMgr, null, 1000, app)
#--------------------------------------------------> Express Routing
new SpinCycle.HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new SpinCycle.WsMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
# Adding sample logic
logic = new SampleLogic(messageRouter)
port = process.env.PORT or 6601
setTimeout(
  ()->
    server.listen port, ->
      console.log "Server listening at port %d", port
    return
  ,1000
)


