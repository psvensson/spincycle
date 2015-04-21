defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')
M               = require('./MessageRouter')
OMgr            = require('./OStore')
DB              = require('./DB')
error           = require('./Error').error
ResolveModule   = require('./ResolveModule')

console.log 'supermodel dirname is '+__dirname
console.log(__dirname)
dirname = __dirname.substring(0, __dirname.indexOf('/node_modules'))
if __dirname.indexOf('node_modules') == -1  then dirname = '../..'

console.log 'starting module resolving from path '+dirname
##
## TODO: Make it possible to seed the resolver with path to our reqquirements if we know them beforehand. *might* speed things up eh?
##
resolver = new ResolveModule(dirname)

class SuperModel

  SuperModel.resolver = resolver

  _getRecord:() =>
   rv = @getRecord()
   rv._rev = @._rev
   return rv;

  constructor:(@record)->
    OMgr.storeObject(@)
    if @record._rev then @_rev = @record._rev

  serialize: () =>
    q = defer()
    if not @_serializing
      @_serializing = true
      record = @_getRecord()
      if @_rev then record._rev = @_rev
      OMgr.storeObject(@)
      DB.set(@type, record).then () =>
        @_serializing = false
        q.resolve(@)
      if M.debug then console.log ' * serializing '+@type+" id "+@id
    else
      q.resolve(@)
    return q

  # [ {name: 'zones', type: 'zone', ids: [x, y, z, q] }, .. ]
  loadFromIds:(resolvearr) =>
    alldone = defer()
    allpromises = []
    if(not resolvearr or resolvearr.length == 0)
      console.log ' ++++++++++++++++ NO RESOLVEARR ++++++++++++++'
      q = defer()
      allpromises.push(q)
      q.resolve()
    else
      resolvearr.forEach (robj) =>
        ((resolveobj) =>
          r = defer()
          allpromises.push(r)
          @[resolveobj.name] = [] if resolveobj.array == true
          @[resolveobj.name] = {} if resolveobj.hashtable == true
          if not resolveobj.ids
            #@[resolveobj.name] = []
            resolveobj.ids = []
            if M.debug then console.log '============================== null resolveobj.ids for '+resolveobj.type+' ['+resolveobj.name+']'
            r.resolve(null)
          else
            if typeof resolveobj.ids is 'string'
              resolveobj.ids = [resolveobj.ids]

            if M.debug then console.log ' resolveobjds ('+(typeof resolveobj.ids)+') ids length are.. '+resolveobj.ids.length
            if M.debug then console.dir(resolveobj.ids)
            count = resolveobj.ids.length
            if count == 0
              r.resolve(null)
            else
              resolveobj.ids.forEach (id) =>
                if M.debug then console.log 'trying to get '+resolveobj.type+' with id '+id
                OMgr.getObject(id, resolveobj.type).then (oo) =>
                  if oo
                    @insertObj(resolveobj, oo)
                    if --count == 0 then r.resolve(oo)
                  else
                    DB.get(resolveobj.type,[id]).then (record) =>
                      resolver.createObjectFrom(record).then (obj) =>
                        if M.debug then console.log 'object created: '+obj.id
                        @insertObj(resolveobj, obj)
                        if --count == 0 then r.resolve(obj)
        )(robj)

    all(allpromises, error).then( (results) ->
      alldone.resolve(results)
    ,error)
    return alldone

  insertObj: (ro, o) =>
    if ro.array == true
      @[ro.name].push(o)
    else if ro.hashtable == true
      @[ro.name][o.name] = o
    else
      @[ro.name] = o
    OMgr.storeObject(o)


module.exports = SuperModel;
