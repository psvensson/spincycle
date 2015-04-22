expect = require('chai').expect
SuperModel = require('../lib/SuperModel')
describe 'SuperModel', ->
  record =
    _rev: 10101020202030303404
    id: 17
    name: 'foo'

  class Foo extends SuperModel
    constructor:(@record={})->
      @type = 'Foo'
      @resolvearr=
      [
        {name: 'name', value: 'foo'}
      ]
      return super

  class Bar extends SuperModel
    constructor: (@record={}) ->
      @type = 'Bar'
      @resolvearr=
      [
        {name: 'name', value: 'yohoo'}
        {name: 'theFoo', ids: [17] }
      ]
      return super

  it 'should retain _rev property from record', ()->
    new Foo(record).then (o) ->
      expect(o._rev).to.equal(record._rev)

  it 'should get back basic values when creating record', ()->
    new Foo(record).then (o) ->
      rv = o.getRecord()
      expect(rv.name).to.equal(record.name)

  it 'should get resolve direct reference values from record', ()->
    new Foo(record).then (foo) ->
      new Bar().then (bar) ->
        #console.dir bar
        expect(bar.theFoo).to.exist

  it 'should get back id from direct reference when creating record', ()->
    new Foo(record).then (foo) ->
      new Bar().then (bar) ->
        rv = bar.getRecord()
        expect(rv.theFoo).to.equal(17)