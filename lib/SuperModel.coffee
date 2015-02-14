defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')

OMgr            = require('./OStore')
DB              = require('./DB')
error           = require('./Error').error
ResolveModule   = require('./ResolveModule')

resolver = new ResolveModule('../')

class SuperModel

  serialize: () =>
    record = @getRecord()
    OMgr.storeRecord(@)
    DB.set(@type, record)
    #console.log ' * serializing '+@type+" id "+@id

  # [ {name: 'zones', type: 'zone', ids: [x, y, z, q] }, .. ]
  loadFromIds:(resolvearr) =>
    alldone = defer()
    allpromises = []
    console.log 'loadfromids called resolvearr is '+resolvearr.length
    if(not resolvearr)
      console.log ' ++++++++++++++++ NO RESOVLEARR ++++++++++++++'
      q = defer()
      allpromises.push(q)
      q.resolve()
    else
      resolvearr.forEach (resolveobj) =>

        (() =>
          r = defer()
          allpromises.push(rd)
          if not resolveobj.ids
            @[resolveobj.name] = []
            resolveobj.ids = []
            console.log '============================== null resolveobj.ids'
            r.resolve({})
          else
            if typeof resolveobj.ids is 'string' then resolveobj.ids = [resolveobj.ids]
            if resolveobj.ids.length > 1 then  @[resolveobj.name] = []
            console.log ' resolveobjds ('+(typeof resolveobj.ids)+') is are.. '+resolveobj.ids
            console.dir(resolveobj.ids)
            resolveobj.ids.forEach (id) =>
              DB.get(resolveobj.type, [id]).then (record) =>
                @createObjectFrom(record).then (obj) =>
                  console.log 'object created: '+obj.id
                  @insertObj(resolveobj, obj)
                  #console.log '============================== 2'
                  r.resolve(obj)
        )

    all(allpromises, error).then( (results) ->
      #console.log 'allpromises resolved'
      alldone.resolve(results)
    ,error)
    return alldone

  createObjectFrom: (record) =>
    q = defer()
    console.log 'createObjectFrom got record'
    console.dir record[0]
    resolver.resolve record[0].type, (filename) ->
      module = require(filename.replace('.js', ''))
      o = Object.create(module.prototype)
      o.constructor(record[0])
      q.resolve(o)
    return q

  insertObj: (ro, o) =>
    if ro.ids.length > 1
      @[ro.name].push(o)
    else
      @[ro.name] = o


module.exports = SuperModel;
