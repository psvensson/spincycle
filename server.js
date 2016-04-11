// Generated by CoffeeScript 1.10.0
(function() {
  var AuthenticationManager, SpinCycle, app, authMgr, cors, express, messageRouter, port, server;

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

  app.use(express["static"]("lib"));

  app.use(cors);

  app.options('*', cors());

  authMgr = new AuthenticationManager();

  messageRouter = new SpinCycle(authMgr, null, null, app, 'rethinkdb');

  new SpinCycle.HttpMethod(messageRouter, app, '/api/');

  new SpinCycle.WsMethod(messageRouter, server);

  messageRouter.open();

}).call(this);

//# sourceMappingURL=server.js.map
