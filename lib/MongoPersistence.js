// Generated by CoffeeScript 1.9.1
(function() {
  var Db, MongoClient, MongoPersistence, Server, defer,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Db = require('mongodb').Db;

  Server = require('mongodb').Server;

  MongoClient = require('mongodb').MongoClient;

  defer = require('node-promise').defer;

  MongoPersistence = (function() {
    function MongoPersistence() {
      this.remove = bind(this.remove, this);
      this.set = bind(this.set, this);
      this.byProviderId = bind(this.byProviderId, this);
      this.get = bind(this.get, this);
      this.all = bind(this.all, this);
      this.getDbFor = bind(this.getDbFor, this);
      this.getConnection = bind(this.getConnection, this);
      this.connect = bind(this.connect, this);
      this.dbs = [];
    }

    MongoPersistence.prototype.connect = function() {
      return console.log('Mongo connect called');
    };

    MongoPersistence.prototype.getConnection = function() {
      var q;
      q = defer();
      if (this.db) {
        q.resolve(this.db);
      } else {
        MongoClient.connect('mongodb://localhost:27017/spincycle', (function(_this) {
          return function(err, db) {
            if (err) {
              console.log('MONGO Error connection: ' + err);
              console.dir(err);
              return q.resolve(null);
            } else {
              console.log("---- We are connected ----");
              _this.db = db;
              return q.resolve(db);
            }
          };
        })(this));
      }
      return q;
    };

    MongoPersistence.prototype.getDbFor = function(_type) {
      var db, q, type;
      q = defer();
      type = _type.toLowerCase();
      db = this.dbs[type];
      if (!db) {
        this.getConnection().then((function(_this) {
          return function(connection) {
            return connection.collection(type, function(err, collection) {
              if (err) {
                console.log('MONGO Error getting collection: ' + err);
                console.dir(err);
                return q.resolve(null);
              } else {
                _this.dbs[type] = collection;
                return q.resolve(collection);
              }
            });
          };
        })(this));
      } else {
        q.resolve(db);
      }
      return q;
    };

    MongoPersistence.prototype.all = function(_type, cb) {
      var type;
      type = _type.toLowerCase();
      return this.getDbFor(type).then((function(_this) {
        return function(collection) {
          return collection.find().toArray(function(err, items) {
            if (err) {
              console.log('MONGO Error getting all: ' + err);
              console.dir(err);
              return cb(null);
            } else {
              return cb(items);
            }
          });
        };
      })(this));
    };

    MongoPersistence.prototype.get = function(_type, id, cb) {
      var type;
      type = _type.toLowerCase();
      console.log('Mongo.get called for type ' + type + ' and id ' + id);
      if (typeof id === 'object') {
        console.dir(id);
      }
      return this.getDbFor(type).then((function(_this) {
        return function(collection) {
          return collection.findOne({
            id: id
          }, function(err, item) {
            if (err) {
              console.log('MONGO get Error: ' + err);
              console.dir(err);
              return cb(null);
            } else {
              return cb(item);
            }
          });
        };
      })(this));
    };

    MongoPersistence.prototype.byProviderId = function(_type, pid) {
      var q, type;
      console.log('byProviderId called for pid ' + pid + ' and type ' + _type);
      q = defer();
      type = _type.toLowerCase();
      this.getDbFor(type).then((function(_this) {
        return function(collection) {
          return collection.findOne({
            providerId: pid
          }, function(err, item) {
            if (err) {
              console.log('MONGO byProviderId Error: ' + err);
              console.dir(err);
              return q.resolve(null);
            } else {
              return q.resolve(item);
            }
          });
        };
      })(this));
      return q;
    };

    MongoPersistence.prototype.set = function(_type, obj, cb) {
      var type;
      type = _type.toLowerCase();
      return this.getDbFor(type).then((function(_this) {
        return function(collection) {
          console.log('Mongo.set called for type ' + type + ' and id ' + obj.id);
          if (typeof obj.id === 'object') {
            console.dir(obj);
          }
          return collection.update({
            id: obj.id
          }, obj, {
            upsert: true
          }, function(err, result, upserted) {
            if (err) {
              console.log('MONGO set Error: ' + err);
              console.dir(err);
              return cb(null);
            } else {
              return cb(result);
            }
          });
        };
      })(this));
    };

    MongoPersistence.prototype.remove = function(_type, obj, cb) {
      var type;
      type = _type.toLowerCase();
      return this.getDbFor(type).then((function(_this) {
        return function(collection) {
          return collection.remove({
            id: obj.id
          }, {
            w: 1
          }, function(err, numberOfRemovedDocs) {
            if (err) {
              console.log('MONGO remove Error: ' + err);
              console.dir(err);
              return cb(null);
            } else {
              return cb(obj);
            }
          });
        };
      })(this));
    };

    return MongoPersistence;

  })();

  module.exports = MongoPersistence;

}).call(this);

//# sourceMappingURL=MongoPersistence.js.map