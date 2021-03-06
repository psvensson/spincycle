// Generated by CoffeeScript 1.9.3
(function() {
  var ClientEndpoints, RedisMethod, debug, redis, uuid,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  uuid = require('node-uuid');

  redis = require('redis');

  ClientEndpoints = require('./ClientEndpoints');

  debug = process.env["DEBUG"];

  RedisMethod = (function() {
    function RedisMethod(messageRouter, app, dbUrl, addr) {
      this.registrationFunc = bind(this.registrationFunc, this);
      this.onChannelMessage = bind(this.onChannelMessage, this);
      var chid, rhost, rport;
      this.redisroutes = [];
      if (debug) {
        console.log('RediMethod dbUrl = ' + dbUrl);
      }
      rhost = dbUrl || process.env['REDIS_PORT_6379_TCP_ADDR'] || '127.0.0.1';
      rport = process.env['REDIS_PORT_6379_TCP_PORT'] || '6379';
      if (debug) {
        console.log('RedisMethod rhost = ' + rhost + ', rport = ' + rport);
      }
      this.listenclient = redis.createClient(rport, rhost);
      this.sendclient = redis.createClient(rport, rhost);
      chid = 'spinchannel';
      if (addr) {
        chid = chid + '_' + addr;
      }
      this.listenclient.subscribe(chid);
      this.listenclient.on('message', this.onChannelMessage);
      messageRouter.addMethod('redis', this);
    }

    RedisMethod.prototype.onChannelMessage = function(channel, message) {
      var clientChannel, msg, target;
      if (debug) {
        console.log('redismethod got channel ' + channel + ' message ' + message);
      }
      msg = JSON.parse(message);
      clientChannel = msg.channelID;
      msg.client = msg.channelID;
      if (clientChannel) {
        ClientEndpoints.registerEndpoint(msg.channelID, (function(_this) {
          return function(sendmsg) {
            if (debug) {
              console.log('******************* sending backchannel message through redis channel .' + clientChannel);
            }
            if (debug) {
              console.dir(sendmsg);
            }
            return _this.sendclient.publish(clientChannel, JSON.stringify(sendmsg));
          };
        })(this));
      }
      target = this.redisroutes[msg.target];
      if (target) {
        msg.messageId = msg.messageId || uuid.v4();
        msg.replyFunc = (function(_this) {
          return function(_replydata) {
            var replydata;
            if (!_replydata.payload) {
              if (debug) {
                console.log('message lacked payload, so creating proper message object with payload around it..');
              }
              replydata = {
                status: 'SUCCESS',
                info: 'reply',
                payload: _replydata
              };
            } else {
              replydata = _replydata;
            }
            console.log('redismethod replying to target ' + msg.target + ' message ' + msg.messageId + ' on channel ' + clientChannel);
            if (debug) {
              console.log('---------------------replydata is-------------------------');
            }
            if (debug) {
              console.dir(replydata);
            }
            replydata.messageId = msg.messageId;
            return _this.sendclient.publish(clientChannel, JSON.stringify(replydata));
          };
        })(this);
        return target(msg);
      } else {
        console.log('RedisMethod: could not find target "' + msg.target + '" sending failure back to channel "' + clientChannel + '"');
        return this.sendclient.publish(clientChannel, JSON.stringify({
          messageId: msg.messageId,
          status: 'FAILURE',
          info: 'could not find target "' + msg.target + '"',
          payload: null
        }));
      }
    };

    RedisMethod.prototype.registrationFunc = function(targetName, targetFunc) {
      return this.redisroutes[targetName] = targetFunc;
    };

    return RedisMethod;

  })();

  module.exports = RedisMethod;

}).call(this);

//# sourceMappingURL=RedisMethod.js.map
