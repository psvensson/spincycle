gcloud  = require('gcloud')
defer   = require('node-promise').defer
debug   = process.env["DEBUG"]

class GooglePersistence

  constructor: (@dburl, @DB) ->
    @connection = undefined
    @dbs = []

  connect: ()=>
    console.log 'Google connect called...'
    q = defer()
    q.resolve(@)
    return q

  getDbFor: (_type)=>
    q = defer()
    type = _type.toLowerCase()
    db = @dbs[type]
    if db
      q.resolve(db)
    else
      dataset = gcloud.datastore({ projectId: process.env.GCLOUD_PROJECT, namespace: 'spincycle' })
      @dbs[type] = dataset
      q.resolve(dataset)
    return q

  all: (_type, cb)=>
    type = _type.toLowerCase()
    if debug then console.log 'Google.all called for '+type
    @getDbFor(type).then (db)=>
      query = db.createQuery(type).order('-createdAt').limit(10000)
      db.runQuery query, (err, entities) ->
        if err
          if debug then console.log 'Google.all ERROR: '+err
          if debug then console.dir err
          cb()
        else
          if debug then console.log 'Google.all returns '+entities.length+' entities'
          if debug then console.dir entities
          cb(entities)

  count: (_type)=>
    if debug then console.log 'Google.count called'
    type = _type.toLowerCase()
    q = defer()
    @getDbFor(type).then (db)=>
      query = db.createQuery('__Stat_spincycle_'+type+'__')
      count = query.getproeprties('count')
      console.log 'Google.count return '+count
      q.resolve(count)
      """
      db.runQuery query, (err, entities) ->
        if err
          if debug then console.log 'Google.all ERROR: '+err
          if debug then console.dir err
          cb()
        else
          if debug then console.log 'Google.all returns '+entities.length+' entities'
          if debug then console.dir entities
          cb(entities)
      """
    return q

  get: (_type, id, cb) =>
    if debug then console.log 'Google.get called '
    type = _type.toLowerCase()
    @getDbFor(type).then (db)=>
      key = db.key([type, id])
      db.get key, (err, entity) =>
        if err
          if debug then console.log 'Google.get ERROR: '+err
          if debug then console.dir err
          cb()
        else
          if debug then console.log 'Google.get returns entity'
          if debug then console.dir entity
          cb(entity)

  find: (_type, property, _value) =>
    @findMany(_type, property, _value)

  findMany: (_type, property, _value) =>
    if debug then console.log 'Google.findMany called'
    value = _value or ""
    query = db.createQuery(type).order('-createdAt').limit(10000).filter(property, '=', value)
    db.runQuery query, (err, entities) ->
      if err
        if debug then console.log 'Google.all ERROR: '+err
        if debug then console.dir err
        cb()
      else
        if debug then console.log 'Google.all returns '+entities.length+' entities'
        if debug then console.dir entities
        cb(entities)
    return q

  findQuery: (_type, query) =>
    @findMany(_type, query.property, query.value)

  # datastore doesn't support wildcard text searches :/
  search: (_type, property, _value) =>
    @findMany(_type, property, value)

  set: (_type, obj, cb)=>
    type = _type.toLowerCase()
    if debug then console.log 'Google.set called for '+type
    if debug then console.dir obj
    @getDbFor(type).then (db)=>
      if not obj.id
        key = db.key(type)
        obj.id = key.path[1]
      else
        key = db.key(type, obj.id)
      db.upsert key, obj, (err)=>
        if err
          if debug then console.log 'Google.set ERROR: '+err
          if debug then console.dir err
          cb(false)
        else
          cb(true)

  remove: (_type, obj, cb) =>
    if debug then console.log 'Google.remove called'
    type = _type.toLowerCase()
    id = obj.id
    @getDbFor(type).then (db)=>
      key = db.key(type, obj.id)
      db.delete key, (err, apiResponse)=>
        if err
          if debug then console.log 'Google.remove ERROR: '+apiResponse
          if debug then console.dir apiResponse
          cb(false)
        else
          cb(true)


module.exports = GooglePersistence