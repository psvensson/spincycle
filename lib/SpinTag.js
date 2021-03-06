// Generated by CoffeeScript 1.9.3
(function() {
  var SpinTag, SuperModel, all, defer,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  SuperModel = require('./SuperModel');

  defer = require('node-promise').defer;

  all = require('node-promise').allOrNone;

  SpinTag = (function(superClass) {
    extend(SpinTag, superClass);

    SpinTag.type = 'SpinTag';

    SpinTag.model = [
      {
        name: 'name',
        "public": true,
        value: 'name',
        "default": 'foo'
      }, {
        name: 'modelRef',
        "public": true,
        value: 'modelRef'
      }, {
        name: 'modelType',
        "public": true,
        value: 'modelType'
      }
    ];

    function SpinTag(record) {
      this.record = record != null ? record : {};
      this.postCreate = bind(this.postCreate, this);
      return SpinTag.__super__.constructor.apply(this, arguments);
    }

    SpinTag.prototype.postCreate = function(q) {
      return q.resolve(this);
    };

    return SpinTag;

  })(SuperModel);

  module.exports = SpinTag;

}).call(this);

//# sourceMappingURL=SpinTag.js.map
