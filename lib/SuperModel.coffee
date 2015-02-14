defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')

OMgr            = require('./OStore')
DB              = require('./DB')
error           = require('./Error').error
ResolveModule   = require('./ResolveModule')

console.log 'supermodel dirname is '+dirname
console.log(__dirname)
dirname = __dirname.substring(0, __dirname.indexOf('/node_modules'))
console.log 'starting module rsolveing from path '+dirname
resolver = new ResolveModule(dirname)

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
    if(not resolvearr)
      console.log ' ++++++++++++++++ NO RESOVLEARR ++++++++++++++'
      q = defer()
      allpromises.push(q)
      q.resolve()
    else
      resolvearr.forEach (robj) =>

        ((resolveobj) =>
          r = defer()
          allpromises.push(r)
          if not resolveobj.ids
            @[resolveobj.name] = []
            resolveobj.ids = []
            console.log '============================== null resolveobj.ids'
            r.resolve({})
          else
            if typeof resolveobj.ids is 'string' then resolveobj.ids = [resolveobj.ids]
            if resolveobj.ids.length > 1 then  @[resolveobj.name] = []
            console.log ' resolveobjds ('+(typeof resolveobj.ids)+') ids length are.. '+resolveobj.ids.length
            #console.dir(resolveobj.ids)
            count = resolveobj.ids.length
            resolveobj.ids.forEach (id) =>
              DB.get(resolveobj.type, [id]).then (record) =>
                @createObjectFrom(record).then (obj) =>
                  console.log 'object created: '+obj.id
                  @insertObj(resolveobj, obj)
                  #console.log '============================== 2'
                  if --count == 0 then r.resolve(obj)
        )(robj)

    all(allpromises, error).then( (results) ->
      #console.log 'allpromises resolved'
      alldone.resolve(results)
    ,error)
    return alldone

  createObjectFrom: (record) =>
    q = defer()
    console.log 'createObjectFrom got record '+record[0].id
    #console.dir record[0]
    resolver.resolve record[0].type, (filename) ->
      console.log 'resolved module '+record[0].type+" as "+filename
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
