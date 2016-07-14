expect          = require('chai').expect
SuperModel      = require('../lib/SuperModel')
ResolveModule   = require('../lib/ResolveModule')
DB              = require('../lib/DB')
OStore          = require('../lib/OStore')

AuthenticationManager = require('../example/AuthenticationManager')
express         = require("express")
app             = express()
SpinCycle       = require('../lib/MessageRouter')
ClientEndpoints  = require('../lib/ClientEndpoints')

describe 'Spincycle Model Tests', ->

  authMgr = undefined
  messageRouter = undefined

  before (done)->
    console.log '------------------------------------- before called'
    DB.createDatabases(['foo','bar','dfoo','directbar','hashbar']).then () ->
      console.log '++++++++++++++++++++++++++++++++++++spec dbs created'
      authMgr         = new AuthenticationManager()
      messageRouter   = new SpinCycle(authMgr, null, 10)
      messageRouter.open()
      done()

  record =
    _rev: 99101020202030303404
    id: 17
    name: 'foo'

  f1record =
    _rev: 'f10101020202030303404'
    id: 'f117'
    name: 'foo'

  f2record =
    _rev: 'f20101020202030303404'
    id: 'f217'
    name: 'foo'

  f3record =
    _rev: 'f30101020202030303404'
    id: 'f317'
    name: 'foo'

  f4record =
    _rev: 'f40101020202030303404'
    id: 'f417'
    name: 'foo'

  f5record =
    _rev: 'f50101020202030303404'
    id: 'f517'
    name: 'foo'

  record2 =
    _rev: 77788877788899900099
    id: 4711
    name: 'xyzzy'
    theFoo: 17
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

  ResolveModule.modulecache['Foo'] = Foo

  class DFoo extends SuperModel
    @type = 'DFoo'
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
      {name: 'foos', public: true, array: true, ids: 'foos', type: 'Foo'}
      {name: 'footable', hashtable: true, ids: 'footable', type: 'Foo'}
    ]
    constructor: (@record={}) ->
      return super

  class HashBar extends SuperModel
    @type = 'HashBar'
    @model=
      [
        {name: 'name', public: true, value: 'name', default: 'yohoo'}
        {name: 'theFoo', value: 'theFoo', type: 'Foo' }
        {name: 'foos', public: true, array: true, ids: 'foos'}
        {name: 'footable', hashtable: true, ids: 'footable', type: 'Foo', keyproperty: 'id'}
      ]
    constructor: (@record={}) ->
      return super


  ResolveModule.modulecache['Bar'] = Bar
  ResolveModule.modulecache['HashBar'] = HashBar

  class Fooznaz extends SuperModel
    @type = 'Fooznaz'
    @model=
      [
        {name: 'name', value: 'name', default:'fooznaz', public: true}
        {name: 'things', ids: 'things', array: true, type: 'Bar', public: true}
      ]
    constructor:(@record={})->
      return super

  class DirectBar extends SuperModel
    @type = 'DirectBar'
    @model=
      [
        {name: 'name', public: true, value: 'name', default: 'directyohoo'}
        {name: 'theFoo', value: 'theFoo', type: 'DFoo', storedirectly: true }
        {name: 'foos', public: true, type: 'DFoo', array: true, ids: 'foos', storedirectly: true}
        {name: 'footable', hashtable: true, ids: 'footable', type: 'DFoo', storedirectly: true}
      ]
    constructor: (@record={}) ->
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
    new Foo(f1record).then (o) ->
      rv = o.getRecord()
      expect(rv.name).to.equal(record.name)

  it 'should get resolve direct reference values from record', ()->
    new Foo(f2record).then (foo) ->
      new Bar(record2).then (bar) ->
        #console.dir bar
        expect(bar.theFoo).to.exist

  it 'should get back id from direct reference when creating record', ()->
    new Foo(f1record).then (foo) ->
      OStore.storeObject(foo)
      new Bar(record2).then (bar) ->
        rv = bar.getRecord()
        expect(rv.theFoo).to.equal(record.id)

  it 'should be able to create a hashtable property from record', ()->
    new Bar(record2).then (bar) ->
      #console.dir bar
      expect(bar.footable).to.exist

  it 'should be able to persist newly added hashtable references and still have them after serializing and reloading from record', (done)->
    new Bar(record2).then (bar) ->
      OStore.storeObject(bar)
      new Foo(f4record).then (foo) ->
        OStore.storeObject(foo)
        bar.footable[foo.name] = foo
        foo.serialize().then ()->
          bar.serialize().then ()->
            DB.get('Bar', [4711]).then (newbars) ->
              newbar = newbars[0]
              #console.dir newbar
              expect(newbar.footable).to.exist
              setTimeout(
                ()->
                done()
              ,400
              )

  it 'should be able to use custom properties for hashtable keys', ()->
    record222 =
      _rev: 71299900099
      id: 174711
      name: 'BAR xyzzy'
      theFoo: 17
      foos: [17]
    new HashBar(record222).then (bar) ->
      OStore.storeObject(bar)
      new Foo(f4record).then (foo) ->
        OStore.storeObject(foo)
        bar.footable[foo.id] = foo
        foo.serialize()
        bar.serialize()
        DB.get('HashBar', [174711]).then (newbars) ->
          newbar = newbars[0]
          new HashBar(newbar).then (nbobj) ->
            expect(nbobj.footable[foo.id]).to.equal(foo)

  it 'should get back array of ids from array reference when creating record', ()->
    new Foo(f5record).then (afoo) ->
      OStore.storeObject(afoo)
      new Bar(record2).then (bar) ->
        OStore.storeObject(bar)
        c = 10
        for i in [1..10]
          new Foo().then (foo) ->
            OStore.storeObject(foo)
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
      OStore.storeObject(foo)
      new Bar(record2).then (bar) ->
        OStore.storeObject(bar)
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

  it 'should always return an array from listObjects', (done)->
    msg =
      type: 'Foo'
      user:
        isAdmin: true
      replyFunc: (reply)->
        console.log '--------------testing if listObject always returns an array'
        #console.dir reply
        expect(reply.payload.length).to.gt(0)
        done()
    setTimeout(
      ()->
        messageRouter.objectManager._listObjects(msg)
      ,400
    )




  it 'should include whole objects when using storedirectly', (done)->
    #console.log '------------------------------------------------trying to make a foo'
    record7=
      id: 'aaa3'
      type: 'DFoo'
      name: 'BolarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    ResolveModule.modulecache['DirectBar'] = DirectBar
    new DFoo(record7).then (dfoo) ->
      #console.dir(dfoo)
      #console.log 'trying to make a dbar'
      new DirectBar().then (dbar) ->
        dbar.theFoo = dfoo
        dbar.foos.push dfoo
        dbar.footable[dfoo.name] = dfoo
        #console.log 'trying to serialize dbar'
        dbar.serialize().then () ->
          #console.log 'trying to recreate dbar'
          DB.get('DirectBar', [dbar.id]).then (dbar_records)->
            #console.log 'created new directbar!'
            #console.dir dbar_records
            bar_record = dbar_records[0]
            new DirectBar(bar_record).then (newdbar)->
              #console.log 'new direct bar-----------------------------'
              #console.dir newdbar
              expect(newdbar.theFoo.name).to.equal(dfoo.name)
              done()


  it 'should be able to do a search on a property', (done)->
    record7=
      id: 'bbb456'
      type: 'DFoo'
      name: 'BolarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record7).then (dfoo) ->
      dfoo.serialize().then ()->
        query = {sort:'name', property: 'name', value: 'BolarsKolars'}
        DB.findQuery('DFoo', query).then (records) =>
          expect(records.length).to.equal(1)
          done()


  it 'should not get any results when searching on the wrong property', (done)->
    record7=
      id: 'bbb456'
      type: 'DFoo'
      name: 'BolarsKolars2'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record7).then (dfoo) ->
      dfoo.serialize().then ()->
        query = {sort:'name', property: 'id', value: 'BolarsKolars2'}
        DB.findQuery('DFoo', query).then (records) =>
          expect(records.length).to.equal(0)
          done()


  it 'should be able to search on a wildcard property', (done)->
    record8=
      id: 'bbb456'
      type: 'DFoo'
      name: 'MehmetBolarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record8).then (dfoo) ->
      dfoo.serialize().then ()->
        query = {sort:'name', property: 'name', value: 'Meh', wildcard: true}
        DB.findQuery('DFoo', query).then (records) =>
          expect(records.length).to.equal(1)
          done()


  it 'should be able to get two hits on a wildcard property', (done)->
    record9=
      id: 'bbb4567'
      type: 'DFoo'
      name: 'Myfflan sKolars'
    record10=
      id: 'bbb45677'
      type: 'DFoo'
      name: 'MyhmetBolarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record9).then (dfoo1) ->
      dfoo1.serialize().then ()->
        new DFoo(record10).then (dfoo2) ->
          dfoo2.serialize().then ()->
            query = {sort:'name', property: 'name', value: 'My', wildcard: true}
            DB.findQuery('DFoo', query).then (records) =>
              expect(records.length).to.equal(2)
              done()

  it 'should not bomb on searches with wildcard characters', (done)->
    record11=
      id: 'bb3356'
      type: 'DFoo'
      name: 'ArnelarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record11).then (dfoo) ->
      dfoo.serialize().then ()->
        query = {sort:'name', property: 'name', value: 'Arne*', wildcard: true}
        DB.findQuery('DFoo', query).then (records) =>
          expect(records.length).to.equal(1)
          done()

  it 'should not bomb on specific searches with faulty values', (done)->
    record12=
      id: 'b44b3356'
      type: 'DFoo'
      name: 'MixnelarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record12).then (dfoo) ->
      dfoo.serialize().then ()->
        query = {sort:'name', property: 'id', value: '[Object object]'}
        DB.findQuery('DFoo', query).then (records) =>
          expect(records.length).to.equal(0)
          done()

  it 'should be able to do specific searches', (done)->
    record12=
      id: 'b44rrb3356'
      type: 'DFoo'
      name: 'AlohaMixnelarsKolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record12).then (dfoo) ->
      dfoo.serialize().then ()->
        DB.findMany('DFoo', 'id', 'b44rrb3356').then (records) =>
          #console.log '--------------------- specific search recods '
          #console.dir records
          expect(records.length).to.equal(1)
          done()

  it 'should get an error message when sending too many requests per second', (done)->
    user = { name: 'foo', id:17}
    count = 12
    failure = false
    for i in [0..12]
      msg =
        target: 'listcommands'
        user: user
        replyFunc: (reply)->
          console.log 'reply was '+reply.info
          #console.dir reply
          if reply.status == 'NOT_ALLOWED' then failure = true
          if --count == 0
            expect(failure).to.equal(true)
            done()
      messageRouter.routeMessage(msg)

  it 'should update an array on an object with a reference and have that reference be present in the array when searching for the object', (done)->
    new Bar().then (bar) ->
      bar.serialize()
      new Foo().then (foo) ->
        foo.serialize().then ()->
          umsg =
            obj:
              id: bar.id
              foos: [foo.id]
            user:
              isAdmin: true
            replyFunc: (ureply)->
              console.log 'update reply was'
              #console.dir(ureply)
          messageRouter.objectManager._updateObject(umsg)
          msg =
            type: 'Bar'
            user:
              isAdmin: true
            replyFunc: (reply)->
              #reply.payload.forEach (obj) -> if obj.id == bar.id then console.dir obj
              expect(reply.payload.length).to.gt(0)
              done()
          messageRouter.objectManager._listObjects(msg)

  it 'should be able to resolve object graphs properly', (done)->
    messageRouter.objectManager.resolveReferences(record2, Bar.model).then (result)->
      #console.log '---------------- resolvereferences results ------------------'
      #console.dir result
      done()

  it 'should be able to update scalars without trashing array references', (done)->
    new Bar().then (bar) ->
      new Foo().then (foo) ->
        foo.serialize().then ()->
          bar.foos.push foo
          bar.serialize().then ()->
            brecord = bar.toClient()
            brecord.name = 'Doctored Bar object'
            messageRouter.objectManager.resolveReferences(brecord, Bar.model).then (result)->
              #console.log '---------------- resolvereferences results ------------------'
              #console.dir result
              expect(result.foos.length).to.gt(0)
              done()

  it 'should be able to get correct array references to an object update subscriber', (done)->
    new Bar().then (bar) ->
      new Foo().then (foo) ->
        foo.serialize().then ()->
          bar.foos.push foo
          bar.serialize().then ()->
            #console.log '------------------------- initial bar object'
            #console.dir bar

            ClientEndpoints.registerEndpoint 'fooclient',(reply)->
              #console.log '--__--__--__ object update __--__--__--'
              #console.dir reply
              expect(reply.payload.foos[0]).to.equal(foo.id)
              done()

            msg =
              type: 'Bar'
              client: 'fooclient'
              obj:{id: bar.id, type: 'Bar'}
              user:
                isAdmin: true
              replyFunc: (reply)->

            messageRouter.objectManager.onRegisterForUpdatesOn(msg)

            brecord = bar.toClient()
            brecord.name = 'Extra Doctored Bar object'
            umsg =
              obj: brecord
              user:
                isAdmin: true
              replyFunc: (ureply)->

            messageRouter.objectManager._updateObject(umsg)

  it 'should be able to get population change callbacks', (done)->
    ClientEndpoints.registerEndpoint 'updateclient',(reply)->
      console.log '--__--__--__  update client got population change __--__--__--'
      console.dir reply
      expect(reply.payload).to.exist
      done()

    msg =
      type: 'Bar'
      client: 'updateclient'
      user:
        isAdmin: true
      replyFunc: (reply)->
        new Bar().then (bar) ->
          console.log 'bar created. waiting for population change'

    messageRouter.objectManager.onRegisterForPopulationChanges(msg)

