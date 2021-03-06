expect          = require('chai').expect
SuperModel      = require('../lib/SuperModel')
ResolveModule   = require('../lib/ResolveModule')
DB              = require('../lib/DB')
OStore          = require('../lib/OStore')
request         = require('request')
unirest         = require('unirest')
AuthenticationManager = require('../example/AuthenticationManager')
express         = require("express")
bodyParser      = require("body-parser")
app             = express()

app.use(bodyParser.urlencoded({
  extended: true
}))
app.use(bodyParser.json())

app.use(bodyParser());


SpinCycle       = require('../lib/MessageRouter')
ClientEndpoints  = require('../lib/ClientEndpoints')

describe 'Spincycle Model Tests', ->
  this.timeout(500000);

  authMgr = undefined
  messageRouter = undefined
  httpMethod = undefined

  record =
    _rev: 99101020202030303404
    id: '17'
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
    id: '4711'
    name: 'xyzzy'
    theFoo: '17'
    foos: ['17']
    footable: ['17']

  class Foo extends SuperModel
    @type = 'Foo'
    @model=
      [
        {name: 'name', value: 'name', default:'foo', public: true}
      ]
    constructor:(@record={})->
      return super

  ResolveModule.modulecache['Foo'] = Foo

  class DFoo extends SuperModel
    @type = 'DFoo'
    @model=
      [
        {name: 'name', value: 'name', default:'foo'}
        {name: 'someProp', value: 'someProp', default:'xyzzy'}
      ]
    constructor:(@record={})->
      return super

  class Bar extends SuperModel
    @type = 'Bar'
    @model=
      [
        {name: 'name', public: true, value: 'name', default: 'yohoo'}
        {name: 'theFoo', value: 'theFoo', public: true, type: 'Foo' }
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
        {name: 'foos', public: true, array: true, ids: 'foos', type: 'Foo'}
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

  class VeryBar extends SuperModel
    @type = 'VeryBar'
    @model=
      [
        {name: 'name', public: true, value: 'name', default: 'directyohoo'}
        {name: 'theFoo', value: 'theFoo', type: 'DFoo', storedirectly: true }
        {name: 'foos', public: true, type: 'Foo', array: true, ids: 'foos'}
        {name: 'bars', public: true, type: 'Bar', array: true, ids: 'bars'}
        {name: 'dfoos', public: true, type: 'DFoo', array: true, ids: 'dfoos'}
      ]
    constructor: (@record={}) ->
      return super

  before (done)->
    #console.log '------------------------------------- before called'
    authMgr         = new AuthenticationManager()
    messageRouter = undefined
    #messageRouter   = new SpinCycle(authMgr, null, 10, app, 'mongodb')
    new SpinCycle(authMgr, null, 10, app, 'rethinkdb').then (mr)=>
      messageRouter = mr
      """
      options = {
        api_key: "8a8c68a6193ac76c501f49b08e3a105f",
        app_key: "1b9c45f6638bd01d8ef4c474ec87e15487f644a2",
        #api_version: 'v1.5',
        api_host: 'app.datadoghq.com'
      }
      messageRouter   = new SpinCycle(authMgr, null, 10, app, 'google', options)
      """
      httpMethod = new SpinCycle.HttpMethod(messageRouter, app, '/api/')
      app.listen(8008)
      ResolveModule.modulecache['foo'] = Foo
      ResolveModule.modulecache['bar'] = Bar
      ResolveModule.modulecache['dfoo'] = DFoo
      ResolveModule.modulecache['directbar'] = DirectBar
      ResolveModule.modulecache['verybar'] = VeryBar
      ResolveModule.modulecache['hashbar'] = HashBar
      ResolveModule.modulecache['fooznaz'] = Fooznaz
      DB.createDatabases(['foo','bar','dfoo','directbar','hashbar','fooznaz', 'verybar']).then () ->
        console.log '++++++++++++++++++++++++++++++++++++spec dbs created'
        messageRouter.open()
        done()
    return false


  #-----------------------------------------------------------------------

  postCreateState = -1

  @record3 =
    id:'42'
    name: 'xyzzy'
    shoesize: '42'

  @record4=
    id:'667'
    name: 'Neihgbor of the beast'
    hatsize: '42'

  @record5=
    id:'9'
    name: 'Neihgbor of the beast'
    shirtsize: '42'


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

  it 'should not spill over old array contents from one object creation to another', ()->
    new Bar().then (bar) ->
      bar.foos.push '123456789'
      bar.serialize().then ()->
        console.dir bar
        new Bar({name: 'a bar'}).then (bar2) ->
          console.dir bar2
          expect(bar2.foos[0]).to.not.exist

  it 'should create an object that has a direct reference and be able to set and update that reference', (done)->
    new Foo({id:'12345'}).then (o) ->
      #console.log 'got new foo'
      #console.dir o
      #console.log 'trying to serialize...'
      o.serialize().then ()->
        new Bar().then (bar) ->
          #console.log 'got new bar'
          #console.dir bar
          bar.theFoo = '12345'
          umsg =
            obj: bar.toClient()
            user:
              isAdmin: true
              email: 'foo@bar.com'
              name: 'Mr. Xyzzy'
            replyFunc: (ureply)->
              #console.log 'update reply was'
              #console.dir(ureply)
              expect(ureply.status).to.equal('SUCCESS')
              done()
          messageRouter.objectManager._updateObject(umsg)


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
            DB.get('Bar', ['4711']).then (newbars) ->
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
      id: '174711'
      type: 'Bar'
      name: 'BAR xyzzy'
      theFoo: '17'
      foos: ['17']
    new HashBar(record222).then (bar) ->
      OStore.storeObject(bar)
      new Foo(f4record).then (foo) ->
        OStore.storeObject(foo)
        bar.footable[foo.id] = foo
        foo.serialize()
        bar.serialize()
        DB.get('HashBar', ['174711']).then (newbars) ->
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
          DB.get('Bar', ['4711']).then (bar_records)->
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

  it 'should resolve cold array references to objects not yet in ostore, only in db', (done)->
    foo = {id: '99008877', name: 'fooname', value: 'name', default:'foo', type: 'Foo'}
    DB.set 'Foo', foo, (sres) ->
      bar =
        type: 'Bar'
        id: '444174711'
        name: 'BAR xyzzy'
        theFoo: ''
        foos: ['99008877']

      DB.set 'Bar', bar, (bres) ->
        messageRouter.objectManager.getObjectPullThrough('444174711', 'Bar').then (barobj)->
          expect(barobj.foos.length).to.equal(1)
          done()

  it 'should resolve multiple cold array references to objects not yet in ostore, only in db', (done)->
    console.log '--------------------------------------------------------------------- cold array test start'
    foo = {id: '11008877', name: 'fooname', value: 'name', default:'foo', type: 'Foo'}
    foo2 = {id: '77778877', name: 'fooname', value: 'name2', default:'foo2', type: 'Foo'}
    DB.set 'Foo', foo, (sres) ->
      DB.set 'Foo', foo2, (sres2) ->
        bar =
          type: 'Bar'
          id: 'foobarbaz'
          name: 'ANOTHER BAR xyzzyqq'
          theFoo: ''
          foos: ['11008877', '77778877']

        DB.set 'Bar', bar, (bres) ->
          messageRouter.objectManager.getObjectPullThrough('foobarbaz', 'Bar').then (barobj)->
            expect(barobj.foos.length).to.equal(2)
            done()

  it 'should have multiple cold array references to objects not yet in ostore, and get right amount of references in arrays of search results', (done)->
    console.log '--------------------------------------------------------------------- cold array test start 2'
    foo = {id: '21008877', name: 'fooname', value: 'namexxxx', default:'foox', type: 'Foo'}
    foo2 = {id: '27778877', name: 'fooname', value: 'nameyyyy', default:'fooy', type: 'Foo'}
    DB.set 'Foo', foo, (sres) ->
      DB.set 'Foo', foo2, (sres2) ->
        bar =
          type: 'Bar'
          id: 'xyzzy17'
          name: 'YET ANOTHER BAR'
          theFoo: ''
          foos: ['21008877', '27778877']

        DB.set 'Bar', bar, (bres) ->
          msg =
            type: 'Bar'
            user:
              isAdmin: true
            replyFunc: (reply)->
              expect(reply.payload.length).to.gt(0)
              done()

          messageRouter.objectManager._listObjects(msg)

  it 'should cold load an object with a large amount of references in arrays of search results', (done)->
    foorefs = []
    max = 29
    count = max-1
    count++
    for _x in [0..max]
      ((x)->
        foo = {id: 'foo_'+x+'_21008877', name: 'fooname', value: 'name_'+x, type: 'Foo'}
        DB.set 'Foo', foo, (sres) ->
          foorefs.push foo.id
          if --count == 0
            bar =
              type: 'Bar'
              id: '4711xyzzy17'
              name: 'SON OF YET ANOTHER BAR'
              theFoo: ''
              foos: foorefs

            DB.set 'Bar', bar, (bres) ->
              msg =
                type: 'Bar'
                user:
                  isAdmin: true
                replyFunc: (reply)->
                  reply.payload.forEach (bb)->
                    if bb.name == bar.name
                      expect(bb.foos.length).to.equal(foorefs.length)
                      done()

              messageRouter.objectManager._listObjects(msg)
      )(_x)

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
        #console.log '--------------testing if listObject always returns an array'
        #console.dir reply
        expect(reply.payload.length).to.gt(0)
        done()
    setTimeout(
      ()->
        messageRouter.objectManager._listObjects(msg)
      ,200
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

  it 'should be able to update sparse object with arrays', (done)->
    new Foo().then (foo) ->
      new DFoo().then (dfoo) ->
        new Bar().then (bar)->
          new VeryBar().then (vbar)->
            vbar.foos.push foo
            vbar.dfoos.push dfoo
            vbar.serialize()
            msg1 =
              type: 'VeryBar'
              id: vbar.id
              obj:
                id: vbar.id
                type: 'VeryBar'
              user:
                isAdmin: true
              replyFunc: (ureply)->
                #console.log 'get reply for verybar was'
                #console.dir(ureply)
                record = {id:vbar.id, type:'VeryBar',bars:[]}
                record.bars.push bar.id
                msg2 =
                  obj: record
                  user:
                    isAdmin: true
                  replyFunc: (ureply2)->
                    console.log 'update reply for verybar was'
                    console.dir ureply2
                    msg3 =
                      type: 'VeryBar'
                      id: vbar.id
                      obj:
                        id: vbar.id
                        type: 'VeryBar'
                      user:
                        isAdmin: true
                      replyFunc: (ureply3)->
                        console.log 'get again reply for verybar was'
                        console.dir(ureply3)
                        expect(ureply3.payload.foos.length).to.equal(1)
                        done()
                    messageRouter.objectManager._getObject(msg3)
                #console.log '--- sparse test updating object'
                messageRouter.objectManager._updateObject(msg2)
            messageRouter.objectManager._getObject(msg1)


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

  it 'should not get any hits when using part of a string value to search on a property, and not using wildcard', (done)->
    record7=
      id: 'bbb456'
      type: 'DFoo'
      name: 'aaaaabbbbb'
    new DFoo(record7).then (dfoo) ->
      dfoo.serialize().then ()->
        query = {sort:'name', property: 'name', value: 'aaaaa'}
        DB.findQuery('DFoo', query).then (records) =>
          console.dir records
          expect(records.length).to.equal(0)
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

  it 'should be able to get two hits on a specific property search', (done)->
    record9=
      id: 'bbb4567'
      type: 'DFoo'
      createdBy: 'a945872c-cd42-48e7-9d73-703df1e82f1c'
      name: 'fyffe sKolars'
    record10=
      id: 'bbb45677'
      type: 'DFoo'
      createdBy: 'a945872c-cd42-48e7-9d73-703df1e82f1c'
      name: 'affo Kolars'
    ResolveModule.modulecache['DFoo'] = DFoo
    new DFoo(record9).then (dfoo1) ->
      dfoo1.serialize().then ()->
        new DFoo(record10).then (dfoo2) ->
          dfoo2.serialize().then ()->
            query = {property: 'createdBy', value: 'a945872c-cd42-48e7-9d73-703df1e82f1c'}
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
          #console.log 'bomb query got back'
          #console.dir records
          expect(records.length).to.equal(0)
          done()

  it 'should be able to limit search results', (done)->
      query = {sort:'name', property: 'name', value: 'M', limit: 1, wildcard:true}
      DB.findQuery('DFoo', query).then (records) =>
        console.log 'limit query got back'
        console.dir records
        expect(records.length).to.equal(1)
        done()

  it 'should be able to limit all search results', (done)->
    query = {sort:'name', limit: 2}
    DB.all 'DFoo', query,(records) =>
      console.log 'limit query got back'
      console.dir records
      expect(records.length).to.equal(2)
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

  it 'should be able to do an ordered search', (done)->
    foorefs = []
    max = 10
    count = max-1
    count++
    for _x in [0..max]
      ((x)->
        foo = {id: 'order_foo_'+x, name: 'order_foo_'+x, value: 'name_'+x, type: 'Foo'}
        new Foo(foo).then (sres) ->
          sres.serialize().then ()->
            if --count == 0
              query = {sort:'createdBy', skip:0, limit:'10'}
              DB.all 'Foo', query, (records) =>
                console.log '---------------------orderBy search result'
                console.dir records
                done()
      )(_x)

  it 'should get an error message when sending too many requests per second', (done)->
    user = { name: 'foo', id:'17'}
    count = 12
    failure = false
    for i in [0..12]
      msg =
        target: 'listcommands'
        user: user
        replyFunc: (reply)->
          #console.log 'reply was '+reply.info
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
              type: 'Bar'
              foos: [foo.id]
            user:
              isAdmin: true
            replyFunc: (ureply)->
              console.log 'update reply was'
              console.dir(ureply)
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
            console.log '------------------------- initial bar object foos is '
            console.dir bar.foos

            ClientEndpoints.registerEndpoint 'fooclient',(reply)->
              console.log '--__--__--__ object update __--__--__--'
              console.dir reply
              expect(reply.payload.foos.length).to.equal(0)
              done()

            msg =
              type: 'Bar'
              client: 'fooclient'
              obj:{id: bar.id, type: 'Bar'}
              user:
                isAdmin: true
              replyFunc: (reply)->#console.log "we're listening to "+bar.id

            messageRouter.objectManager.onRegisterForUpdatesOn(msg)

            brecord = bar.toClient()
            brecord.name = '*** Extra Doctored Bar object'
            brecord.foos = []
            umsg =
              obj: brecord
              user:
                isAdmin: true
              replyFunc: (ureply)->

            messageRouter.objectManager._updateObject(umsg)

  it 'should be able to update an array reference with one less object reference', (done)->
    new Bar().then (bar) ->
      new Foo().then (foo) ->
        foo.serialize().then ()->
          new Foo().then (foo2) ->
            foo.serialize().then ()->
              bar.foos.push foo
              bar.foos.push foo2
              bar.serialize().then ()->
                #console.log '------------------------- initial bar object foos is '
                #console.dir bar.foos
                brecord = bar.toClient()
                brecord.name = '*** one less Doctored Bar object'
                brecord.foos = [foo2.id]
                umsg =
                  obj: brecord
                  user:
                    isAdmin: true
                  replyFunc: (ureply)->
                    console.log 'one less object update is '+ureply
                    console.dir ureply
                    msg1 =
                      type: 'Bar'
                      id: bar.id
                      obj:
                        id: bar.id
                        type: 'Bar'
                      user:
                        isAdmin: true
                      replyFunc: (ureply2)->
                        console.log 'one less after update _get is..'
                        console.dir ureply2
                        expect(ureply2.payload.foos.length).to.equal(1)
                        done()
                    messageRouter.objectManager._getObject(msg1)
                messageRouter.objectManager._updateObject(umsg)

  it 'should be able to get an object with all array references of that of the object in db', (done)->
    new Bar().then (bar) ->
      new Foo().then (foo) ->
        new Foo().then (foo2) ->
          foo.serialize().then ()->
            bar.foos.push foo
            bar.foos.push foo2
            bar.serialize().then ()->
              console.log '------------------------- initial bar object foos is '
              console.dir bar.foos

              msg =
                type: 'Bar'
                obj:{id: bar.id, type: 'Bar'}
                user:
                  isAdmin: true
                replyFunc: (reply)->
                  console.log '--__--__--__ object get result __--__--__--'
                  console.dir reply
                  expect(reply.payload.foos.length).to.equal(2)
                  done()

              messageRouter.objectManager._getObject(msg)
    return false


  it 'should be able to get population change callbacks on create', (done)->
    ClientEndpoints.registerEndpoint 'updateclient',(reply)->
      #console.log '--__--__--__  update client got population change __--__--__--'
      #console.dir reply
      expect(reply.payload.added).to.exist
      ClientEndpoints.removeEndpoint 'updateclient'
      done()

    msg =
      type: 'Bar'
      id:'11992299'
      client: 'updateclient'
      user:
        isAdmin: true
      replyFunc: (reply)->
        new Bar().then (bar) ->
          #console.log 'bar created. waiting for population change'

    messageRouter.objectManager.onRegisterForPopulationChanges(msg)

  it 'should be able to get population change callbacks on delete', (done)->
    ClientEndpoints.registerEndpoint 'updateclient2',(reply)->
      #console.log '--__--__--__  update client got population change __--__--__--'
      #console.dir reply
      expect(reply.payload.removed).to.exist
      ClientEndpoints.removeEndpoint 'updateclient2'
      done()

    new Bar({id:'11992299', type: 'Bar'}).then (bar) ->
      umsg =
        obj: {type:'Bar', id:'11992299'}
        type: 'Bar'
        client: 'updateclient2'
        user:
          isAdmin: true
        replyFunc: (ureply)->

      msg =
        type: 'Bar'
        client: 'updateclient2'
        user:
          isAdmin: true
        replyFunc: (reply)->
          messageRouter.objectManager._deleteObject(umsg)

      messageRouter.objectManager.onRegisterForPopulationChanges(msg)

  it 'should be able call listcommands through HttpMethod', (done)->
    request.get 'http://localhost:8008/api/?target=listcommands', (req,res,_body)->
      #console.log('listcommands returns '+body)
      body = JSON.parse(_body)
      #console.dir arguments
      expect(body.status).to.equal('SUCCESS')
      done()

  it 'should be able to expose an object and access _listObject through HttpMethod', (done)->
    messageRouter.objectManager.expose('Foo')
    request.get 'http://localhost:8008/api/?target=_listFoos', (req,res,_body)->
      #console.log('listcommands returns '+_body)
      body = JSON.parse(_body)
      #console.dir arguments
      expect(body.status).to.equal('SUCCESS')
      done()

  it 'should be able to restify an already exposed object and access /rest/Object through HttpMethod', (done)->
    messageRouter.makeRESTful('Foo')
    request.get 'http://localhost:8008/rest/Foo', (req,res,_body)->
      #console.log('listcommands returns '+_body)
      body = JSON.parse(_body)
      #console.dir arguments
      expect(body.status).to.equal('SUCCESS')
      done()

  it 'should be able to access a restified object through /rest/Object/:id and HttpMethod', (done)->
    #messageRouter.makeRESTful('Foo')
    request.get 'http://localhost:8008/rest/Foo/21008877', (req,res,_body)->
      #console.log('listcommands returns '+_body)
      body = JSON.parse(_body)
      #console.dir arguments
      expect(body.status).to.equal('SUCCESS')
      done()

  it 'should be able to update a restified object through put /rest/Object/:id and HttpMethod', (done)->
    #messageRouter.makeRESTful('Foo')
    record =
      type: 'Foo'
      abc: 123
      obj:{name: 'xxxxx17', type: 'Foo'}
    new Foo(record).then (fobj)->
      fobj.serialize().then ()->
        record2 =
          obj:{name: 'qfoobar17', type: 'Foo', id: fobj.id}
        console.log '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
        #console.dir fobj
        request.put {url:'http://localhost:8008/rest/Foo/'+fobj.id+'/?apitoken=abcdef123456', headers:{"Content-Type": "application/x-www-form-urlencoded"}, form: record2, body: record2}, (req,res,_body)=>
          console.log('put returns '+_body)
          request.get 'http://localhost:8008/rest/Foo/'+fobj.id, (req2,res2,_body2)=>
            console.log('rest get returns '+_body2)
            res = JSON.parse(_body2)
            console.dir res.payload
            expect(res.payload.name).to.equal('qfoobar17')
            done()

  it 'should be able to delete a restified object through delete /rest/Object/:id and HttpMethod', (done)->
    #messageRouter.makeRESTful('Foo')
    request.delete 'http://localhost:8008/rest/Foo/21008877', (req,res,_body)->
      #console.log('listcommands returns '+_body)
      body = JSON.parse(_body)
      #console.dir arguments
      expect(body.status).to.equal('SUCCESS')
      done()

  it 'should be able to create a new restified object through post /rest/Object/:id and HttpMethod', (done)->
    #messageRouter.makeRESTful('Foo')
    record =
      id: 'f117'
      name: 'foobarbaz'
    request.post {url:'http://localhost:8008/rest/Foo', headers:{"Content-Type": "application/json"}, body:JSON.stringify(record)}, (req,res,_body)->
      #console.log('put returns '+_body)
      body = JSON.parse(_body)
      #console.dir arguments
      expect(body.status).to.equal('SUCCESS')
      done()

  it 'should be able to extend a model with a new property', (done)->
    Foo.model.push {name:'xyzzy4', public: true, value:'xyzzy', default:'quux'}
    DB.extendSchemaIfNeeded(DB.DataStore, 'Foo').then ()=>
      DB.get('foo',['f417']).then (res)=>
        #console.log 'DB.get got back '+res
        #console.dir res
        expect(res[0].xyzzy2).to.equal('quux')
        done()

  it 'should be able to tag a model', (done)->
    new Bar({id:'f0f04b4b'}).then (bar) ->
      messageRouter.setTag('Bar', bar.id, 'footag').then (res)->
        #console.log 'tagged a model'
        done()

  it 'should be able to get all tags for a model', (done)->
    messageRouter.getTagsFor('Bar', 'f0f04b4b').then (res)->
      #console.log 'tags for tagged Bar  obj is '+res
      expect(res.indexOf('footag')).to.not.equal(-1)
      done()

  it 'should be able to search for all models with a tag', (done)->
    messageRouter.searchForTags('Bar', ['footag']).then (res)->
      #console.log 'models returned from searching for footag tags  is '+res
      expect(res[0]).to.equal('f0f04b4b')
      done()