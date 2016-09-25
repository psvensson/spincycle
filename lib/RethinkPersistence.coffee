r           = require('rethinkdb')
defer       = require('node-promise').defer


debug = process.env["DEBUG"]


class RethinkPersistence

  if process.env['RETHINKDB_PORT_28015_TCP_PORT'] then madr = 'rethinkdb' else madr = '127.0.0.1'
  mport = process.env['RETHINKDB_PORT_28015_TCP_PORT'] or '28015'

  constructor: (@dburl, @DB) ->
    @connection = undefined
    @dbs = []

  connect: ()=>
    console.log 'connect called...'
    q = defer()
    r.connect({host: madr, port: mport}, (err, conn) =>
      if err then throw err
      @connection = conn
      q.resolve(@)
    )
    return q

  getConnection: () =>

  listenForChanges: (table) =>
    table.changes().run(@connection).then (cursor)=>
      #if debug then console.log '========================================================changes result is '+cursor
      #if debug then console.dir cursor
      if cursor
        cursor.each (el)->
          if debug then console.log 'Rethink changes update --- --- ---'
          if debug then console.dir el
          if el
            @DB.onUpdated(el)

  _dogetDBFor: (_type)=>
    q = defer()
    type = _type.toLowerCase()
    r.dbList().contains('spincycle').do((databaseExists) ->
      r.branch(databaseExists, { created: 0 }, r.dbCreate('spincycle'))
    ).run(@connection, (err, res) =>
      if err
        console.log 'Rethink getDbFor err = '+err
        console.dir err
      if @dbs[type]
        #console.log '---- found table in cache: '+type
        q.resolve @dbs[type]
      else
        #console.log 'not found in cache...'
        r.db('spincycle').tableList().run(@connection, (te, _tlist)=>
          tlist = _tlist or []
          #console.log 'table list is... '+tlist
          exists = (tlist.filter (el)-> el == type)[0]
          if exists == type
            table = @dbs[type]
            if not table
              #console.log 'did not find table '+type+' in cache. Adding now..'
              table = r.db('spincycle').table(type)
              @dbs[type] = table
              @listenForChanges(table)
            #console.log 'resolving table from cache: '+type
            q.resolve table
          else
            console.log 'exist != '+type
            r.db('spincycle').tableCreate(type).run(@connection, (err2, res2) =>
              #console.log 'table create result is..'
              #console.dir res2
              if err2
                console.log 'tableList err = '+err2
                console.dir err2
              table = r.db('spincycle').table(type)
              console.log 'creating new table '+type
              @dbs[type] = table
              @listenForChanges(table)
              q.resolve(table)
            )
      )

    )
    return q

  getDbFor: (_type) =>
    q = defer()
    #console.log 'getDbFor called for '+_type
    if not @connection
      @connect().then () =>
       @_dogetDBFor(_type).then (db)=>
          #console.log 'getDbFor got back later db for '+_type
          q.resolve(db)
    else
      @_dogetDBFor(_type).then (db)=>
        #console.log 'getDbFor got back db for '+_type
        q.resolve(db)
    return q

  extend: (_type, id, field, def) =>
    q = defer()
    @get _type,id,(o)=>
      if o and not o[field]
        o[field] = def
        @set _type,o, (setdone)=>q.resolve(o)
    return q

  all: (_type, query, cb)=>
    type = _type.toLowerCase()
    if debug then console.log 'Rethink.all called for '+type
    @getDbFor(type).then (db)=>
      if debug then console.log 'all got query'
      if debug then console.dir query
      rr = db
      if query?.limit
        if debug then console.log 'skipping '+query.skip+' limiting '+query.limit
        rr = rr.skip(parseInt(query.skip)).limit(parseInt(query.limit))
      if query?.sort then rr = db.orderBy(query?.sort or 'name')
      rr.run @connection, (err, cursor) ->
        if err
          console.log 'all err: '+err
          console.dir err
          throw err
        cursor.toArray (ce, result)=>
          if debug then console.log 'all result is '+result.length+' records'
          #if debug then console.dir result
          cb result

  count: (_type)=>
    if debug then console.log 'Rethink.count called'
    type = _type.toLowerCase()
    q = defer()
    @getDbFor(type).then (db)=>
      db.count().run @connection, (err, result) ->
        if err
          console.log 'count err: '+err
          console.dir err
          throw err
        console.log result
        q.resolve result
    return q

  get: (_type, id, cb) =>
    #if debug then console.log 'Rethink.get called'
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>
      db.get(id).run @connection, (err, result) ->
        if err
          console.log 'get err: '+err
          console.dir err
          throw err
        #console.log 'get result was'
        #console.log result
        cb result

  find: (_type, property, _value) =>
    @findMany(_type, property, _value)

  findMany: (_type, _property, _value) =>
    if debug then console.log 'Rethink.findMany called'
    property = _property or ""
    value = _value or ""
    if value
      value = value.toString()
      value = value.replace(/[^\w\s@.-]/gi, '')
    #console.log 'Rethink findmany called for type '+_type+' property '+property+' and value '+value
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>
      db.filter( (element)=>
        element(property).match(value)
      ).run @connection, (err, cursor) ->
        if err
          console.log 'findMany err: '+err
          console.dir err
          throw err
        cursor.toArray (ce, result)=>
          #console.log 'findmany result is '+result
          #console.log result
          q.resolve result
    return q

  findQuery: (_type, query) =>
    if debug then console.log 'Rethink findQuery called for type '+_type
    if debug then console.dir query
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>
        # { sort: 'name', property: 'name', value: 'BolarsKolars' }
      rr = db.orderBy(query.sort or 'name')
      rv = query.value == 'undefined' or query.value.indexOf('[') > -1 or query.value == 'null' or query.value.indexOf('bject') > -1
      if not rv and query.property
        value = query.value.toString()
        value = value.replace(/[^\w\s@.]/gi, '')
        if not query.wildcard then value = '^'+value+'$'
        rr = rr.filter( (element)=>
            if debug then console.log 'Rethink findQuery running query...'
            element(query.property).match(value)
        )
        if query.limit
          rr = rr.skip(query.skip).limit(query.limit)

        rr.run @connection, (err, cursor) ->
          if err
            console.log 'findQuery error: '+err
            console.dir err
          cursor.toArray (ce, result)=>
            #console.log 'findQuery result is '
            #console.log result
            q.resolve result
      else
        q.resolve([])
    return q

  search: (_type, property, _value) =>
    if debug then console.log 'Rethink.search called'
    value = _value or ""
    if value
      value = value.toString()
      value = value.replace(/[^\w\s@.]/gi, '')
    console.log 'Rethink search called for type '+_type+' property '+property+' and value '+value
    q = defer()
    @getDbFor(type).then (db)=>
      db.filter( (element)=>
        element(property).match("^"+value)
      ).run @connection, (err, cursor) ->
        if err
          console.log 'search err: '+err
          console.dir err
          throw err
        cursor.toArray (ce, result)=>
          console.log 'search result is '+result
          console.log result
          q.resolve result
    return q

  set: (_type, obj, cb)=>
    type = _type.toLowerCase()
    #if debug then console.log 'Rethink.set called for '+type
    #if debug then console.dir obj
    @getDbFor(type).then (db)=>
      try
        db.insert(obj, {conflict: "update", return_changes: true}).run @connection, (err, result) ->
          if err
            console.log 'set err: '+err
            console.dir err
            throw err
            cb()
          else
            cb(result)
      catch ex
        console.log 'caught exception!'
        console.dir ex
        console.dir obj
        cb()

  remove: (_type, obj, cb) =>
    if debug then console.log 'Rethink.remove called'
    type = _type.toLowerCase()
    id = obj.id
    @getDbFor(type).then (db)=>
      db.get(id).delete().run @connection, (err, result) ->
        if err
          console.log 'remove err: '+err
          console.dir err
          throw err
        console.log 'remove result = '+result
        cb result


module.exports = RethinkPersistence