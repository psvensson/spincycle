// Generated by CoffeeScript 1.8.0
(function() {
  var SuperModel, expect,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  expect = require('chai').expect;

  SuperModel = require('../lib/SuperModel');

  describe('SuperModel Tests', function() {
    var Bar, Foo, record, record2;
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
    Foo = (function(_super) {
      __extends(Foo, _super);

      Foo.type = 'Foo';

      Foo.model = [
        {
          name: 'name',
          value: 'name',
          "default": 'foo'
        }
      ];

      function Foo(record) {
        this.record = record != null ? record : {};
        return Foo.__super__.constructor.apply(this, arguments);
      }

      return Foo;

    })(SuperModel);
    Bar = (function(_super) {
      __extends(Bar, _super);

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
          ids: 'footable'
        }
      ];

      function Bar(record) {
        this.record = record != null ? record : {};
        return Bar.__super__.constructor.apply(this, arguments);
      }

      return Bar;

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
    it('should get back array of ids from array reference when creating record', function() {
      return new Foo(record).then(function(foo) {
        return new Bar(record2).then(function(bar) {
          var c, i, _i, _results;
          c = 10;
          _results = [];
          for (i = _i = 1; _i <= 10; i = ++_i) {
            _results.push(new Foo().then(function(foo) {
              var rv;
              bar.foos.push(foo);
              if (--c === 0) {
                rv = bar.getRecord();
                return expect(rv.foos.length).to.be(10);
              }
            }));
          }
          return _results;
        });
      });
    });
    return it('should filter record properties to only show those that are public when calling toClient', function() {
      return new Bar(record2).then(function(bar) {
        var rv;
        rv = bar.toClient();
        expect(rv.footable).to.not.exist;
        return expect(rv.name).to.exist;
      });
    });
  });

}).call(this);

//# sourceMappingURL=modelSpec.js.map
