// Generated by CoffeeScript 1.9.1
(function() {
  var DB, SuperModel, expect,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  expect = require('chai').expect;

  SuperModel = require('../lib/SuperModel');

  DB = require('../lib/DB');

  DB.createDatabases(['foo', 'Level', 'Zone', 'Game', 'Tile', 'Entity', 'Player']).then(function() {
    return console.log('++++++++++++++++++++++++++++++++++++spec dbs created');
  });

  describe('Spincycle Model Tests', function() {
    var Bar, Baz, Ezra, Foo, Fooznaz, Quux, postCreateState, record, record2, record3, record4, record5;
    before(function(done) {
      return console.log(' ------------------------------------- before called');
    });
    record = {
      _rev: 10101020202030303404,
      id: 17,
      name: 'foo'
    };
    record2 = {
      _rev: 77788877788899900099,
      id: 4711,
      name: 'xyzzy',
      theFoo: [17],
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
          ids: 'foos'
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
    postCreateState = -1;
    record3 = {
      id: 42,
      name: 'xyzzy',
      shoesize: 42
    };
    record4 = {
      id: 667,
      name: 'Neihgbor of the beast',
      hatsize: 42
    };
    record5 = {
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
        return new Baz(record3).then((function(_this) {
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
        return new Quux(record4).then((function(_this) {
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
      return new Foo(record).then(function(o) {
        var rv;
        rv = o.getRecord();
        return expect(rv.name).to.equal(record.name);
      });
    });
    it('should get resolve direct reference values from record', function() {
      return new Foo(record).then(function(foo) {
        return new Bar(record2).then(function(bar) {
          return expect(bar.theFoo).to.exist;
        });
      });
    });
    it('should get back id from direct reference when creating record', function() {
      return new Foo(record).then(function(foo) {
        return new Bar(record2).then(function(bar) {
          var rv;
          rv = bar.getRecord();
          return expect(rv.theFoo).to.equal(17);
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
        return new Foo(record).then(function(foo) {
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
    it('should get back array of ids from array reference when creating record', function() {
      return new Foo(record).then(function(foo) {
        return new Bar(record2).then(function(bar) {
          var c, i, j, results;
          c = 10;
          results = [];
          for (i = j = 1; j <= 10; i = ++j) {
            results.push(new Foo().then(function(foo) {
              var rv;
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
      return new Ezra(record5).then(function(ezra) {
        return expect(postCreateState).to.equal(5);
      });
    });
    it('should retain hashtable key name and values after persistence', function() {
      return new Foo(record).then(function(foo) {
        return new Bar(record2).then(function(bar) {
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
    return it('should filter out crap values in arrays when updating', function() {
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
  });

}).call(this);

//# sourceMappingURL=modelSpec.js.map
