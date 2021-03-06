// Generated by CoffeeScript 1.12.6
(function() {
  var RethinkPersistence, debug, defer, r,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  r = require('rethinkdb');

  defer = require('node-promise').defer;

  debug = process.env["DEBUG"];

  RethinkPersistence = (function() {
    var madr, mport;

    if (process.env['RETHINKDB_HOST']) {
      madr = process.env['RETHINKDB_HOST'];
    } else {
      madr = '127.0.0.1';
    }

    mport = process.env['RETHINKDB_PORT_28015_TCP_PORT'] || '28015';

    function RethinkPersistence(dburl, DB) {
      this.dburl = dburl;
      this.DB = DB;
      this.remove = bind(this.remove, this);
      this.set = bind(this.set, this);
      this.search = bind(this.search, this);
      this.findQuery = bind(this.findQuery, this);
      this.filter = bind(this.filter, this);
      this.findMany = bind(this.findMany, this);
      this.find = bind(this.find, this);
      this.get = bind(this.get, this);
      this.count = bind(this.count, this);
      this.all = bind(this.all, this);
      this.extend = bind(this.extend, this);
      this.getDbFor = bind(this.getDbFor, this);
      this.addIndexIfNotPresent = bind(this.addIndexIfNotPresent, this);
      this._dogetDBFor = bind(this._dogetDBFor, this);
      this.listenForChanges = bind(this.listenForChanges, this);
      this.getConnection = bind(this.getConnection, this);
      this.connect = bind(this.connect, this);
      console.log('RethinkPersistence::constructor dburl = ' + this.dburl);
      this.connection = void 0;
      this.dbs = [];
    }

    RethinkPersistence.prototype.connect = function() {
      var ccc, q;
      console.log('connect called...  dburl = ' + this.dburl);
      q = defer();
      ccc = this.dburl || {
        host: madr,
        port: mport
      };
      r.connect(ccc, (function(_this) {
        return function(err, conn) {
          if (err) {
            throw err;
          }
          _this.connection = conn;
          return q.resolve(_this);
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.getConnection = function() {};

    RethinkPersistence.prototype.listenForChanges = function(table) {
      return table.changes().run(this.connection).then((function(_this) {
        return function(cursor) {
          if (cursor) {
            return cursor.each(function(el) {
              if (debug) {
                console.log('Rethink changes update --- --- ---');
              }
              if (debug) {
                console.dir(el);
              }
              if (_this.DB) {
                if (el) {
                  return _this.DB.onUpdated(el);
                }
              } else {
                return console.log('@DB not defined in rethinkPersistence!!');
              }
            });
          }
        };
      })(this));
    };

    RethinkPersistence.prototype._dogetDBFor = function(_type) {
      var q, type;
      q = defer();
      type = _type.toLowerCase();
      r.dbList().contains('spincycle')["do"](function(databaseExists) {
        return r.branch(databaseExists, {
          created: 0
        }, r.dbCreate('spincycle'));
      }).run(this.connection, (function(_this) {
        return function(err, res) {
          if (err) {
            console.log('Rethink getDbFor err = ' + err);
            console.dir(err);
          }
          if (_this.dbs[type]) {
            return q.resolve(_this.dbs[type]);
          } else {
            return r.db('spincycle').tableList().run(_this.connection, function(te, _tlist) {
              var exists, table, tlist;
              tlist = _tlist || [];
              exists = (tlist.filter(function(el) {
                return el === type;
              }))[0];
              if (exists === type) {
                table = _this.dbs[type];
                if (!table) {
                  table = r.db('spincycle').table(type);
                  _this.dbs[type] = table;
                  _this.listenForChanges(table);
                }
                return q.resolve(table);
              } else {
                console.log('exist != ' + type);
                return r.db('spincycle').tableCreate(type).run(_this.connection, function(err2, res2) {
                  if (err2) {
                    console.log('tableList err = ' + err2);
                    console.dir(err2);
                  }
                  table = r.db('spincycle').table(type);
                  console.log('creating new table ' + type);
                  _this.dbs[type] = table;
                  _this.listenForChanges(table);
                  return q.resolve(table);
                });
              }
            });
          }
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.addIndexIfNotPresent = function(table, type, prop) {
      var q;
      q = defer();
      table.indexList().run(this.connection, (function(_this) {
        return function(err2, res2) {
          var found;
          console.log('---- addindex check result for property ' + prop + ' on table ' + type + ' ---> ' + res2);
          console.dir(res2);
          found = false;
          res2.forEach(function(el) {
            if (el === prop) {
              return found = true;
            }
          });
          if (!found) {
            console.log('addIndexIfNotPresent adding multi index for property ' + prop + ' on table ' + type);
            table.indexCreate(prop, {
              multi: true
            });
            return table.indexWait(prop).run(_this.connection, function(er2, re2) {
              console.log('addIndexIfNotPresent waited done');
              return q.resolve();
            });
          } else {
            return q.resolve();
          }
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.getDbFor = function(_type) {
      var q;
      q = defer();
      if (!this.connection) {
        this.connect().then((function(_this) {
          return function() {
            return _this._dogetDBFor(_type).then(function(db) {
              return q.resolve(db);
            });
          };
        })(this));
      } else {
        this._dogetDBFor(_type).then((function(_this) {
          return function(db) {
            return q.resolve(db);
          };
        })(this));
      }
      return q;
    };

    RethinkPersistence.prototype.extend = function(_type, id, field, def) {
      var q;
      q = defer();
      this.get(_type, id, (function(_this) {
        return function(o) {
          if (o && !o[field]) {
            o[field] = def;
            return _this.set(_type, o, function(setdone) {
              return q.resolve(o);
            });
          }
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.all = function(_type, query, cb) {
      var type;
      type = _type.toLowerCase();
      return this.getDbFor(type).then((function(_this) {
        return function(db) {
          var rr;
          rr = db;
          if (query) {
            rr = rr.orderBy(query.sort || 'name');
            if (query.skip) {
              rr = rr.skip(parseInt(query.skip || 0));
            }
            if (query.limit) {
              rr = rr.limit(parseInt(query.limit));
            }
          }
          return rr.run(_this.connection, function(err, cursor) {
            if (err) {
              console.log('all err: ' + err);
              console.dir(err);
              throw err;
            }
            return cursor.toArray((function(_this) {
              return function(ce, result) {
                return cb(result);
              };
            })(this));
          });
        };
      })(this));
    };

    RethinkPersistence.prototype.count = function(_type) {
      var q, type;
      if (debug) {
        console.log('Rethink.count called');
      }
      type = _type.toLowerCase();
      q = defer();
      this.getDbFor(type).then((function(_this) {
        return function(db) {
          return db.count().run(_this.connection, function(err, result) {
            if (err) {
              console.log('count err: ' + err);
              console.dir(err);
              throw err;
            }
            if (debug) {
              console.log(result);
            }
            return q.resolve(result);
          });
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.get = function(_type, id, cb) {
      var type;
      type = _type.toLowerCase();
      return this.getDbFor(type).then((function(_this) {
        return function(db) {
          return db.get(id).run(_this.connection, function(err, result) {
            if (err) {
              console.log('get err: ' + err);
              console.dir(err);
              throw err;
            }
            if (debug) {
              console.log('RethinkPersistence get result was');
            }
            if (debug) {
              console.log(result);
            }
            return cb(result);
          });
        };
      })(this));
    };

    RethinkPersistence.prototype.find = function(_type, property, _value) {
      return this.findMany(_type, property, _value);
    };

    RethinkPersistence.prototype.findMany = function(_type, _property, _value) {
      var property, q, type, value;
      if (debug) {
        console.log('Rethink.findMany called');
      }
      property = _property || "";
      value = _value || "";
      if (value) {
        value = value.toString();
        value = value.replace(/[^\w\s@.-]/gi, '');
      }
      q = defer();
      type = _type.toLowerCase();
      this.getDbFor(type).then((function(_this) {
        return function(db) {
          return db.filter(function(element) {
            if (property) {
              return element(property).eq(value);
            }
          }).run(_this.connection, function(err, cursor) {
            if (err) {
              console.log('findMany err: ' + err);
              console.dir(err);
              throw err;
            }
            return cursor.toArray((function(_this) {
              return function(ce, result) {
                return q.resolve(result);
              };
            })(this));
          });
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.filter = function(_type, query) {
      var q, type;
      if (debug) {
        console.log('Rethink filter called for type ' + _type);
      }
      if (debug) {
        console.dir(query);
      }
      q = defer();
      type = _type.toLowerCase();
      this.getDbFor(type).then((function(_this) {
        return function(db) {
          return db.filter(query).run(_this.connection, function(err, cursor) {
            if (debug) {
              console.log('filter cursor got back');
            }
            if (debug) {
              console.dir(cursor);
            }
            if (err) {
              console.log('filter error: ' + err);
              console.dir(err);
            }
            return cursor.toArray((function(_this) {
              return function(ce, result) {
                if (debug) {
                  console.log('Rethink filter got ' + result.length + ' results');
                }
                return q.resolve(result);
              };
            })(this));
          });
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.findQuery = function(_type, query) {
      var q, type;
      if (debug) {
        console.log('Rethink findQuery called for type ' + _type);
      }
      if (debug) {
        console.dir(query);
      }
      if (!query.property) {
        query.property = 'name';
      }
      q = defer();
      type = _type.toLowerCase();
      this.getDbFor(type).then((function(_this) {
        return function(db) {
          var rr, sv;
          rr = r.db('spincycle').table(type);
          sv = query.sort || 'name';
          return _this.addIndexIfNotPresent(rr, type, sv).then(function() {
            var rv, rv2;
            rv = _this.getValueForQuery('value', 'property', query);
            if (!rv.invalid) {
              rr = rr.filter(function(element) {
                if (query.wildcard) {
                  return element(query.property).match("^" + query.value);
                } else {
                  return element(query.property).eq(query.value);
                }
              });
              if (query.property2) {
                rv2 = _this.getValueForQuery('value2', 'property2', query);
                if (!rv2.invalid) {
                  rr = rr.filter(function(el) {
                    if (query.wildcard) {
                      return el(query.property2).match(rv2.value);
                    } else {
                      return el(query.property2).eq(rv2.value);
                    }
                  });
                }
              }
              if (query.limit) {
                rr = rr.skip(query.skip || 0).limit(query.limit);
              }
              if (query.orderBy) {
                rr = rr.orderBy(r.desc(query.orderBy));
              }
              if (debug) {
                console.log('Rethink findQuery running query...');
              }
              return rr.run(_this.connection, function(err, cursor) {
                if (err) {
                  console.log('findQuery error: ' + err);
                  console.dir(err);
                  return resolve([]);
                } else {
                  return cursor.toArray((function(_this) {
                    return function(ce, result) {
                      return q.resolve(result);
                    };
                  })(this));
                }
              });
            } else {
              return q.resolve([]);
            }
          });
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.getValueForQuery = function(val, prop, query) {
      var rv, value;
      if (debug) {
        console.log('getValueFor called with valname ' + val + ' and propname ' + prop);
      }
      rv = query[val] === 'undefined' || query[val].indexOf('[') > -1 || query[val] === 'null' || query[val].indexOf('bject') > -1;
      value = query[val].toString();
      value = value.replace(/[`~!@#$%^&*()_|+\=?;:'",.<>\{\}\[\]\\\/]/gi, '');
      if (debug) {
        console.log('final search value is ' + value);
      }
      return {
        invalid: rv,
        value: value
      };
    };

    RethinkPersistence.prototype.search = function(_type, property, _value) {
      var q, value;
      if (debug) {
        console.log('Rethink.search called');
      }
      value = _value || "";
      if (value) {
        value = value.toString();
        value = value.replace(/[^\w\s@.]/gi, '');
      }
      console.log('Rethink search called for type ' + _type + ' property ' + property + ' and value ' + value);
      q = defer();
      this.getDbFor(type).then((function(_this) {
        return function(db) {
          return db.filter(function(element) {
            if (query.wildcard) {
              return element(property).match("^" + value);
            } else {
              return element(property).eq(value);
            }
          }).run(_this.connection, function(err, cursor) {
            if (err) {
              console.log('search err: ' + err);
              console.dir(err);
              throw err;
            }
            return cursor.toArray((function(_this) {
              return function(ce, result) {
                console.log('search result is ' + result);
                console.log(result);
                return q.resolve(result);
              };
            })(this));
          });
        };
      })(this));
      return q;
    };

    RethinkPersistence.prototype.set = function(_type, obj, cb) {
      var type;
      type = _type.toLowerCase();
      if (obj) {
        return this.getDbFor(type).then((function(_this) {
          return function(db) {
            var ex;
            try {
              return db.insert(obj, {
                conflict: "update",
                return_changes: true
              }).run(_this.connection, function(err, result) {
                if (err) {
                  console.log('set err: ' + err);
                  console.dir(err);
                  throw err;
                  return cb();
                } else {
                  return cb(result);
                }
              });
            } catch (error) {
              ex = error;
              console.log('caught exception!');
              console.dir(ex);
              console.dir(obj);
              return cb();
            }
          };
        })(this));
      } else {
        if (debug) {
          console.log('Rethink.set not OK (empty obj)');
        }
        return cb();
      }
    };

    RethinkPersistence.prototype.remove = function(_type, obj, cb) {
      var id, type;
      if (debug) {
        console.log('Rethink.remove called');
      }
      type = _type.toLowerCase();
      id = obj.id;
      return this.getDbFor(type).then((function(_this) {
        return function(db) {
          return db.get(id)["delete"]().run(_this.connection, function(err, result) {
            if (err) {
              console.log('remove err: ' + err);
              console.dir(err);
              throw err;
            }
            return cb(result);
          });
        };
      })(this));
    };

    return RethinkPersistence;

  })();

  module.exports = RethinkPersistence;

}).call(this);

//# sourceMappingURL=RethinkPersistence.js.map
