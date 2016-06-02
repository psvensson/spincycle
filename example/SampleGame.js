// Generated by CoffeeScript 1.8.0
(function() {
  var SampleGame, SamplePlayer, SuperModel, all, defer, uuid,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  SuperModel = require('../lib/SuperModel');

  defer = require('node-promise').defer;

  all = require('node-promise').allOrNone;

  uuid = require('node-uuid');

  SamplePlayer = require('./SamplePlayer');

  SampleGame = (function(_super) {
    __extends(SampleGame, _super);

    SampleGame.type = 'SampleGame';

    SampleGame.model = [
      {
        name: 'players',
        "public": true,
        array: true,
        type: 'SamplePlayer',
        ids: 'players'
      }, {
        name: 'name',
        "public": true,
        value: 'name',
        "default": 'game_' + uuid.v4()
      }
    ];

    function SampleGame(record) {
      this.record = record;
      this.createPlayers = __bind(this.createPlayers, this);
      this.postCreate = __bind(this.postCreate, this);
      return SampleGame.__super__.constructor.apply(this, arguments);
    }

    SampleGame.prototype.postCreate = function(q) {
      if (this.players.length === 0) {
        return this.createPlayers().then((function(_this) {
          return function() {
            console.log('SampelGame players created...');
            return q.resolve(_this);
          };
        })(this));
      } else {
        return q.resolve(this);
      }
    };

    SampleGame.prototype.createPlayers = function() {
      var q;
      console.log('creating sample players');
      q = defer();
      this.players = [];
      all([new SamplePlayer(), new SamplePlayer()]).then((function(_this) {
        return function(results) {
          console.log('sample players created');
          results.forEach(function(player) {
            _this.players[player.name] = player;
            player.serialize();
            return console.log('serializing player ' + player.name);
          });
          return q.resolve();
        };
      })(this));
      return q;
    };

    return SampleGame;

  })(SuperModel);

  module.exports = SampleGame;

}).call(this);

//# sourceMappingURL=SampleGame.js.map
