r           = require('rethinkdb')
defer       = require('node-promise').defer


debug = process.env["DEBUG"]


class RethinkPersistence

  if process.env['CRATEDB_HOST'] then madr = process.env['CRATEDB_HOST'] else madr = '127.0.0.1'
  mport = process.env['CRATEDB_PORT_28015_TCP_PORT'] or '28015'

  constructor: (@dburl, @DB) ->
    @connection = undefined
    @dbs = []

  connect: ()=>
    console.log 'connect called...  dburl = '+@dburl
    #console.dir @dburl
    q = defer()
    ccc = @dburl or {host: madr, port: mport}

    return q

  getConnection: () =>

  listenForChanges: (table) =>
    table.changes().run(@connection).then (cursor)=>


  _dogetDBFor: (_type)=>
    q = defer()
    type = _type.toLowerCase()


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

    return q

  all: (_type, query, cb)=>
    type = _type.toLowerCase()
    if debug then console.log '-Rethink.all called for '+type
    @getDbFor(type).then (db)=>


  count: (_type)=>
    if debug then console.log 'Rethink.count called'
    type = _type.toLowerCase()
    q = defer()

    return q

  get: (_type, id, cb) =>
#if debug then console.log 'Rethink.get called'
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>


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

    return q

  findQuery: (_type, query) =>
    if debug then console.log 'Rethink findQuery called for type '+_type
    if debug then console.dir query
    if not query.property then query.property = 'name'
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>

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

    return q

  set: (_type, obj, cb)=>
    type = _type.toLowerCase()

    cb()

  remove: (_type, obj, cb) =>
    if debug then console.log 'Rethink.remove called'
    type = _type.toLowerCase()
    id = obj.id

    cb result


module.exports = RethinkPersistence