r           = require('rethinkdb')
defer       = require('node-promise').defer


debug = process.env["DEBUG"]


class RethinkPersistence

  if process.env['RETHINKDB_HOST'] then madr = process.env['RETHINKDB_HOST'] else madr = '127.0.0.1'
  mport = process.env['RETHINKDB_PORT_28015_TCP_PORT'] or '28015'

  constructor: (@dburl, @DB) ->
    console.log 'RethinkPersistence::constructor dburl = '+@dburl
    @connection = undefined
    @dbs = []

  connect: ()=>
    console.log 'connect called...  dburl = '+@dburl
    #console.dir @dburl
    q = defer()
    ccc = @dburl or {host: madr, port: mport}
    r.connect(ccc, (err, conn) =>
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
        cursor.each (el)=>
          if debug then console.log 'Rethink changes update --- --- ---'
          if debug then console.dir el
          if @DB
            if el
              @DB.onUpdated(el)
          else
            console.log '@DB not defined in rethinkPersistence!!'

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

  addIndexIfNotPresent:(table,type,prop)=>
    q = defer()

    table.indexList().run @connection,(err2, res2) =>
      console.log '---- addindex check result for property '+prop+' on table '+type+' ---> '+res2
      console.dir res2
      found = false
      res2.forEach (el) => if el == prop then found = true
      if not found
        console.log 'addIndexIfNotPresent adding multi index for property '+prop+' on table '+type
        table.indexCreate(prop, {multi: true})
        table.indexWait(prop).run @connection,(er2, re2) =>
          console.log 'addIndexIfNotPresent waited done'
          q.resolve()
      else
        q.resolve()
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
    #if debug then console.log '-Rethink.all called for '+type
    @getDbFor(type).then (db)=>
      #if debug then console.log 'all got query for db '+db
      #if debug then console.dir query
      rr = db
      if query
        rr = rr.orderBy(query.sort or 'name')
        #if debug then console.log 'skipping '+query.skip+' limiting '+query.limit
        if query.skip then rr = rr.skip(parseInt(query.skip or 0))
        if query.limit then rr = rr.limit(parseInt(query.limit))
      rr.run @connection, (err, cursor) ->
        if err
          console.log 'all err: '+err
          console.dir err
          throw err
        cursor.toArray (ce, result)=>
          #if debug then console.log 'all result is '+result.length+' records'
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
        if debug then console.log result
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
        if debug then console.log 'RethinkPersistence get result was'
        if debug then console.log result
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
        if property then element(property).eq(value)
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

  filter:(_type, query)=>
    if debug then console.log 'Rethink filter called for type '+_type
    if debug then console.dir query
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>
      db.filter(query).run @connection, (err, cursor) ->
        if debug then console.log 'filter cursor got back'
        if debug then console.dir cursor
        if err
          console.log 'filter error: '+err
          console.dir err
        cursor.toArray (ce, result)=>
          if debug then console.log 'Rethink filter got '+result.length+' results'
          q.resolve result
    return q

  findQuery: (_type, query) =>
    if debug then console.log 'Rethink findQuery called for type '+_type
    if debug then console.dir query
    if not query.property then query.property = 'name'
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>
      # { sort: 'name', property: 'name', value: 'BolarsKolars' }
      #console.log 'orderby = '+r.orderBy+' desc = '+r.desc
      rr = r.db('spincycle').table(type)
      sv = query.sort or 'name'
      @addIndexIfNotPresent(rr, type, sv).then ()=>
        #rr = rr.orderBy({index: r.desc(sv)})
        rr = rr.orderBy(sv)
        rv = @getValueForQuery('value', 'property', query)
        if not rv.invalid
          rr = rr.filter( (element)=>
            if query.wildcard
              element(query.property).match("^"+query.value)
            else
              element(query.property).eq(query.value)
          )
          if query.property2
            rv2 = @getValueForQuery('value2', 'property2', query)
            if not rv2.invalid
              rr = rr.filter( (el)=>
                if query.wildcard
                  el(query.property2).match(rv2.value)
                else
                  el(query.property2).eq(rv2.value)
              )
          if query.limit then rr = rr.skip(query.skip or 0).limit(query.limit)
          if query.orderBy then rr = rr.orderBy(query.orderBy)
          if debug then console.log 'Rethink findQuery running query...'
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

  getValueForQuery: (val, prop, query)->
    if debug then console.log 'getValueFor called with valname '+val+' and propname '+prop
    rv = query[val] == 'undefined' or query[val].indexOf('[') > -1 or query[val] == 'null' or query[val].indexOf('bject') > -1
    #console.log 'rv = '+rv
    #console.log 'not rv and query.property ---> '+(not rv and query[prop] isnt undefined and query[prop] isnt null)
    value = query[val].toString()
    #value = value.replace(/[^\w\s@.]/gi, '')
    value = value.replace(/[`~!@#$%^&*()_|+\=?;:'",.<>\{\}\[\]\\\/]/gi, '')
    if debug then console.log 'final search value is '+value
    #if query.wildcard then value = '^'+value
    #console.log 'returning value "'+value+'"'
    return {invalid: rv, value: value}

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
        if query.wildcard
          element(property).match("^"+value)
        else
          element(property).eq(value)
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
    if obj
      @getDbFor(type).then (db)=>
        #if debug then console.log 'Rethink.set using db '+db
        try
          db.insert(obj, {conflict: "update", return_changes: true}).run @connection, (err, result) ->
            if err
              console.log 'set err: '+err
              console.dir err
              throw err
              cb()
            else
              #if debug then console.log 'Rethink.set OK'
              cb(result)
        catch ex
          console.log 'caught exception!'
          console.dir ex
          console.dir obj
          cb()
     else
        if debug then console.log 'Rethink.set not OK (empty obj)'
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
        #console.log 'remove result = '+result
        cb result


module.exports = RethinkPersistence