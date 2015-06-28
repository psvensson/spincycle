defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')

OMgr            = require('./OStore')
DB              = require('./DB')
error           = require('./Error').error
ResolveModule   = require('./ResolveModule')


##
## TODO: Make it possible to seed the resolver with path to our reqquirements if we know them beforehand. *might* speed things up eh?
##
resolver = new ResolveModule()
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
    @id         = @record.id or uuid.v4()

    # populate 'aggregate' list object for all_* in OStore so that it can be subscribed to
    obj =
    {
      id: 'all_'+@constructor.type
      list: [@.id]
      getRecord: ()->
        obj
    }
    OMgr.getObject('all_'+@constructor.type, @constructor.type).then (oo) =>
      if oo
        if debug then console.log 'adding '+@constructor.type+' id '+@id+' to all_ list'
        oo.list.push @.id
        console.dir oo
        OMgr.updateObj(oo)
      else
        if debug
          console.log 'creating original all_'+@constructor.type+' list object'
          console.dir obj
        OMgr.storeObject(obj)

    @record = @unPrettify(@record)
    missing = true
    @constructor.model.forEach (mp) -> if mp.name == 'createdAt' then missing = false
    if missing
      @constructor.model.push({ name: 'createdAt',    public: true,   value: 'createdAt' })
      @constructor.model.push({ name: 'modifiedAt',   public: true,   value: 'modifiedAt' })
      @constructor.model.push({ name: 'createdBy',    public: true,   value: 'createdBy' })

    @type = @constructor.type
    q = defer()

    OMgr.storeObject(@)
    if @record._rev
      #if debug then console.log 'setting _rev to '+@record._rev+' for '+@constructor.type+' '+@id
      @_rev = @record._rev

    @loadFromIds(@constructor.model).then( () =>
      if @postCreate
        @postCreate(q)
      else
        q.resolve(@)
    , error)
    #if debug then console.log 'returning promise from constructor for '+@constructor.type
    return q

  getRecord: () =>
    @._getRecord(@, @constructor.model, @record)

  _getRecord: (me, model, record) ->
    rv = {}
    rv._rev = @_rev if @_rev
    model.forEach (v) ->
      k = v.name
      if v.value then rv[k] = me[v.value] or record[k]
      else if v.hashtable
        varr = []
        ha = me[v.name] or []
        for hk, hv of ha
          varr.push hv.id
        rv[k] = varr
      else if v.array
        varr = []
        marr = me[v.name] or []
        marr.forEach (hv) -> varr.push hv.id
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
      ra.forEach (el) =>
        if el.name == k and k != 'record' and el.public
          res = @prettyPrint(k, v)
          #if debug then console.log 'toClient '+k+' -> '+res
          rv[k] = res
    rv.id = @id
    rv.type = @.constructor.type
    return rv

  serialize: (updatedObj) =>
    q = defer()
    if not @_serializing
      @_serializing = true
      OMgr.storeObject()
      OMgr.updateObj(updatedObj) if updatedObj
      record = @getRecord()
      if @_rev then record._rev = @_rev
      DB.set(@.constructor.type, record).then () =>
        @_serializing = false
        q.resolve(@)
      #if debug then console.log ' * serializing '+@type+" id "+@id
    else
      q.resolve(@)
    return q

  prettyPrint: (name, value) =>
    rv = value
    if (name == 'createdAt' or name == 'modifiedAt') and value then rv = new Date(parseInt(value)).toUTCString()
    return rv

  unPrettify: (record) =>
    #TODO: Perhaps if createdBy is used, but it should actually be solved by the client instead (request name for user id referenced)
    record

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
            if resolveobj.type
              if debug then console.log 'supermodel creating direct reference of type '+resolveobj.type+', value '+resolveobj.value+' object '+ @record[resolveobj.value]
              if debug then console.dir @record[resolveobj.value]
              @resolveObj(resolveobj, @record[resolveobj.value], r, 0)                 # direct object reference by id
            else
              @[resolveobj.name] = @record[resolveobj.value] or resolveobj.default  # scalar
            r.resolve(@[resolveobj.name])
          else
            @[resolveobj.name] = [] if resolveobj.array == true
            @[resolveobj.name] = {} if resolveobj.hashtable == true
            ids = @record[resolveobj.ids]
            if not ids or typeof ids == 'undefined' or ids == 'undefined'
              ids = []
              #if debug then console.log '============================== null resolveobj.ids for '+resolveobj.type+' ['+resolveobj.name+']'
              r.resolve(null)
            else                                                                    # array or hashtable by array of ids
              if typeof ids is 'string'
                ids = [ids]
              if debug then console.log 'resolveobjds '+resolveobj.name+' ('+(typeof ids)+') ids length are.. '+ids.length
              count = ids.length
              if count == 0
                if debug then console.log 'no ids for '+resolveobj.name+' so resolving null'
                r.resolve(null)
              else
                ids.forEach (_id) =>
                  ((id) =>
                    if debug then console.log 'SuperModel loadFromIds trying to get '+resolveobj.name+' with id '+id
                    @resolveObj(resolveobj, id, r, --count)
                  )(_id)
          #if debug then console.log '------- property '+resolveobj.name+' now set to '+@[resolveobj.name]
        )(robj)

    all(allpromises, error).then( (results) =>
      if debug then console.log '<------------------------------------------------ loadfromIds done for '+@.constructor.type+' '+@id+' '+model.length+' properties'
      alldone.resolve(results)
    ,error)
    return alldone

  resolveObj: (resolveobj, id, r, count) =>
    OMgr.getObject(id, resolveobj.type).then( (oo) =>
      if oo
        if debug then console.log 'found existing instance of '+resolveobj.name+' type '+resolveobj.type+' in OStore'
        @insertObj(resolveobj, oo)
        if count == 0
          if debug then console.log 'resolving '+resolveobj.name+' type '+resolveobj.type+' immediately'
          r.resolve(oo)
      else
        if debug then console.log 'did not find obj '+resolveobj.name+' ['+id+'] of type '+resolveobj.type+' in OStore. Getting from DB...'
        DB.get(resolveobj.type, [id]).then( (record) =>
          if not record
            console.log 'SuperModel::loadFromIds got back null record from DB for type '+resolveobj.type+' and id '+id
            if count == 0 then r.resolve(null)
          else resolver.createObjectFrom(record).then( (obj) =>
            if not obj
              console.log ' Hmm. Missing object reference. Sad Face.'
              if count == 0 then r.resolve(null)
            else
              if debug then console.log 'object '+resolveobj.name+' type '+resolveobj.type+' created: '+obj.id
              @insertObj(resolveobj, obj)
              if count == 0 then r.resolve(obj)
          , error)
        , error)
    , error)

  insertObj: (ro, o) =>
    if ro.array == true
      #if debug then console.log 'inserting obj '+ro.type+' as array'
      @[ro.name].push(o)
    else if ro.hashtable == true
      #if debug then console.log 'inserting obj '+ro.type+' as hashtable'
      @[ro.name][o.name] = o
    else
      #if debug then console.log 'inserting obj '+ro.type+' as direct reference'
      @[ro.name] = o
    OMgr.storeObject(o)


module.exports = SuperModel;
