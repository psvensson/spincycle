couchdb         = require('felix-couchdb');
defer           = require('node-promise').defer
OStore          = require('./OStore')

debug = process.env["DEBUG"]

class CouchPersistence

  constructor: () ->
    @dbs = []

  connect: () =>
    @client = couchdb.createClient(5984, 'localhost', auth: { username: 'admin', password: process.env["COUCH_ADMIN_PW"] })

  getDbFor: (_type) =>
    q = defer()
    type = _type.toLowerCase()
    db = @dbs[type]
    if not db
      db = @client.db(type)
      db.exists (er, exists) =>
        if exists
          q.resolve(db)
        else
          console.log('database '+type+' does not exists. creating as we speak...')
          db.create (er) =>
            if (er) then console.log 'DB create error: '+JSON.stringify(er)
            # --------------------------------------------- Create 'all' view
            db.saveDesign type, views:
              'all': map: (doc)->
                if doc.id and doc.type.toLowerCase() == type
                  emit doc.id, doc

              'byProviderId': map: (doc)->
                if doc.id and doc.type.toLowerCase() == type
                  emit doc.providerId, doc

            @dbs[type] = db
            q.resolve(db)

    return q

  dot: (attr) ->
    return (obj) ->
      obj[attr]

  byProviderId: (_type, pid) =>
    console.log 'byProviderId called for pid '+pid
    q = defer()
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>
      matches = db.view type, 'byProviderId', { key: pid }, (err, matches) =>
        console.log 'err = '+err+' matches = '+matches
        console.dir matches
        q.resolve(matches.rows.map(@dot('value')))
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