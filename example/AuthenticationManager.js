// Generated by CoffeeScript 1.8.0
(function() {
  var AuthenticationManager, defer, uuid,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  defer = require('node-promise').defer;

  uuid = require('node-uuid');

  AuthenticationManager = (function() {
    function AuthenticationManager() {
      this.canUserCreateThisObject = __bind(this.canUserCreateThisObject, this);
      this.canUserWriteToThisObject = __bind(this.canUserWriteToThisObject, this);
      this.canUserReadFromThisObject = __bind(this.canUserReadFromThisObject, this);
      this.decorateMessageWithUser = __bind(this.decorateMessageWithUser, this);
      this.anonymousUsers = [];
      console.log('** new AuthMgr created **');
    }

    AuthenticationManager.prototype.decorateMessageWithUser = function(message) {
      var q, user;
      q = defer();
      user = this.anonymousUsers[message.client] || {
        id: uuid.v4()
      };
      message.user = user;
      q.resolve(message);
      this.anonymousUsers[message.client] = user;
      return q;
    };

    AuthenticationManager.prototype.canUserReadFromThisObject = function(obj, user) {
      return true;
    };

    AuthenticationManager.prototype.canUserWriteToThisObject = function(obj, user) {
      return true;
    };

    AuthenticationManager.prototype.canUserCreateThisObject = function(obj, user) {
      return true;
    };

    return AuthenticationManager;

  })();

  module.exports = AuthenticationManager;

}).call(this);

//# sourceMappingURL=AuthenticationManager.js.map
