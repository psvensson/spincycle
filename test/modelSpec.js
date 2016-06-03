// Generated by CoffeeScript 1.10.0
(function() {
  var AuthenticationManager, DB, OStore, ResolveModule, SpinCycle, SuperModel, app, expect, express,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  expect = require('chai').expect;

  SuperModel = require('../lib/SuperModel');

  ResolveModule = require('../lib/ResolveModule');

  DB = require('../lib/DB');

  OStore = require('../lib/OStore');

  AuthenticationManager = require('../example/AuthenticationManager');

  express = require("express");

  app = express();

  SpinCycle = require('../lib/MessageRouter');

  describe('Spincycle Model Tests', function() {
    var Bar, Baz, DFoo, DirectBar, Ezra, Foo, Fooznaz, HashBar, Quux, authMgr, f1record, f2record, f3record, f4record, f5record, messageRouter, postCreateState, record, record2;
    authMgr = void 0;
    messageRouter = void 0;
    before(function(done) {
      console.log('------------------------------------- before called');
      return DB.createDatabases(['foo', 'bar', 'dfoo', 'directbar', 'hashbar']).then(function() {
        console.log('++++++++++++++++++++++++++++++++++++spec dbs created');
        authMgr = new AuthenticationManager();
        messageRouter = new SpinCycle(authMgr, null, 10);
        messageRouter.open();
        return done();
      });
    });
    record = {
      _rev: 99101020202030303404,
      id: 17,
      name: 'foo'
    };
    f1record = {
      _rev: 'f10101020202030303404',
      id: 'f117',
      name: 'foo'
    };
    f2record = {
      _rev: 'f20101020202030303404',
      id: 'f217',
      name: 'foo'
    };
    f3record = {
      _rev: 'f30101020202030303404',
      id: 'f317',
      name: 'foo'
    };
    f4record = {
      _rev: 'f40101020202030303404',
      id: 'f417',
      name: 'foo'
    };
    f5record = {
      _rev: 'f50101020202030303404',
      id: 'f517',
      name: 'foo'
    };
    record2 = {
      _rev: 77788877788899900099,
      id: 4711,
      name: 'xyzzy',
      theFoo: 17,
      foos: [17],
      footable: [17]
    };
    Foo = (function(superClass) {
      extend(Foo, superClass);

      Foo.type = 'Foo';

      Foo.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'foo'
        }
      ];

      function Foo(record1) {
        this.record = record1 != null ? record1 : {};
        return Foo.__super__.constructor.apply(this, arguments);
      }

      return Foo;

    })(SuperModel);
    ResolveModule.modulecache['Foo'] = Foo;
    DFoo = (function(superClass) {
      extend(DFoo, superClass);

      DFoo.type = 'DFoo';

      DFoo.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'foo'
        }
      ];

      function DFoo(record1) {
        this.record = record1 != null ? record1 : {};
        return DFoo.__super__.constructor.apply(this, arguments);
      }

      return DFoo;

    })(SuperModel);
    Bar = (function(superClass) {
      extend(Bar, superClass);

      Bar.type = 'Bar';

      Bar.model = [
        {
          name: 'name',
          "public": true,
          value: 'name',
          "default": 'yohoo'
        }, {
          name: 'theFoo',
          value: 'theFoo',
          type: 'Foo'
        }, {
          name: 'foos',
          "public": true,
          array: true,
          ids: 'foos',
          type: 'Foo'
        }, {
          name: 'footable',
          hashtable: true,
          ids: 'footable',
          type: 'Foo'
        }
      ];

      function Bar(record1) {
        this.record = record1 != null ? record1 : {};
        return Bar.__super__.constructor.apply(this, arguments);
      }

      return Bar;

    })(SuperModel);
    HashBar = (function(superClass) {
      extend(HashBar, superClass);

      HashBar.type = 'HashBar';

      HashBar.model = [
        {
          name: 'name',
          "public": true,
          value: 'name',
          "default": 'yohoo'
        }, {
          name: 'theFoo',
          value: 'theFoo',
          type: 'Foo'
        }, {
          name: 'foos',
          "public": true,
          array: true,
          ids: 'foos'
        }, {
          name: 'footable',
          hashtable: true,
          ids: 'footable',
          type: 'Foo',
          keyproperty: 'id'
        }
      ];

      function HashBar(record1) {
        this.record = record1 != null ? record1 : {};
        return HashBar.__super__.constructor.apply(this, arguments);
      }

      return HashBar;

    })(SuperModel);
    ResolveModule.modulecache['Bar'] = Bar;
    ResolveModule.modulecache['HashBar'] = HashBar;
    Fooznaz = (function(superClass) {
      extend(Fooznaz, superClass);

      Fooznaz.type = 'Fooznaz';

      Fooznaz.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'fooznaz',
          "public": true
        }, {
          name: 'things',
          ids: 'things',
          array: true,
          type: 'Bar',
          "public": true
        }
      ];

      function Fooznaz(record1) {
        this.record = record1 != null ? record1 : {};
        return Fooznaz.__super__.constructor.apply(this, arguments);
      }

      return Fooznaz;

    })(SuperModel);
    DirectBar = (function(superClass) {
      extend(DirectBar, superClass);

      DirectBar.type = 'DirectBar';

      DirectBar.model = [
        {
          name: 'name',
          "public": true,
          value: 'name',
          "default": 'directyohoo'
        }, {
          name: 'theFoo',
          value: 'theFoo',
          type: 'DFoo',
          storedirectly: true
        }, {
          name: 'foos',
          "public": true,
          type: 'DFoo',
          array: true,
          ids: 'foos',
          storedirectly: true
        }, {
          name: 'footable',
          hashtable: true,
          ids: 'footable',
          type: 'DFoo',
          storedirectly: true
        }
      ];

      function DirectBar(record1) {
        this.record = record1 != null ? record1 : {};
        return DirectBar.__super__.constructor.apply(this, arguments);
      }

      return DirectBar;

    })(SuperModel);
    postCreateState = -1;
    this.record3 = {
      id: 42,
      name: 'xyzzy',
      shoesize: 42
    };
    this.record4 = {
      id: 667,
      name: 'Neihgbor of the beast',
      hatsize: 42
    };
    this.record5 = {
      id: 9,
      name: 'Neihgbor of the beast',
      shirtsize: 42
    };
    Baz = (function(superClass) {
      extend(Baz, superClass);

      Baz.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'baz'
        }, {
          name: 'shoesize',
          value: 'shoesize',
          "default": '-1'
        }
      ];

      function Baz(record1) {
        this.record = record1 != null ? record1 : {};
        postCreateState = 3;
        return Baz.__super__.constructor.apply(this, arguments);
      }

      return Baz;

    })(SuperModel);
    Quux = (function(superClass) {
      extend(Quux, superClass);

      Quux.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'baz'
        }, {
          name: 'hatsize',
          value: 'hatsize',
          "default": '0'
        }
      ];

      function Quux(record1) {
        this.record = record1 != null ? record1 : {};
        this.postCreate = bind(this.postCreate, this);
        postCreateState = 2;
        return Quux.__super__.constructor.apply(this, arguments);
      }

      Quux.prototype.postCreate = function(q) {
        postCreateState = 1;
        return new Baz(this.record3).then((function(_this) {
          return function(baz) {
            postCreateState = 4;
            return q.resolve(_this);
          };
        })(this));
      };

      return Quux;

    })(SuperModel);
    Ezra = (function(superClass) {
      extend(Ezra, superClass);

      Ezra.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'baz'
        }, {
          name: 'shirtsize',
          value: 'shirtsize',
          "default": '7'
        }, {
          name: 'thequux',
          value: 'thequux',
          type: 'Quux'
        }
      ];

      function Ezra(record1) {
        this.record = record1 != null ? record1 : {};
        this.postCreate = bind(this.postCreate, this);
        postCreateState = 0;
        return Ezra.__super__.constructor.apply(this, arguments);
      }

      Ezra.prototype.postCreate = function(q) {
        var postCreateStatee;
        postCreateStatee = 1;
        return new Quux(this.record4).then((function(_this) {
          return function(quux) {
            _this.thequux = quux;
            postCreateState = 5;
            return q.resolve(_this);
          };
        })(this));
      };

      return Ezra;

    })(SuperModel);
    it('should retain _rev property from record', function() {
      return new Foo(record).then(function(o) {
        return expect(o._rev).to.equal(record._rev);
      });
    });
    it('should get back basic values when creating record', function() {
      return new Foo(f1record).then(function(o) {
        var rv;
        rv = o.getRecord();
        return expect(rv.name).to.equal(record.name);
      });
    });
    it('should get resolve direct reference values from record', function() {
      return new Foo(f2record).then(function(foo) {
        return new Bar(record2).then(function(bar) {
          return expect(bar.theFoo).to.exist;
        });
      });
    });
    it('should get back id from direct reference when creating record', function() {
      return new Foo(f1record).then(function(foo) {
        OStore.storeObject(foo);
        return new Bar(record2).then(function(bar) {
          var rv;
          rv = bar.getRecord();
          return expect(rv.theFoo).to.equal(record.id);
        });
      });
    });
    it('should be able to create a hashtable property from record', function() {
      return new Bar(record2).then(function(bar) {
        return expect(bar.footable).to.exist;
      });
    });
    it('should be able to persist newly added hashtable references and still have them after serializing and reloading from record', function() {
      return new Bar(record2).then(function(bar) {
        OStore.storeObject(bar);
        return new Foo(f4record).then(function(foo) {
          OStore.storeObject(foo);
          bar.footable[foo.name] = foo;
          foo.serialize();
          bar.serialize();
          return DB.get('Bar', [4711]).then(function(newbars) {
            var newbar;
            newbar = newbars[0];
            return expect(newbar.footable).to.exist;
          });
        });
      });
    });
    it('should be able to use custom properties for hashtable keys', function() {
      var record222;
      record222 = {
        _rev: 71299900099,
        id: 174711,
        name: 'BAR xyzzy',
        theFoo: 17,
        foos: [17]
      };
      return new HashBar(record222).then(function(bar) {
        OStore.storeObject(bar);
        return new Foo(f4record).then(function(foo) {
          OStore.storeObject(foo);
          bar.footable[foo.id] = foo;
          foo.serialize();
          bar.serialize();
          return DB.get('HashBar', [174711]).then(function(newbars) {
            var newbar;
            newbar = newbars[0];
            return new HashBar(newbar).then(function(nbobj) {
              return expect(nbobj.footable[foo.id]).to.equal(foo);
            });
          });
        });
      });
    });
    it('should get back array of ids from array reference when creating record', function() {
      return new Foo(f5record).then(function(afoo) {
        OStore.storeObject(afoo);
        return new Bar(record2).then(function(bar) {
          var c, i, j, results;
          OStore.storeObject(bar);
          c = 10;
          results = [];
          for (i = j = 1; j <= 10; i = ++j) {
            results.push(new Foo().then(function(foo) {
              var rv;
              OStore.storeObject(foo);
              bar.foos.push(foo);
              if (--c === 0) {
                rv = bar.getRecord();
                return expect(rv.foos.length).to.be(10);
              }
            }));
          }
          return results;
        });
      });
    });
    it('should filter record properties to only show those that are public when calling toClient', function() {
      return new Bar(record2).then(function(bar) {
        var rv;
        rv = bar.toClient();
        expect(rv.footable).to.not.exist;
        return expect(rv.name).to.exist;
      });
    });
    it('should call postCreate, when defined, in serial order down the references', function() {
      return new Ezra(this.record5).then(function(ezra) {
        return expect(postCreateState).to.equal(5);
      });
    });
    it('should retain hashtable key name and values after persistence', function() {
      return new Foo(record).then(function(foo) {
        OStore.storeObject(foo);
        return new Bar(record2).then(function(bar) {
          OStore.storeObject(bar);
          return bar.serialize().then(function() {
            return DB.get('Bar', [4711]).then(function(bar_records) {
              var bar_record;
              bar_record = bar_records[0];
              return new Bar(bar_record).then(function(newbar) {
                var i, j, k, keys1, keys2, kk, len, ref, ref1, same, v, vals1, vals2, vv;
                same = false;
                keys1 = [];
                keys2 = [];
                vals1 = [];
                vals2 = [];
                ref = newbar.footable;
                for (k in ref) {
                  v = ref[k];
                  keys1.push(k);
                  vals1.push(v);
                }
                ref1 = bar.footable;
                for (kk in ref1) {
                  vv = ref1[kk];
                  keys2.push(k);
                  vals2.push(v);
                }
                for (i = j = 0, len = keys1.length; j < len; i = ++j) {
                  k = keys1[i];
                  if (keys1[i] && keys1[i] !== keys2[i]) {
                    same = false;
                  } else {
                    same = true;
                  }
                  if (vals1[i] && vals1[i] !== vals2[i]) {
                    same = false;
                  } else {
                    same = true;
                  }
                }
                return expect(same).to.equal(true);
              });
            });
          });
        });
      });
    });
    it('should filter out crap values in arrays when updating', function() {
      return new Fooznaz().then(function(fz) {
        record = fz.toClient();
        record.things.push(null);
        record.things.push("null");
        record.things.push("undefined");
        record.things.push(void 0);
        return new Fooznaz(record).then(function(fz2) {
          return expect(fz2.things.length).to.equal(0);
        });
      });
    });
    it('should always return an array from listObjects', function(done) {
      var msg;
      msg = {
        type: 'Foo',
        user: {
          isAdmin: true
        },
        replyFunc: function(reply) {
          expect(reply.payload.length).to.gt(0);
          return done();
        }
      };
      return messageRouter.objectManager._listObjects(msg);
    });
    it('should include whole objects when using storedirectly', function(done) {
      var record7;
      record7 = {
        id: 'aaa3',
        type: 'DFoo',
        name: 'BolarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      ResolveModule.modulecache['DirectBar'] = DirectBar;
      return new DFoo(record7).then(function(dfoo) {
        return new DirectBar().then(function(dbar) {
          dbar.theFoo = dfoo;
          dbar.foos.push(dfoo);
          dbar.footable[dfoo.name] = dfoo;
          return dbar.serialize().then(function() {
            return DB.get('DirectBar', [dbar.id]).then(function(dbar_records) {
              var bar_record;
              bar_record = dbar_records[0];
              return new DirectBar(bar_record).then(function(newdbar) {
                expect(newdbar.theFoo.name).to.equal(dfoo.name);
                return done();
              });
            });
          });
        });
      });
    });
    it('should be able to do a search on a property', function(done) {
      var record7;
      record7 = {
        id: 'bbb456',
        type: 'DFoo',
        name: 'BolarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record7).then(function(dfoo) {
        var query;
        dfoo.serialize();
        query = {
          sort: 'name',
          property: 'name',
          value: 'BolarsKolars'
        };
        return DB.findQuery('DFoo', query).then((function(_this) {
          return function(records) {
            expect(records.length).to.equal(1);
            return done();
          };
        })(this));
      });
    });
    it('should not get any results when searching on the wrong property', function(done) {
      var record7;
      record7 = {
        id: 'bbb456',
        type: 'DFoo',
        name: 'BolarsKolars2'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record7).then(function(dfoo) {
        var query;
        dfoo.serialize();
        query = {
          sort: 'name',
          property: 'id',
          value: 'BolarsKolars2'
        };
        return DB.findQuery('DFoo', query).then((function(_this) {
          return function(records) {
            expect(records.length).to.equal(0);
            return done();
          };
        })(this));
      });
    });
    it('should not be able to search on a wildcard property', function(done) {
      var record8;
      record8 = {
        id: 'bbb456',
        type: 'DFoo',
        name: 'MehmetBolarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record8).then(function(dfoo) {
        var query;
        dfoo.serialize();
        query = {
          sort: 'name',
          property: 'name',
          value: 'Meh',
          wildcard: true
        };
        return DB.findQuery('DFoo', query).then((function(_this) {
          return function(records) {
            expect(records.length).to.equal(1);
            return done();
          };
        })(this));
      });
    });
    it('should be able to get two hits on a wildcard property', function(done) {
      var record10, record9;
      record9 = {
        id: 'bbb4567',
        type: 'DFoo',
        name: 'Myfflan sKolars'
      };
      record10 = {
        id: 'bbb45677',
        type: 'DFoo',
        name: 'MyhmetBolarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record9).then(function(dfoo1) {
        dfoo1.serialize();
        return new DFoo(record10).then(function(dfoo2) {
          var query;
          dfoo2.serialize();
          query = {
            sort: 'name',
            property: 'name',
            value: 'My',
            wildcard: true
          };
          return DB.findQuery('DFoo', query).then((function(_this) {
            return function(records) {
              expect(records.length).to.equal(2);
              return done();
            };
          })(this));
        });
      });
    });
    it('should not bomb on searches with wildcard characters', function(done) {
      var record11;
      record11 = {
        id: 'bb3356',
        type: 'DFoo',
        name: 'ArnelarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record11).then(function(dfoo) {
        var query;
        dfoo.serialize();
        query = {
          sort: 'name',
          property: 'name',
          value: 'Arne*',
          wildcard: true
        };
        return DB.findQuery('DFoo', query).then((function(_this) {
          return function(records) {
            expect(records.length).to.equal(1);
            return done();
          };
        })(this));
      });
    });
    it('should not bomb on specific searches with faulty values', function(done) {
      var record12;
      record12 = {
        id: 'b44b3356',
        type: 'DFoo',
        name: 'MixnelarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record12).then(function(dfoo) {
        var query;
        dfoo.serialize();
        query = {
          sort: 'name',
          property: 'id',
          value: '[Object object]'
        };
        return DB.findQuery('DFoo', query).then((function(_this) {
          return function(records) {
            expect(records.length).to.equal(0);
            return done();
          };
        })(this));
      });
    });
    it('should be able to do specific searches', function(done) {
      var record12;
      record12 = {
        id: 'b44rrb3356',
        type: 'DFoo',
        name: 'AlohaMixnelarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record12).then(function(dfoo) {
        dfoo.serialize();
        return DB.findMany('DFoo', 'id', 'b44rrb3356').then((function(_this) {
          return function(records) {
            expect(records.length).to.equal(1);
            return done();
          };
        })(this));
      });
    });
    it('should get an error message when sending too many requests per second', function(done) {
      var count, failure, i, j, msg, results, user;
      user = {
        name: 'foo',
        id: 17
      };
      count = 12;
      failure = false;
      results = [];
      for (i = j = 0; j <= 12; i = ++j) {
        msg = {
          target: 'listcommands',
          user: user,
          replyFunc: function(reply) {
            console.log('reply was ' + reply.info);
            if (reply.status === 'NOT_ALLOWED') {
              failure = true;
            }
            if (--count === 0) {
              expect(failure).to.equal(true);
              return done();
            }
          }
        };
        results.push(messageRouter.routeMessage(msg));
      }
      return results;
    });
    it('should update an array on an object with a reference and have that reference be present in the array when searching for the object', function(done) {
      return new Bar().then(function(bar) {
        bar.serialize();
        return new Foo().then(function(foo) {
          var msg, umsg;
          foo.serialize();
          umsg = {
            obj: {
              id: bar.id,
              foos: [foo.id]
            },
            user: {
              isAdmin: true
            },
            replyFunc: function(ureply) {
              return console.log('update reply was');
            }
          };
          messageRouter.objectManager._updateObject(umsg);
          msg = {
            type: 'Bar',
            user: {
              isAdmin: true
            },
            replyFunc: function(reply) {
              expect(reply.payload.length).to.gt(0);
              return done();
            }
          };
          return messageRouter.objectManager._listObjects(msg);
        });
      });
    });
    it('should be able to resolve object graphs properly', function(done) {
      return messageRouter.objectManager.resolveReferences(record2, Bar.model).then(function(result) {
        console.log('---------------- resolvereferences results ------------------');
        console.dir(result);
        return done();
      });
    });
    return it('should be able to update scalars without trashing array references', function(done) {
      return new Bar().then(function(bar) {
        return new Foo().then(function(foo) {
          var brecord;
          foo.serialize();
          bar.foos.push(foo);
          bar.serialize();
          console.log('------------------------- initial bar object');
          console.dir(bar);
          brecord = bar.toClient();
          brecord.name = 'Doctored Bar object';
          return messageRouter.objectManager.resolveReferences(brecord, Bar.model).then(function(result) {
            console.log('---------------- resolvereferences results ------------------');
            console.dir(result);
            return done();
          });
        });
      });
    });
  });

}).call(this);

//# sourceMappingURL=modelSpec.js.map
