// Generated by CoffeeScript 1.8.0
(function() {
  var PostgresqlPersistence, pg,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  pg = require('pg');

  PostgresqlPersistence = (function() {
    function PostgresqlPersistence() {
      this.remove = __bind(this.remove, this);
      this.set = __bind(this.set, this);
      this.get = __bind(this.get, this);
      this.all = __bind(this.all, this);
      this.getDbFor = __bind(this.getDbFor, this);
      this.connect = __bind(this.connect, this);
      this.dbs = [];
      this.done;
    }

    PostgresqlPersistence.prototype.connect = function() {
      var conString;
      conString = "postgres://peter:foobar@localhost/qp";
      return pg.connect(conString, (function(_this) {
        return function(err, client, done) {
          if (err) {
            console.log('PostgreSQL ERROR connecting: ' + err);
            return console.dir(err);
          } else {
            _this.deon = done;
            _this.client = client;
            return console.log('Created PostgreSQL successfully');
          }
        };
      })(this));
    };

    PostgresqlPersistence.prototype.getDbFor = function(_type) {
      var db, q, type;
      q = defer();
      type = _type.toLowerCase();
      db = this.dbs[type];
      if (!db) {
        this.client.query('SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_name = \'' + type + '\' )', (function(_this) {
          return function(err, result) {
            if (err) {
              throw err;
            } else {
              if (result.rows.length === 0) {

              } else {
                _this.dbs[type] = type;
                return q.resolve(type);
              }
            }
          };
        })(this));
      } else {
        q.resolve(type);
      }
      return q;
    };

    PostgresqlPersistence.prototype.all = function(_type, cb) {
      var rv, type;
      rv = [];
      type = _type.toLowerCase();
      return this.getDbFor(type).then((function(_this) {
        return function(db) {};
      })(this));
    };

    PostgresqlPersistence.prototype.get = function() {};

    PostgresqlPersistence.prototype.set = function() {};

    PostgresqlPersistence.prototype.remove = function() {};

    return PostgresqlPersistence;

  })();

  module.exports = PostgresqlPersistence;

}).call(this);

//# sourceMappingURL=PostgresqlPersistence.js.map