// Generated by CoffeeScript 1.10.0
(function() {
  var AuthenticationManager, ClientEndpoints, DB, OStore, ResolveModule, SpinCycle, SuperModel, app, expect, express, request, unirest,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  expect = require('chai').expect;

  SuperModel = require('../lib/SuperModel');

  ResolveModule = require('../lib/ResolveModule');

  DB = require('../lib/DB');

  OStore = require('../lib/OStore');

  request = require('request');

  unirest = require('unirest');

  AuthenticationManager = require('../example/AuthenticationManager');

  express = require("express");

  app = express();

  SpinCycle = require('../lib/MessageRouter');

  ClientEndpoints = require('../lib/ClientEndpoints');

  describe('Spincycle Model Tests', function() {
    var Bar, Baz, DFoo, DirectBar, Ezra, Foo, Fooznaz, HashBar, Quux, authMgr, f1record, f2record, f3record, f4record, f5record, httpMethod, messageRouter, postCreateState, record, record2;
    authMgr = void 0;
    messageRouter = void 0;
    httpMethod = void 0;
    record = {
      _rev: 99101020202030303404,
      id: '17',
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
    before(function(done) {
      authMgr = new AuthenticationManager();
      messageRouter = new SpinCycle(authMgr, null, 10, app, 'rethinkdb');
      httpMethod = new SpinCycle.HttpMethod(messageRouter, app, '/api/');
      app.listen(8008);
      ResolveModule.modulecache['foo'] = Foo;
      ResolveModule.modulecache['bar'] = Bar;
      ResolveModule.modulecache['dfoo'] = DFoo;
      ResolveModule.modulecache['directbar'] = DirectBar;
      ResolveModule.modulecache['hashbar'] = HashBar;
      return DB.createDatabases(['foo', 'bar', 'dfoo', 'directbar', 'hashbar']).then(function() {
        console.log('++++++++++++++++++++++++++++++++++++spec dbs created');
        messageRouter.open();
        return done();
      });
    });
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
    it('should create an object that has a direct reference and be able to set and update that reference', function(done) {
      return new Foo({
        id: '12345'
      }).then(function(o) {
        return o.serialize().then(function() {
          return new Bar().then(function(bar) {
            var umsg;
            bar.theFoo = '12345';
            umsg = {
              obj: bar,
              user: {
                isAdmin: true
              },
              replyFunc: function(ureply) {
                expect(ureply.status).to.equal('SUCCESS');
                return done();
              }
            };
            return messageRouter.objectManager._updateObject(umsg);
          });
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
    it('should be able to persist newly added hashtable references and still have them after serializing and reloading from record', function(done) {
      return new Bar(record2).then(function(bar) {
        OStore.storeObject(bar);
        return new Foo(f4record).then(function(foo) {
          OStore.storeObject(foo);
          bar.footable[foo.name] = foo;
          return foo.serialize().then(function() {
            return bar.serialize().then(function() {
              return DB.get('Bar', [4711]).then(function(newbars) {
                var newbar;
                newbar = newbars[0];
                expect(newbar.footable).to.exist;
                return setTimeout(function() {}, done(), 400);
              });
            });
          });
        });
      });
    });
    it('should be able to use custom properties for hashtable keys', function() {
      var record222;
      record222 = {
        _rev: 71299900099,
        id: 174711,
        type: 'Bar',
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
    it('should resolve cold array references to objects not yet in ostore, only in db', function(done) {
      var foo;
      foo = {
        id: '99008877',
        name: 'fooname',
        value: 'name',
        "default": 'foo',
        type: 'Foo'
      };
      return DB.set('Foo', foo, function(sres) {
        var bar;
        bar = {
          type: 'Bar',
          id: '444174711',
          name: 'BAR xyzzy',
          theFoo: '',
          foos: ['99008877']
        };
        return DB.set('Bar', bar, function(bres) {
          return messageRouter.objectManager.getObjectPullThrough('444174711', 'Bar').then(function(barobj) {
            expect(barobj.foos.length).to.equal(1);
            return done();
          });
        });
      });
    });
    it('should resolve multiple cold array references to objects not yet in ostore, only in db', function(done) {
      var foo, foo2;
      foo = {
        id: '11008877',
        name: 'fooname',
        value: 'name',
        "default": 'foo',
        type: 'Foo'
      };
      foo2 = {
        id: '77778877',
        name: 'fooname',
        value: 'name2',
        "default": 'foo2',
        type: 'Foo'
      };
      return DB.set('Foo', foo, function(sres) {
        return DB.set('Foo', foo2, function(sres2) {
          var bar;
          bar = {
            type: 'Bar',
            id: 'foobarbaz',
            name: 'ANOTHER BAR xyzzyqq',
            theFoo: '',
            foos: ['11008877', '77778877']
          };
          return DB.set('Bar', bar, function(bres) {
            return messageRouter.objectManager.getObjectPullThrough('foobarbaz', 'Bar').then(function(barobj) {
              expect(barobj.foos.length).to.equal(2);
              return done();
            });
          });
        });
      });
    });
    it('should have multiple cold array references to objects not yet in ostore, and get right amount of references in arrays of search results', function(done) {
      var foo, foo2;
      foo = {
        id: '21008877',
        name: 'fooname',
        value: 'namexxxx',
        "default": 'foox',
        type: 'Foo'
      };
      foo2 = {
        id: '27778877',
        name: 'fooname',
        value: 'nameyyyy',
        "default": 'fooy',
        type: 'Foo'
      };
      return DB.set('Foo', foo, function(sres) {
        return DB.set('Foo', foo2, function(sres2) {
          var bar;
          bar = {
            type: 'Bar',
            id: 'xyzzy17',
            name: 'YET ANOTHER BAR',
            theFoo: '',
            foos: ['21008877', '27778877']
          };
          return DB.set('Bar', bar, function(bres) {
            var msg;
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
    });
    it('should cold load an object with a large amount of references in arrays of search results', function(done) {
      var _x, count, foorefs, j, max, ref, results;
      foorefs = [];
      max = 29;
      count = max - 1;
      count++;
      results = [];
      for (_x = j = 0, ref = max; 0 <= ref ? j <= ref : j >= ref; _x = 0 <= ref ? ++j : --j) {
        results.push((function(x) {
          var foo;
          foo = {
            id: 'foo_' + x + '_21008877',
            name: 'fooname',
            value: 'name_' + x,
            type: 'Foo'
          };
          return DB.set('Foo', foo, function(sres) {
            var bar;
            foorefs.push(foo.id);
            if (--count === 0) {
              bar = {
                type: 'Bar',
                id: '4711xyzzy17',
                name: 'SON OF YET ANOTHER BAR',
                theFoo: '',
                foos: foorefs
              };
              return DB.set('Bar', bar, function(bres) {
                var msg;
                msg = {
                  type: 'Bar',
                  user: {
                    isAdmin: true
                  },
                  replyFunc: function(reply) {
                    return reply.payload.forEach(function(bb) {
                      if (bb.name === bar.name) {
                        expect(bb.foos.length).to.equal(foorefs.length);
                        return done();
                      }
                    });
                  }
                };
                return messageRouter.objectManager._listObjects(msg);
              });
            }
          });
        })(_x));
      }
      return results;
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
      return setTimeout(function() {
        return messageRouter.objectManager._listObjects(msg);
      }, 200);
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
        return dfoo.serialize().then(function() {
          var query;
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
        return dfoo.serialize().then(function() {
          var query;
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
    });
    it('should be able to search on a wildcard property', function(done) {
      var record8;
      record8 = {
        id: 'bbb456',
        type: 'DFoo',
        name: 'MehmetBolarsKolars'
      };
      ResolveModule.modulecache['DFoo'] = DFoo;
      return new DFoo(record8).then(function(dfoo) {
        return dfoo.serialize().then(function() {
          var query;
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
        return dfoo1.serialize().then(function() {
          return new DFoo(record10).then(function(dfoo2) {
            return dfoo2.serialize().then(function() {
              var query;
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
        return dfoo.serialize().then(function() {
          var query;
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
        return dfoo.serialize().then(function() {
          var query;
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
        return dfoo.serialize().then(function() {
          return DB.findMany('DFoo', 'id', 'b44rrb3356').then((function(_this) {
            return function(records) {
              expect(records.length).to.equal(1);
              return done();
            };
          })(this));
        });
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
          return foo.serialize().then(function() {
            var msg, umsg;
            umsg = {
              obj: {
                id: bar.id,
                foos: [foo.id]
              },
              user: {
                isAdmin: true
              },
              replyFunc: function(ureply) {}
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
    });
    it('should be able to resolve object graphs properly', function(done) {
      return messageRouter.objectManager.resolveReferences(record2, Bar.model).then(function(result) {
        return done();
      });
    });
    it('should be able to update scalars without trashing array references', function(done) {
      return new Bar().then(function(bar) {
        return new Foo().then(function(foo) {
          return foo.serialize().then(function() {
            bar.foos.push(foo);
            return bar.serialize().then(function() {
              var brecord;
              brecord = bar.toClient();
              brecord.name = 'Doctored Bar object';
              return messageRouter.objectManager.resolveReferences(brecord, Bar.model).then(function(result) {
                expect(result.foos.length).to.gt(0);
                return done();
              });
            });
          });
        });
      });
    });
    it('should be able to get correct array references to an object update subscriber', function(done) {
      return new Bar().then(function(bar) {
        return new Foo().then(function(foo) {
          return foo.serialize().then(function() {
            bar.foos.push(foo);
            return bar.serialize().then(function() {
              var brecord, msg, umsg;
              ClientEndpoints.registerEndpoint('fooclient', function(reply) {
                expect(reply.payload.foos[0]).to.equal(foo.id);
                return done();
              });
              msg = {
                type: 'Bar',
                client: 'fooclient',
                obj: {
                  id: bar.id,
                  type: 'Bar'
                },
                user: {
                  isAdmin: true
                },
                replyFunc: function(reply) {}
              };
              messageRouter.objectManager.onRegisterForUpdatesOn(msg);
              brecord = bar.toClient();
              brecord.name = '*** Extra Doctored Bar object';
              umsg = {
                obj: brecord,
                user: {
                  isAdmin: true
                },
                replyFunc: function(ureply) {}
              };
              return messageRouter.objectManager._updateObject(umsg);
            });
          });
        });
      });
    });
    it('should be able to get population change callbacks', function(done) {
      var msg;
      ClientEndpoints.registerEndpoint('updateclient', function(reply) {
        expect(reply.payload).to.exist;
        return done();
      });
      msg = {
        type: 'Bar',
        client: 'updateclient',
        user: {
          isAdmin: true
        },
        replyFunc: function(reply) {
          return new Bar().then(function(bar) {});
        }
      };
      return messageRouter.objectManager.onRegisterForPopulationChanges(msg);
    });
    it('should be able call listcommands through HttpMethod', function(done) {
      return request.get('http://localhost:8008/api/?target=listcommands', function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    it('should be able to expose an object and access _listObject through HttpMethod', function(done) {
      messageRouter.objectManager.expose('Foo');
      return request.get('http://localhost:8008/api/?target=_listFoos', function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    it('should be able to restify an already exposed object and access /rest/Object through HttpMethod', function(done) {
      messageRouter.makeRESTful('Foo');
      return request.get('http://localhost:8008/rest/Foo', function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    it('should be able to access a restified object through /rest/Object/:id and HttpMethod', function(done) {
      return request.get('http://localhost:8008/rest/Foo/21008877', function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    it('should be able to update a restified object through put /rest/Object/:id and HttpMethod', function(done) {
      record = {
        id: 'f117',
        name: 'foobar'
      };
      return request.put({
        url: 'http://localhost:8008/rest/Foo/21008877',
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(record)
      }, function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    it('should be able to delete a restified object through delete /rest/Object/:id and HttpMethod', function(done) {
      return request["delete"]('http://localhost:8008/rest/Foo/21008877', function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    it('should be able to create a new restified object through post /rest/Object/:id and HttpMethod', function(done) {
      record = {
        id: 'f117',
        name: 'foobarbaz'
      };
      return request.post({
        url: 'http://localhost:8008/rest/Foo',
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(record)
      }, function(req, res, _body) {
        var body;
        body = JSON.parse(_body);
        expect(body.status).to.equal('SUCCESS');
        return done();
      });
    });
    return it('should be able to extend a model with a new property', function(done) {
      Foo.model.push({
        name: 'xyzzy4',
        "public": true,
        value: 'xyzzy',
        "default": 'quux'
      });
      return DB.extendSchemaIfNeeded(DB.DataStore, 'Foo').then((function(_this) {
        return function() {
          return DB.get('foo', ['f417']).then(function(res) {
            console.log('DB.get got back ' + res);
            console.dir(res);
            expect(res[0].xyzzy2).to.equal('quux');
            return done();
          });
        };
      })(this));
    });
  });

}).call(this);

//# sourceMappingURL=modelSpec.js.map
