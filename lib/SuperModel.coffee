defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')

OMgr            = require('./OStore')
DB              = require('./DB')
cfg             = require('../Config')
error           = require('../Error').error

class SuperModel

  serialize: () =>
    record = @getRecord()
    OMgr.storeObj(@)
    DB.set(@type, record)


  # [ {name: 'zones', type: 'zone', ids: [x, y, z, q] }, .. ]
  loadFromIds:(resolvearr) =>
    alldone = defer()
    allpromises = []

    if(not resolvearr)
      q = defer()
      allpromises.push(q)
      q.resolve()
    else
      resolvearr.forEach (resolveobj) =>
        r = defer()
        allpromises.push(r)
        if not resolveobj.ids
          @[resolveobj.name] = []
          resolveobj.ids = []
          r.resolve({})
        if typeof resolveobj.ids is 'string' then resolveobj.ids = [resolveobj.ids]
        if resolveobj.ids.length > 1 then  @[resolveobj.name] = []

        resolveobj.ids.forEach (id) =>
          OMgr.getObj(id, resolveobj.type).then (obj) =>
            @insertObj(resolveobj, obj)
            r.resolve(obj)

    all(allpromises, error).then( (results) ->
      alldone.resolve(results)
    ,error)
    return alldone

  insertObj: (ro, o) =>
    if ro.ids.length > 1
      @[ro.name].push(o)
    else
      @[ro.name] = o


module.exports = SuperModel;
