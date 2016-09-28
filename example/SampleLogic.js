// Generated by CoffeeScript 1.10.0
(function() {
  var DB, HttpMethod, ResolveModule, SampleGame, SampleLogic, SamplePlayer, e;

  e = require('../lib/EventManager');

  SampleGame = require('./SampleGame');

  SamplePlayer = require('./SamplePlayer');

  DB = require('../lib/DB');

  HttpMethod = require('../lib/HttpMethod');

  ResolveModule = require('../lib/ResolveModule');

  SampleLogic = (function() {
    SampleLogic.gamecount = 0;

    function SampleLogic(messageRouter) {
      this.messageRouter = messageRouter;
      this.games = [];
      console.log('--------------------------------- SampleLogic contructor -------------------------------');
      this.messageRouter.objectManager.expose('SampleGame');
      this.messageRouter.objectManager.expose('SamplePlayer');
      ResolveModule.modulecache['SampleGame'] = SampleGame;
      ResolveModule.modulecache['SamplePlayer'] = SamplePlayer;
      DB.createDatabases(['SampleGame', 'SamplePlayer']).then((function(_this) {
        return function() {
          console.log(' SampleLogic DB init done..');
          setTimeout(function() {
            return _this.messageRouter.open();
          }, 20);
          return "DB.getOrCreateObjectByRecord({id:17, name: 'fooGame', type: 'SampleGame', createdBy: 'SYSTEM', createdAt: Date.now()}).then (game)=>\n  console.log 'got first game'\n  game.serialize()\n  @messageRouter.open()";
        };
      })(this));
    }

    return SampleLogic;

  })();

  module.exports = SampleLogic;

}).call(this);

//# sourceMappingURL=SampleLogic.js.map
