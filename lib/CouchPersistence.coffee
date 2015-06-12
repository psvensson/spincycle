couchdb         = require('felix-couchdb');
defer           = require('node-promise').defer
OStore          = require('./OStore')
uuid            = require('node-uuid')

debug = process.env["DEBUG"]

class CouchPersistence

  constructor: () ->
    @dbs = []

  connect: () =>
    @client = couchdb.createClient(5984, 'localhost', auth: { username: 'admin', password: process.env["COUCH_ADMIN_PW"] })

  getDbFor: (_type) =>
    #console.log 'getDbFor called for '+_type
    q = defer()
    q.tag = uuid.v4()
    type = _type.toLowerCase()
    db = @dbs[type]
    if not db
      console.log 'no db found for '+type+' q = '+q.tag
      db = @client.db(type)
      db.exists (er, exists) =>
        #console.log 'exists returned '+exists+' for db '+type+' q = '+q.tag
        if er
          console.log 'ERROR ---------------- '+er
          console.dir er
        if exists
          #console.log 'database '+type+' exists, so returning that'+' q = '+q.tag
          @dbs[type] = db
          if not q.done then q.resolve(db)
          q.done = true
        else
          console.log('database '+type+' does not exists. creating as we speak...'+' q = '+q.tag)
          db.create (er) =>
            if (er) then console.log 'DB create error: '+JSON.stringify(er)
            # --------------------------------------------- Create 'all' view
            db.saveDesign type, views:
              'all': map: (doc)->
                if doc.id and doc.type.toLowerCase() == type
                  emit doc.id, doc

              'providerid': map: (doc)->
                if doc.providerId
                  emit doc.providerId, doc

            console.log 'new database '+type+' created'+' q = '+q.tag
            @dbs[type] = db
            q.resolve(db)
    else
      q.resolve(db)
    return q

  dot: (attr) ->
    return (obj) ->
      obj[attr]

  byProviderId: (_type, pid) =>
    console.log 'byProviderId called for pid '+pid+' and type '+_type
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>
      console.log 'got db '+db
      db.view(type,'providerid',{ key: pid},(err, matches) =>
        console.log 'err = '+err+' matches = '+matches
        console.dir matches
        q.resolve(matches.rows.map(@dot('value')))
      )
    return q

  all: (_type, cb) =>
    rv = []
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>
      db.allDocs (err, res) ->
        if (err)
          console.log 'CouchPersistence fetch all ERROR: '+err
          console.dir err
          cb []
        else
          #console.log 'couchpersistence fetch all '+type+" got back.."
          #console.dir(res)
          count = res.rows.length
          if count == 0
            cb rv
          else
            res.rows.forEach (row) ->
              db.getDoc row.id, (verr, value) ->
                rv.push value if row.id.indexOf('_') == -1
                if --count == 0 then cb rv

  get: (_type, id, cb) =>
    if _type
      type = _type.toLowerCase()
      @getDbFor(type).then(
        (db) =>
          db.getDoc id, (err,res) =>
            if err
              console.log '** Couch Get ERROR for type '+type+' id '+id+': '+err
              console.dir err
              cb(null)
            else
              cb(res)
        ,(err) =>
          console.log 'getDbFor Couch ERROR: '+err
          console.dir err
          cb(null)
      )
    else
      console.log '...EEEEhh  trying to get DB object with no type + WTF!'
      xyzzy

  set: (_type, obj, cb) =>
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>
      onSave = (err, res, cb) =>
        if err
          console.log '** Couch Set ERROR: '+err
          console.dir err
          console.dir obj
        else
          OStore          = require('./OStore')
          #console.dir OStore
          oo = OStore.objects[obj.id]
          if debug then console.log '--------------------------------------------------------------------------------------------- couchpersistence.set setting _rev to '+res.rev+' on '+type+' '+obj.id
          if not res.rev then console.dir res
          oo._rev = res.rev
        if cb then cb(res)
      db.saveDoc(obj.id, obj, onSave)

  remove: (_type, obj, cb) =>
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>
      db.removeDoc obj.id, obj._rev, (err, res) =>
        if err
          console.log '** Couch Remove ERROR: '+err
          console.dir err
          console.dir obj
        else
          if (cb) then cb(res)


module.exports = CouchPersistence