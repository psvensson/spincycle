// Generated by CoffeeScript 1.8.0
(function() {
  var HttpMethod, debug, url, uuid;

  uuid = require('node-uuid');

  url = require('url');

  debug = process.env["DEBUG"];

  HttpMethod = (function() {
    HttpMethod.httproutes = [];

    function HttpMethod(messageRouter, app, basePath) {
      app.use(basePath + ':target', function(req, res) {
        var ip, message, p, part, port, target, url_parts;
        ip = req.connection.remoteAddress;
        port = req.connection.remotePort;
        target = HttpMethod.httproutes[req.params.target];
        if (target) {
          url_parts = url.parse(req.url, true);
          message = {
            client: ip + ':' + port,
            target: req.params.target,
            messageId: url_parts.messageId || uuid.v4()
          };
          for (p in url_parts) {
            part = url_parts[p];
            message[p] = part;
          }
          message.replyFunc = function(reply) {
            res.json(reply);
            if (debug) {
              return console.log('HttpMethod calling target ' + target);
            }
          };
          return target(message);
        }
      });
      messageRouter.addMethod('express', this);
    }

    HttpMethod.prototype.registrationFunc = function(targetName, targetFunc) {
      return HttpMethod.httproutes[targetName] = targetFunc;
    };

    return HttpMethod;

  })();

  module.exports = HttpMethod;

}).call(this);

//# sourceMappingURL=HttpMethod.js.map