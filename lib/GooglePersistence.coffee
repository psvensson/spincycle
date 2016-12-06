gcloud  = require('google-cloud')
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

  all: (_type, query, cb)=>
    type = _type.toLowerCase()
    if debug then console.log 'Google.all called for '+type
    @getDbFor(type).then (db)=>
      query = db.createQuery(type).limit(10000)
      db.runQuery query, (err, entities) ->
        if err
          if debug then console.log 'Google.all ERROR: '+err
          if debug then console.dir err
          cb()
        else
          if debug then console.log 'Google.all returns '+entities.length+' entities'
          #if debug then console.dir entities
          result = entities
          #if debug then console.dir result
          cb(result)

  count: (_type)=>
    if debug then console.log 'Google.count called'
    type = _type.toLowerCase()
    q = defer()
    @getDbFor(type).then (db)=>
      #qq = '__Stat_spincycle_'+type+'__'
      qq = type
      console.dir '---------------------------------------query is '+qq
      query = db.createQuery(qq).select('__key__')
      db.runQuery query, (err, entities, endCursor)=>
        if err
          console.log 'Google.count error: '+err
          console.dir err
          q.resolve()
        else
          console.log 'Google.count returns '+entities.length
          #console.dir arguments
          q.resolve(entities.length)
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
    type = _type.toLowerCase()
    #console.log 'Google.get called type = '+type+' id = '+id
    @getDbFor(type).then (db)=>
      key = db.key([type, id])
      #if debug then console.log '-- Google.get key for '+type+' became '
      #if debug then console.dir key
      try
        db.get key,(err, entity) =>
          if err
            if debug then console.log 'Google.get ERROR: '+err
            if debug then console.dir err
            cb()
          else
            if debug then console.log 'Google.get returns entity for '+type+' id = '+id
            if debug then console.dir entity
            cb(entity.value)
      catch ee
        console.log 'get error '+ee+' for key '
        console.dir key
        cb()

  extend: (_type, id, field, def) =>
    #console.log 'google extend called'
    q = defer()
    @get _type,id,(o)=>
      #console.log 'google.get done'
      if o and not o[field]
        o[field] = def
        @set _type,o,(setdone)=>
          #console.log 'google set done'
          q.resolve(o)
      else
        q.resolve(o)
    return q

  find: (_type, property, _value) =>
    @findMany(_type, property, _value)

  findMany: (_type, property, _value, query) =>
    q = defer()
    value = _value or ""
    type = _type.toLowerCase()
    console.log '=============== Google.findMany called for '+type+' filtering on '+property+' = '+value
    @getDbFor(type).then (db)=>
      query = db.createQuery(type).limit(query?.limit or 10000).filter(property, '=', value)
      db.runQuery query, (err, entities, info) ->
        console.log 'google.findMany result info: '+info
        console.dir info
        if err
          if debug then console.log 'Google.findMany ERROR: '+err
          if debug then console.dir err
          q.resolve()
        else
          console.log 'Google.all returns '+entities.length+' entities'
          console.dir entities
          #result = entities.map (el)->el.data
          q.resolve(entities)
    return q

  findQuery: (_type, query) =>
    @findMany(_type, query.property, query.value, query)

  # datastore doesn't support wildcard text searches :/
  search: (_type, property, _value) =>
    @findMany(_type, property, _value)

  set: (_type, obj, cb)=>
    type = _type.toLowerCase()
    #if debug then console.log '-- Google.set called for '+type+' - '+JSON.stringify(obj)
    #if debug then console.dir obj
    @getDbFor(type).then (db)=>
      if not obj.id
        if debug then console.log '-- Google.set called for '+type+' - '+JSON.stringify(obj)
        xyzzy
      else
        key = db.key([type, obj.id])
      if debug then console.log '-- Google.set key for '+type+' became '
      if debug then console.dir key
      db.upsert {key:key, data:obj}, (err)=>
        if debug then console.log '-- Google.set done for '+type+' '+obj.id+' !'
        if err
          if debug then console.log 'Google.set ERROR: '+err
          if debug then console.dir err
          cb()
        else
          cb(obj)

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