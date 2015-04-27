expect = require('chai').expect
SuperModel = require('../lib/SuperModel')
describe 'SuperModel Tests', ->
  record =
    _rev: 10101020202030303404
    id: 17
    name: 'foo'

  record2 =
    _rev: 77788877788899900099
    id: 4711
    name: 'xyzzy'
    theFoo: [17]
    foos: [17]
    footable: [17]

  class Foo extends SuperModel
    @type = 'Foo'
    @model=
    [
      {name: 'name', value: 'name', default:'foo'}
    ]
    constructor:(@record={})->
      return super

  class Bar extends SuperModel
    @type = 'Bar'
    @model=
    [
      {name: 'name', public: true, value: 'name', default: 'yohoo'}
      {name: 'theFoo', ids: 'theFoo' }
      {name: 'foos', public: true, array: true, ids: 'foos'}
      {name: 'footable', hashtable: true, ids: 'footable'}
    ]
    constructor: (@record={}) ->
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
      new Bar(record2).then (bar) ->
        #console.dir bar
        expect(bar.theFoo).to.exist

  it 'should get back id from direct reference when creating record', ()->
    new Foo(record).then (foo) ->
      new Bar(record2).then (bar) ->
        rv = bar.getRecord()
        expect(rv.theFoo).to.equal(17)

  it 'should be able to create a hashtable property from record', ()->
    new Bar(record2).then (bar) ->
      #console.dir bar
      expect(bar.footable).to.exist

  it 'should get back array of ids from array reference when creating record', ()->
    new Foo(record).then (foo) ->
      new Bar(record2).then (bar) ->
        c = 10
        for i in [1..10]
          new Foo().then (foo) ->
            bar.foos.push(foo)
            if --c == 0
              rv = bar.getRecord()
              #console.dir rv
              expect(rv.foos.length).to.be(10)

  it 'should filter record properties to only show those that are public when calling toClient', ()->
    new Bar(record2).then (bar) ->
      rv = bar.toClient()
      #console.dir rv
      expect(rv.footable).to.not.exist
      expect(rv.name).to.exist