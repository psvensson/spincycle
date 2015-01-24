// Generated by CoffeeScript 1.8.0
(function() {
  var AuthenticationManager, HttpMethod, SampleLogic, SpinCycle, WsMethod, app, authMgr, express, logic, messageRouter, port, server;

  SpinCycle = require('../lib/MessageRouter');

  AuthenticationManager = require('./AuthenticationManager');

  SampleLogic = require('./SampleLogic');

  express = require("express");

  app = express();

  server = require("http").createServer(app);

  HttpMethod = require('../lib/HttpMethod');

  WsMethod = require('../lib/WsMethod');

  port = process.env.PORT || 3003;

  server.listen(port, function() {
    console.log("Server listening at port %d", port);
  });

  app.use(express["static"]("app"));

  authMgr = new AuthenticationManager();

  messageRouter = new SpinCycle(authMgr);

  new HttpMethod(messageRouter, app, '/api/');

  new WsMethod(server, messageRouter);

  logic = new SampleLogic(messageRouter);

}).call(this);

//# sourceMappingURL=server.js.map
