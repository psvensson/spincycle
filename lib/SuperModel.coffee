defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')

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
debug = process.env["DEBUG"]

class SuperModel

  SuperModel.resolver = resolver

  _getRecord:() =>
   rv = @getRecord()
   rv._rev = @._rev
   return rv;

  constructor:(@record={})->
    #console.log 'SuperModel constructor'
    #console.dir @model
    @type = @constructor.type
    q = defer()
    @id         = @record.id or uuid.v4()
    OMgr.storeObject(@)
    if @record._rev
      if debug then console.log 'setting _rev to '+@record._rev+' for '+@constructor.type+' '+@id
      @_rev = @record._rev

    @loadFromIds(@constructor.model).then( () =>
      if @postCreate
        @postCreate(q)
      else
        q.resolve(@)
    , error)
    if debug then console.log 'returning promise from constructor for '+@constructor.type
    return q

  getRecord: () =>
    @._getRecord(@, @constructor.model, @record)

  _getRecord: (me, model, record) ->
    rv = {}
    rv._rev = @_rev if @_rev
    if not model
      console.dir me
    model.forEach (v) ->
      k = v.name
      if v.value then rv[k] = me[v.value] or record[k]
      else if v.hashtable
        varr = []
        for hk, hv of me[v.name]
          varr.push hv.id
        rv[k] = varr
      else if v.array
        varr = []
        me[v.name].forEach (hv) -> varr.push hv.id
        rv[k] = varr
      else # direct object reference
        if debug then console.log 'getRecord accessing property '+k+' of object '+@type+' -> '+me[k]
        rv[k] = me[k]?.id

    rv.id = @id
    rv.type = @.constructor.type
    return rv

  toClient: () =>
    r = @getRecord()
    ra = @.constructor.model
    rv = {}
    for k,v of r
      ra.forEach (el) ->
        if el.name == k and el.public then rv[k] = v
    rv.id = @id
    rv.type = @.constructor.type
    return rv

  serialize: () =>
    q = defer()
    if not @_serializing
      @_serializing = true
      record = @getRecord()
      if @_rev then record._rev = @_rev
      OMgr.storeObject(@)
      DB.set(@.constructor.type, record).then () =>
        @_serializing = false
        q.resolve(@)
      #if debug then console.log ' * serializing '+@type+" id "+@id
    else
      q.resolve(@)
    return q

  loadFromIds:(model) =>
    if debug then console.log '------------------------------------------------> loadfromIds called for '+@.constructor.type+' '+@id+' '+model.length+' properties'
    #if debug then console.dir(model)
    #if debug then console.log 'record is...'
    #if debug then console.dir @record
    alldone = defer()
    allpromises = []
    if(not model or model.length == 0)
      #console.log ' ++++++++++++++++ NO model ++++++++++++++'
      q = defer()
      allpromises.push(q)
      q.resolve()
    else
      model.forEach (robj) =>
        ((resolveobj) =>
          r = defer()
          allpromises.push(r)
          if resolveobj.value
            #console.log '++ @record[resolveobj.value] = '+@record[resolveobj.value]+' and resolveobj.default = '+resolveobj.default
            @[resolveobj.name] = @record[resolveobj.value] or resolveobj.default
          @[resolveobj.name] = [] if resolveobj.array == true
          @[resolveobj.name] = {} if resolveobj.hashtable == true
          ids = @record[resolveobj.ids]
          if not ids or typeof ids == 'undefined' or ids == 'undefined'
            #@[resolveobj.name] = []
            ids = []
            if debug then console.log '============================== null resolveobj.ids for '+resolveobj.type+' ['+resolveobj.name+']'
            r.resolve(null)
          else
            if typeof ids is 'string'
              #if debug then console.log 'upcasting string id to array of ids for '+resolveobj.name
              ids = [ids]
            if debug then console.log 'resolveobjds '+resolveobj.name+' ('+(typeof ids)+') ids length are.. '+ids.length
            count = ids.length
            if count == 0
              if debug then console.log 'no ids for '+resolveobj.name+' so resolving null'
              r.resolve(null)
            else
              ids.forEach (id) =>
                if debug then console.log 'trying to get '+resolveobj.name+' with id '+id
                OMgr.getObject(id, resolveobj.type).then( (oo) =>
                  if oo
                    if debug then console.log 'found existing instance of '+resolveobj.name+' type '+resolveobj.type+' in OStore'
                    @insertObj(resolveobj, oo)
                    if --count == 0
                      if debug then console.log 'resolving '+resolveobj.name+' type '+resolveobj.type+' immediately'
                      r.resolve(oo)
                  else
                    if debug then console.log 'did not find obj '+resolveobj.name+' of type '+resolveobj.type+' in OStore. Getting from DB...'
                    DB.get(resolveobj.type,[id]).then( (record) =>
                      resolver.createObjectFrom(record).then( (obj) =>
                        if debug then console.log 'object '+resolveobj.name+' type '+resolveobj.type+' created: '+obj.id
                        @insertObj(resolveobj, obj)
                        if --count == 0 then r.resolve(obj)
                      , error)
                    , error)
                , error)
          #console.log '------- property '+resolveobj.name+' now set to '+@[resolveobj.name]
        )(robj)

    all(allpromises, error).then( (results) =>
      if debug then console.log '<------------------------------------------------ loadfromIds done for '+@.constructor.type+' '+@id+' '+model.length+' properties'
      alldone.resolve(results)
    ,error)
    return alldone

  insertObj: (ro, o) =>
    if ro.array == true
      if debug then console.log 'inserting obj '+ro.type+' as array'
      @[ro.name].push(o)
    else if ro.hashtable == true
      if debug then console.log 'inserting obj '+ro.type+' as hashtable'
      @[ro.name][o.name] = o
    else
      if debug then console.log 'inserting obj '+ro.type+' as direct reference'
      @[ro.name] = o
    OMgr.storeObject(o)


module.exports = SuperModel;
