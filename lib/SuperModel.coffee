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
    console.log '++ loadFromIds resolving '+resolvearr.length+' objects'
    alldone = defer()
    allpromises = []

    if(not resolvearr)
      q = defer()
      allpromises.push(q)
      console.log ' empty resolvearray!! '
      q.resolve()
    else
      resolvearr.forEach (resolveobj) =>
        #console.log '-- resolving obj'
        #console.dir resolveobj
        #console.log 'typeof ids is '+(typeof resolveobj.ids)
        r = defer()
        allpromises.push(r)
        if not resolveobj.ids
          @[resolveobj.name] = []
          resolveobj.ids = []
          console.log 'loadFromIds got null id for '+resolveobj.name
          r.resolve({})
        if typeof resolveobj.ids is 'string' then resolveobj.ids = [resolveobj.ids]
        if resolveobj.ids.length > 1 then  @[resolveobj.name] = []

        resolveobj.ids.forEach (id) =>
          console.log '   SuperModel resolving '+resolveobj.type+' id '+id
          OMgr.getObj(id, resolveobj.type).then (obj) =>
            console.log 'SuperModel resolved '+obj.type+' '+id+' -> '+obj
            @insertObj(resolveobj, obj)
            console.log 'SuperModel id '+id+' resolve done. resolving back..'
            r.resolve(obj)
    console.log '------------------------------------- allpromises arr is '+allpromises.length+' now resolving all... -----------------------------------------'
    all(allpromises, error).then( (results) ->
      console.log '++ loadFromids all done'
      alldone.resolve(results)
    ,error)
    return alldone

  insertObj: (ro, o) =>
    console.log '      insertObj called for '+o.type+'  '+o.id
    if ro.ids.length > 1
      @[ro.name].push(o)
    else
      @[ro.name] = o


module.exports = SuperModel;
