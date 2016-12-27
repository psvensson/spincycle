// Generated by CoffeeScript 1.9.3
(function() {
  var AuthenticationManager, SpinCycle, app, authMgr, cors, ddoptions, express, messageRouter, port, server;

  SpinCycle = require('./lib/MessageRouter');

  AuthenticationManager = require('./example/AuthenticationManager');

  express = require("express");

  cors = require('cors');

  app = express();

  server = require("http").createServer(app);

  port = process.env.PORT || 3003;

  server.listen(port, function() {
    console.log("Server listening at port %d", port);
  });

  app.use(cors());

  app.options('*', cors());

  app.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    return next();
  });

  ddoptions = {
    api_key: "8a8c68a6193ac76c501f49b08e3a105f",
    app_key: "1b9c45f6638bd01d8ef4c474ec87e15487f644a2",
    api_host: 'app.datadoghq.com'
  };

  authMgr = new AuthenticationManager(app);

  messageRouter = new SpinCycle(authMgr, null, null, app, 'rethinkdb', ddoptions);

  new SpinCycle.HttpMethod(messageRouter, app, '/api/');

  new SpinCycle.WsMethod(messageRouter, server);

  messageRouter.open();

}).call(this);

//# sourceMappingURL=server.js.map
