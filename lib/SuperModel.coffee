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
  SuperModel.prototype.resolver = resolver
  SuperModel.oncreatelisteners = []
  SuperModel.onCreate = (cb)->
    SuperModel.oncreatelisteners.push cb

  _getRecord:() =>
   rv = @getRecord()
   rv._rev = @._rev
   return rv;

  constructor:(@record={})->
    #console.log 'SuperModel constructor'
    #console.dir @model
    @id         = @record.id or uuid.v4()
    @record = @unPrettify(@record)

    missing = true
    @constructor.model.forEach (mp) -> if mp.name == 'createdAt' or mp.name == 'createdBy' then missing = false
    if missing
      @constructor.model.push({ name: 'createdAt',    public: true,   value: 'createdAt' })
      @constructor.model.push({ name: 'modifiedAt',   public: true,   value: 'modifiedAt' })
      @constructor.model.push({ name: 'createdBy',    public: true,   value: 'createdBy' })
      #@updateAllModels()
      SuperModel.oncreatelisteners.forEach (listener) -> listener(@)

    @createdAt = @createdAt or Date.now()

    @type = @constructor.type
    q = defer()

    OMgr.storeObject(@)
    if @record._rev
      #if debug then console.log 'setting _rev to '+@record._rev+' for '+@constructor.type+' '+@id
      @_rev = @record._rev

    @loadFromIds(@constructor.model).then( () =>
      if not @createdAt then @createdAt = Date.now()
      if @postCreate
        @postCreate(q)
      else
        #if debug then console.log '-- done resolving constructor for '+@constructor.type
        q.resolve(@)
    , error)
    return q

  getRecord: () =>
    @._getRecord(@, @constructor.model, @record)

  _getRecord: (me, model, record) ->
    #console.log '_getRecord for '+me.type+' id '+me.id
    rv = {}
    rv._rev = @_rev if @_rev
    model.forEach (v) =>
      k = v.name
      if (v.value and v.value isnt 0) and v.type # direct object reference
        if debug then console.log 'getRecord accessing property '+k+' of object '+@type+' -> '+me[k]
        if me[k]
          if v.storedirectly
            rv[k] = me[k]._getRecord(me[k], me[k].constructor.model, me[k].record)
          else
            rv[k] = me[k].id
      else if (v.value and v.value isnt 0) and not v.type
        #if debug then console.log 'direct value '+v.value+' me[v.value] = '+(me[v.value])+' record[k] = '+(record[k])
        rv[k] = me[v.value]
        if not rv[k] and rv[k] isnt 0 then rv[k] = record[k]
      else if v.hashtable
        #if debug then console.log 'hashtable '
        varr = []
        ha = me[v.name] or []
        for hk, hv of ha
          if v.storedirectly
            varr.push hv._getRecord(hv, hv.constructor.model, hv.record)
          else
            #console.log '====================== array prop id is '+hv.id+' typeof '+(typeof hv.id)
            varr.push hv.id
        rv[k] = varr
      else if v.array
        #if debug then console.log 'direct array'
        varr = []
        marr = me[v.name] or []
        marr.forEach (av) -> if av and av isnt null and av isnt 'null'
          if v.storedirectly
            varr.push av._getRecord(av, av.constructor.model, av.record)
          else
            #console.log '====================== hashtable prop id is '+av.id+' typeof '+(typeof av.id)
            varr.push av.id
        rv[k] = varr
      else
        if debug then console.log '**************** AAAUAGHH!!! property '+k+' was not resolved in SuperMOde::_getRecord'

    rv.id = @id
    rv.type = @.constructor.type
    #console.log 'record done for '+me.type
    return rv

  toClient: () =>
    #if debug then console.log '---------------------------------------- toClient -----------------------------------------------'
    #if debug then console.dir @
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
      delete updatedObj.record if updatedObj
      OMgr.updateObj(updatedObj) if updatedObj
      record = @getRecord()
      delete record.record if record.record
      if @_rev then record._rev = @_rev
      DB.set(@.constructor.type, record).then () =>
        if debug then console.log ' * serialized and persisted '+@type+" id "+@id
        @_serializing = false
        q.resolve(@)
    else
      q.resolve(@)
    return q

  prettyPrint: (name, value) =>
    rv = value
    #if (name == 'createdAt' or name == 'modifiedAt') and (value and value isnt 0) then rv = new Date(parseInt(value)).toUTCString()
    return rv

  unPrettify: (record) =>
    #TODO: Perhaps if createdBy is used, but it should actually be solved by the client instead (request name for user id referenced)
    record

  loadFromIds:(model) =>
    #if debug then console.log '------------------------------------------------> loadfromIds called for '+@.constructor.type+' '+@id+' '+model.length+' properties'
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
          #if debug then console.log 'resolveobj '+resolveobj.name
          r = defer()
          allpromises.push(r)
          if resolveobj.value
            if resolveobj.type  # direct object reference by id
              #if debug then console.log 'supermodel creating direct reference of type '+resolveobj.type+', value '+resolveobj.value+' name '+ resolveobj.name + ' id '+@record['id']
              #if debug then console.dir @record[resolveobj.value]
              #if debug then console.dir @record
              if resolveobj.storedirectly
                #console.log '** storedirectly creating direct reference object immediately. ro value is '+resolveobj.value
                #console.dir @record
                #console.log 'value is...'
                #console.dir @record[resolveobj.value]
                @createObjectFromRecord(r, resolveobj, 0, @record[resolveobj.value])
              else
                if @record[resolveobj.value]
                  @resolveObj(resolveobj, @record[resolveobj.value], r, 0)
                else
                  @[resolveobj.name] = null
                  r.resolve(@[resolveobj.name])
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
              ids = ids.filter (ii) ->  ii and ii isnt null and ii isnt "null" and ii isnt "undefined"
              #if debug then console.log 'resolveobjids '+resolveobj.name+' ('+(typeof ids)+') ids length are.. '+ids.length
              #if debug then console.dir ids
              count = ids.length
              if count == 0
                if debug then console.log 'no ids for '+resolveobj.name+' so resolving null'
                r.resolve(null)
              else
                  ids.forEach (_id) =>
                    ((id) =>
                      --count
                      if resolveobj.storedirectly
                        #console.log '** storedirectly creating array or hash object immediately..'
                        @createObjectFromRecord(r, resolveobj, count, id)
                      else
                        #if debug then console.log 'SuperModel loadFromIds trying to get '+resolveobj.name+' with id '+id
                        @resolveObj(resolveobj, id, r, count)
                    )(_id)
          #if debug then console.log '------- property '+resolveobj.name+' now set to '+@[resolveobj.name]
        )(robj)

    all(allpromises, error).then( (results) =>
      #if debug then console.log '<------------------------------------------------ loadfromIds done for '+@.constructor.type+' '+@id+' '+model.length+' properties'
      alldone.resolve(results)
    ,error)
    return alldone

  resolveObj: (resolveobj, id, r, count) =>
    #console.log '************************************* resolveObj called in '+@type+' for id '+id+' typeof '+(typeof id)
    #console.dir id
    OMgr.getObject(id, resolveobj.type).then( (oo) =>
      if oo
        if debug then console.log 'found existing instance of '+resolveobj.name+' type '+resolveobj.type+' in OStore'
        @insertObj(resolveobj, oo)
        if count == 0
          if debug then console.log 'resolving '+resolveobj.name+' type '+resolveobj.type+' immediately'
          r.resolve(oo)
      else
        if debug then console.log 'did not find obj '+resolveobj.name+' ['+id+'] of type '+resolveobj.type+' in OStore. Getting from DB. typeof of id prop is '+(typeof id)
        DB.get(resolveobj.type, [id]).then( (record) =>
          if not record
            console.log 'SuperModel::loadFromIds got back null record from DB for type '+resolveobj.type+' and id '+id
            if count == 0 then r.resolve(null)
          else
            if debug then console.log '** resolveObj no obj found and no record for id '+id
            @createObjectFromRecord(r, resolveobj, count, record)
        , error)
    , error)

  createObjectFromRecord: (r, resolveobj, count, record)=>
    #console.log '################################## supermodel createObjectFromRecord called'
    #console.dir resolveobj
    #console.log 'record.....'
    #console.dir record
    SuperModel.resolver.createObjectFrom(record).then( (obj) =>
      if not obj
        #console.log ' Hmm. Missing object reference. Sad Face.'
        #console.dir record
        if count == 0 then r.resolve(null)
      else
        if debug then console.log 'object '+resolveobj.name+' type '+resolveobj.type+' created: '+obj.id
        @insertObj(resolveobj, obj)
        if count == 0 then r.resolve(obj)
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
