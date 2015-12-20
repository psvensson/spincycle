expect = require('chai').expect
SuperModel = require('../lib/SuperModel')
DB = require('../lib/DB')
OStore = require('../lib/OStore')

describe 'Spincycle Model Tests', ->

  before (done)->
    console.log ' ------------------------------------- before called'
    DB.createDatabases(['foo','Level','Zone','Game','Tile','Entity','Player']).then () ->
    console.log '++++++++++++++++++++++++++++++++++++spec dbs created'
    done()

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
      {name: 'theFoo', value: 'theFoo', type: 'Foo' }
      {name: 'foos', public: true, array: true, ids: 'foos'}
      {name: 'footable', hashtable: true, ids: 'footable', type: 'Foo'}
    ]
    constructor: (@record={}) ->
      return super

  class Fooznaz extends SuperModel
    @type = 'Fooznaz'
    @model=
      [
        {name: 'name', value: 'name', default:'fooznaz', public: true}
        {name: 'things', ids: 'things', array: true, type: 'Bar', public: true}
      ]
    constructor:(@record={})->
      return super

  #-----------------------------------------------------------------------

  postCreateState = -1

  @record3 =
    id:42
    name: 'xyzzy'
    shoesize: 42

  @record4=
    id:667
    name: 'Neihgbor of the beast'
    hatsize: 42

  @record5=
    id:9
    name: 'Neihgbor of the beast'
    shirtsize: 42

  class Baz extends SuperModel
    @model=
    [
      {name: 'name', value: 'name', default:'baz'}
      {name: 'shoesize', value: 'shoesize', default:'-1'}
    ]
    constructor: (@record={}) ->
      #console.log '      Baz constructor'
      postCreateState = 3
      return super

  class Quux extends SuperModel
    @model=
    [
      {name: 'name', value: 'name', default:'baz'}
      {name: 'hatsize', value: 'hatsize', default:'0'}
    ]
    constructor: (@record={}) ->
      #console.log '  Quux constructor'
      postCreateState = 2
      return super

    postCreate: (q) =>
      #console.log '    Quux postcreate. Creating new Baz manually'
      postCreateState = 1
      new Baz(@record3).then (baz) =>
        postCreateState = 4
        #console.log '    Quux post-Baz creation'
        q.resolve(@)

  class Ezra extends SuperModel
    @model=
      [
        {name: 'name', value: 'name', default:'baz'}
        {name: 'shirtsize', value: 'shirtsize', default:'7'}
        {name: 'thequux', value: 'thequux', type:'Quux'}
      ]
    constructor: (@record={}) ->
      #console.log 'Ezra constructor '
      postCreateState = 0
      return super

    postCreate: (q) =>
      #console.log '  Ezra postcreate. Creating new Quux manually'
      postCreateStatee = 1
      new Quux(@record4).then (quux) =>
        @thequux = quux
        postCreateState = 5
        #console.log '  Ezra post-Quux creation'
        q.resolve(@)

  #-------------------------------------------------------------------------

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

  it 'should be able to persist newly added hashtable references and still have them after serializing and reloading from record', ()->
    new Bar(record2).then (bar) ->
      new Foo(record).then (foo) ->
        bar.footable[foo.name] = foo
        foo.serialize()
        bar.serialize()
        DB.get('Bar', [4711]).then (newbars) ->
          newbar = newbars[0]
          #console.dir newbar
          expect(newbar.footable).to.exist

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

  it 'should call postCreate, when defined, in serial order down the references', ()->
    new Ezra(@record5).then (ezra) ->
      expect(postCreateState).to.equal(5)

  it 'should retain hashtable key name and values after persistence', ()->
    new Foo(record).then (foo) ->
      new Bar(record2).then (bar) ->
        bar.serialize().then () ->
          DB.get('Bar', [4711]).then (bar_records)->
            bar_record = bar_records[0]
            new Bar(bar_record).then (newbar)->
              same = false
              keys1 = []
              keys2 = []
              vals1 = []
              vals2 = []
              for k,v of newbar.footable
                keys1.push k
                vals1.push v
              for kk,vv of bar.footable
                keys2.push k
                vals2.push v
              for k,i in keys1
                if keys1[i] and keys1[i] != keys2[i] then same = false else same = true
                if vals1[i] and vals1[i] != vals2[i] then same = false else same = true
              expect(same).to.equal(true)

  it 'should filter out crap values in arrays when updating', ()->
    new Fooznaz().then (fz) ->
      record = fz.toClient()
      record.things.push null
      record.things.push "null"
      record.things.push "undefined"
      record.things.push undefined
      new Fooznaz(record).then (fz2)->
        expect(fz2.things.length).to.equal(0)

  it 'should only end one update even when storeObject is called multiple times on short notice', (done)->
    count = 0
    new Foo(record).then (foo) ->
      OStore.storeObject(foo)
      OStore.addListenerFor(record.id, record.type, ()->
        count++
        #console.log 'reply for updates on object '+foo.id+', count = '+count
      )
      foo.name = 'foo1'
      OStore.storeObject(foo)
      foo.name = 'foo2'
      OStore.storeObject(foo)
      setTimeout(()->
        expect(count).to.equal(1)
        done()
      ,150)