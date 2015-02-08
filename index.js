var MessageRouter = require('lib/MessageRouter');
HttpMethod      = require('../lib/HttpMethod');
WsMethod        = require('../lib/WsMethod');

MessageRouter.HttpMethod = HttpMethod;
MessageRouter.WsMethod = WsMethod;

modules.exports = MessageRouter;