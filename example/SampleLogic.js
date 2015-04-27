// Generated by CoffeeScript 1.9.1
(function() {
  var DB, Game, SampleLogic, e,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  e = require('../lib/EventManager');

  Game = require('./SampleGame');

  DB = require('../lib/DB');

  SampleLogic = (function() {
    SampleLogic.gamecount = 0;

    function SampleLogic(messageRouter) {
      this.messageRouter = messageRouter;
      this.onListGamePlayers = bind(this.onListGamePlayers, this);
      this.onListPlayerGames = bind(this.onListPlayerGames, this);
      this.onNewGame = bind(this.onNewGame, this);
      this.games = [];
      DB.createDatabases(['samplegame', 'sampleplayer']).then((function(_this) {
        return function() {
          return console.log(' DB init done..');
        };
      })(this));
      DB.all('SampleGame', (function(_this) {
        return function(games) {
          console.log(' setting all games to ' + games);
          console.dir(games);
          games.forEach(function(gamerecord) {
            return new Game(gamerecord).then(function(game) {
              game.serialize();
              console.log('--- adding game ' + game.name);
              return _this.games.push(game);
            });
          });
          return console.log('added ' + _this.games.length + ' games from storage');
        };
      })(this));
      this.messageRouter.addTarget('listGames', '<noargs>', this.onListPlayerGames);
      this.messageRouter.addTarget('listGamePlayers', 'gameId', this.onListGamePlayers);
      this.messageRouter.addTarget('newGame', '<noargs>', this.onNewGame);
      this.messageRouter.objectManager.expose('SampleGame');
      this.messageRouter.objectManager.expose('SamplePlayer');
    }

    SampleLogic.prototype.onNewGame = function(msg) {
      console.log('SampleLogic: New Game called');
      return new Game({
        name: 'New Game ' + (SampleLogic.gamecount++)
      }, true).then((function(_this) {
        return function(game) {
          console.log('SampleLogic: -- new game ' + game.name + ' created --');
          game.serialize();
          _this.games.push(game);
          return msg.replyFunc({
            status: e.general.SUCCESS,
            info: 'game "' + game.name + '" created'
          });
        };
      })(this));
    };

    SampleLogic.prototype.onListPlayerGames = function(msg) {
      var rv;
      console.log("got " + this.games.length + " games");
      rv = [];
      console.log('onListPlayerGames for player ' + msg.user.id);
      console.dir(this.games);
      this.games.forEach(function(game) {
        console.log('onListPlayerGames listing game "' + game.name + '"');
        return rv.push(game.id);
      });
      return msg.replyFunc({
        status: e.general.SUCCESS,
        info: '',
        payload: rv
      });
    };

    SampleLogic.prototype.onListGamePlayers = function(msg) {
      var game, rv;
      game = null;
      this.games.forEach((function(_this) {
        return function(lgame) {
          if (lgame.id === msg.gameById) {
            return game = lgame;
          }
        };
      })(this));
      if (game) {
        rv = [];
        game.players.forEach(function(player) {
          return rv.push(player.toClient());
        });
        return msg.replyFunc({
          status: e.general.SUCCESS,
          info: '',
          payload: rv
        });
      } else {
        return msg.replyFunc({
          status: e.general.FAILURE,
          info: 'no game found with that id',
          payload: ''
        });
      }
    };

    return SampleLogic;

  })();

  module.exports = SampleLogic;

}).call(this);

//# sourceMappingURL=SampleLogic.js.map
