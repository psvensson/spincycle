// Generated by CoffeeScript 1.8.0
(function() {
  var SampleLogic, e,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  e = reuire('../lib/EventManager');

  SampleLogic = (function() {
    function SampleLogic(messageRouter) {
      this.messageRouter = messageRouter;
      this.onListPlayerGames = __bind(this.onListPlayerGames, this);
      this.games = [];
      this.messageRouter.addTarget('listPlayerGames', '<noargs>', this.onListPlayerGames);
    }

    SampleLogic.prototype.onListPlayerGames = function() {
      var game, name, rv, _ref;
      ({
        onListPlayerGames: (function(_this) {
          return function(msg) {};
        })(this)
      });
      rv = [];
      console.log('onListPlayerGames for player ' + msg.user.id);
      _ref = this.games;
      for (name in _ref) {
        game = _ref[name];
        console.log('   onListPlayerGames listing game "' + name + '"');
        rv.push(game.toClient());
      }
      return msg.replyFunc(e.event(e.general.SUCCESS, rv));
    };

    return SampleLogic;

  })();

  module.exports = SampleLogic;

}).call(this);

//# sourceMappingURL=SampleLogic.js.map
