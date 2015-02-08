cradle = require('cradle');


class CouchPersistence

  constructor: () ->
    @dbs = []

  connect: () =>
    @connection = new(cradle.Connection)

  getDbFor: (type) =>
    console.log 'couchpersistence getDbFor called with type '+type
    db = @dbs[type]
    if not db
      db = @connection.database(type)
      db.exists (err, exists) =>
        if err then console.log('error', err)
        else if exists then console.log('the force is with you.')
        else
          console.log('database does not exists.');
          db.create()
    @dbs[type] = db
    return db

  get: (type, id, cb) =>
    console.log 'couchPersistence get called type = '+type+' id = '+id
    @getDbFor(type).get id, (err,res) =>
      if err then console.log '** Couch Get ERROR: '+err
      if cb then cb(res)

  set: (type, obj, cb) =>
    db = @getDbFor(type)
    onSave = (err, res, cb) =>
      if err then console.log '** Couch Set ERROR: '+err
      if cb then cb(res)
    if obj.id then db.save(obj.id, obj, onSave) else db.save(obj, onSave)

module.exports = CouchPersistence