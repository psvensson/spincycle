pg = require('pg')

class PostgresqlPersistence

  constructor: () ->
    @dbs = []
    @done

  connect: ()=>
    conString = "postgres://peter:foobar@localhost/qp"
    pg.connect conString,(err, client, done) =>
      if err
        console.log 'PostgreSQL ERROR connecting: '+err
        console.dir err
      else
        @deon = done
        @client = client
        console.log 'Created PostgreSQL successfully'

  getDbFor: (_type) =>
    q = defer()
    type = _type.toLowerCase()
    db = @dbs[type]
    if not db

      @client.query 'SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_name = \''+type+'\' )', (err, result) =>
        if (err)
          throw err
        else
          if result.rows.length == 0
            # create table according to model type schema
          else
            @dbs[type] = type
            q.resolve(type)
    else
      q.resolve(type)
    return q


  all: (_type, cb)=>
    rv = []
    type = _type.toLowerCase()
    @getDbFor(type).then (db) =>


  get: ()=>


  set: ()=>


  remove: ()=>



module.exports = PostgresqlPersistence