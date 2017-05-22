defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')

OMgr            = require('./OStore')
DB              = require('./DB')
error           = require('./Error').error
ResolveModule   = require('./ResolveModule')

resolver = new ResolveModule()


debug = process.env["DEBUG"]

class SuperModel

  SuperModel.resolver = resolver
  SuperModel.prototype.resolver = resolver
  SuperModel.oncreatelisteners = []
  SuperModel.onCreate = (cb)->
    SuperModel.oncreatelisteners.push cb

  constructor:(@record={})->
    #console.log '============================================ SuperModel constructor for '+@record?.id
    #if debug then console.dir @model
    @id         = @record.id or uuid.v4()
    @record = @unPrettify(@record)
    missing = true
    @constructor.model.forEach (mp) =>
      if not @record[mp.name]
        if mp.array == 'true'
          @record[mp.name] = []
        else if mp.hashtable == 'true'
          @record[mp.name] = {}
        else
          #if debug then console.log 'instantiating empty record value for '+mp.name+' with '+mp.default
          if Array.isArray(mp.default)
            @record[mp.name] = []
          else
            @record[mp.name] = mp.default or ' '
      if mp.name == 'createdAt' or mp.name == 'createdBy' then missing = false
    if missing
      @constructor.model.push({ name: 'createdAt',    public: true,   value: 'createdAt' })
      @constructor.model.push({ name: 'modifiedAt',   public: true,   value: 'modifiedAt' })
      @constructor.model.push({ name: 'createdBy',    public: true,   value: 'createdBy' })
      #@updateAllModels()
    @type = @constructor.type
    q = defer()
    OMgr.storeObject(@)
    if @record._rev
      #if debug then console.log 'setting _rev to '+@record._rev+' for '+@constructor.type+' '+@id
      @_rev = @record._rev
    @loadFromIds(@constructor.model).then( () =>
      if (not @createdAt or @createdAt == ' ') then @createdAt = Date.now()
      if (not @modifiedAt or @modifiedAt == ' ') then @modifiedAt = Date.now()
      if (not @createdBy or @createdBy == ' ') then @createdBy = 'SYSTEM'
      if not @record.id then SuperModel.oncreatelisteners.forEach (listener) => listener(@)
      #console.log '============================================ SuperModel constructor after loadFromIds...'
      #console.dir @
      if @postCreate
        if debug then console.log 'calling PostCreate on '+@type+' with deferred '+q
        @postCreate(q)
      else
        #console.log '-- done resolving constructor for '+@constructor.type
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
      #if debug then console.log 'getRecord resolving value '+v.name
      #if debug then console.dir v
      k = v.name
      if (v.value and v.value isnt 0) and v.type # direct object reference
        #if debug then console.log 'getRecord accessing property '+k+' of object '+@type+' -> '+me[k]
        if me[k]
          if v.storedirectly
            rv[k] = me[k]._getRecord(me[k], me[k].constructor.model, me[k].record)
          else
            rv[k] = me[k].id
        else
          rv[k] = null
      else if (v.value and v.value isnt 0) and not v.type
        #if debug then console.log 'direct value '+v.value+' me[v.value] = '+(me[v.value])+' record[k] = '+(record[k])
        rv[k] = me[v.value]
        if not rv[k] and rv[k] isnt 0
          if record and record[k] then rv[k] = record[k] else rv[k] = undefined
      else if v.hashtable
        #if debug then console.log 'hashtable '
        varr = []
        ha = me[v.name] or []
        for hk, hv of ha
          if v.storedirectly
            varr.push hv._getRecord(hv, hv.constructor.model, hv.record)
          else
            #console.log '====================== hashtable prop id is '+hv.id+' typeof '+(typeof hv.id)
            varr.push hv.id
        rv[k] = varr
      else if v.array
        varr = []
        marr = me[v.name] or []
        marr.forEach (av) -> if av and av isnt null and av isnt 'null'
          if v.storedirectly
            varr.push av._getRecord(av, av.constructor.model, av.record)
          else
            if debug then console.log '====================== array prop id is '+av.id+' typeof '+(typeof av.id)
            if av.id then varr.push av.id
        rv[k] = varr
      else
        if debug then console.log '**************** AAAUAGHH!!! property '+k+' was not resolved in SuperModel::_getRecord'

    rv.id = @id
    rv.type = @.constructor.type
    #console.log 'record done for '+me.type
    return rv

  toClient: () =>
    #console.log '---------------------------------------- toClient -----------------------------------------------'
    #console.dir @
    r = @getRecord()
    #console.log 'record is'
    #console.dir r
    ra = @.constructor.model
    rv = {}
    for k,v of r
      ra.forEach (el) =>
        if el.name == k and k != 'record' and el.public
          #console.log 'adding propety '+k
          res = @prettyPrint(k, v)
          #console.dir res
          rv[k] = res
          if not rv[k] and el.default then rv[k] = el.default
    rv.id = @id
    rv.type = @.constructor.type
    return rv

  serialize: (updatedObj) =>
    q = defer()
    if debug then console.log 'SuperModel.serialize called'
    @_serializing = true
    OMgr.storeObject()
    delete updatedObj.record if updatedObj
    #OMgr.updateObj(updatedObj) if updatedObj
    record = @getRecord()
    delete record.record if record.record
    if @_rev then record._rev = @_rev

    #if debug then console.dir record
    #if debug then console.log 'actual object is '
    #if debug then console.dir @
    #if debug then console.log 'toClient is '
    #if debug then console.dir @toClient()
    DB.set @.constructor.type, record, (res) =>
      if debug then console.log ' * serialized and persisted '+@type+" id "+@id
      @_serializing = false
      if res then q.resolve(@) else q.resolve()

    return q

  delete:()=>
    DB.remove(@)

  prettyPrint: (name, value) =>
    rv = value
    #if (name == 'createdAt' or name == 'modifiedAt') and (value and value isnt 0) then rv = new Date(parseInt(value)).toUTCString()
    return rv

  unPrettify: (record) =>
    #TODO: Perhaps if createdBy is used, but it should actually be solved by the client instead (request name for user id referenced)
    record

  loadFromIds:(model) =>
    #console.log '------------------------------------------------> loadfromIds called for '+@.constructor.type+' '+@id+' '+model.length+' properties'
    #console.dir @
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
          #console.log 'SuperModel::loadFromIds for property '+resolveobj.name
          r = defer()
          allpromises.push(r)
          if resolveobj.value
            if resolveobj.type  # direct object reference by id
              #console.log 'direct reference! '+resolveobj.name+' type '+resolveobj.type+' id "'+@record[resolveobj.value]+'" is a space == '+(@record[resolveobj.value] and (@record[resolveobj.value] != ' '))
              if resolveobj.storedirectly
                @createObjectFromRecord(r, resolveobj, 0, @record[resolveobj.value])
              else
                if (@record[resolveobj.value] and (@record[resolveobj.value] != ' '))
                  #console.log '-------------- resolving direct reference'
                  @resolveObj(resolveobj, @record[resolveobj.value], r, 0)
                else
                  #console.log '+++++++++++++++ ugh'
                  #console.dir @record
                  @[resolveobj.name] = null
                  r.resolve(@[resolveobj.name])
            else
              #console.log 'supermodel loadfromids scalar'
              #console.dir resolveobj
              if @record[resolveobj.value]
                @[resolveobj.name] = @record[resolveobj.value] or resolveobj.default  # scalar
              r.resolve(@[resolveobj.name])
          else
            #console.log 'testing for arrays. current value of '+resolveobj.name+' is '+@[resolveobj.name]+' record is "'+@record[resolveobj.name]+'"'
            if resolveobj.array == true
              if (not @[resolveobj.name]) or (Array.isArray(@record[resolveobj.name]) and @record[resolveobj.name].length > 0)
                #console.log 'resolveobjids -- setting empty array for '+resolveobj.name+' since either the property is currently undefined or the array records contain at least one reference which will be added on resolving'
                @[resolveobj.name] = []
            if ((resolveobj.hashtable == true) and (not @[resolveobj.name])) then @[resolveobj.name] = {}
            #if resolveobj.name == 'foos' then console.log 'foos is now '+@[resolveobj.name]
            #if resolveobj.name == 'foos' then console.dir @[resolveobj.name]
            ids = @record[resolveobj.ids]
            if not ids or typeof ids == 'undefined' or ids == 'undefined'
              ids = []
              #console.log '============================== null resolveobj.ids for '+resolveobj.type+' ['+resolveobj.name+']'
              r.resolve()
            else    # array or hashtable by array of ids
              if typeof ids is 'string'
                ids = [ids]
              if Array.isArray(ids)
                ids = ids.filter (ii) ->  ii and ii isnt null and ii isnt "null" and ii isnt "undefined"
              else
                temp = {}
                for x,y of ids
                  if y and y isnt null and y isnt "null" and y isnt "undefined" then temp[x] = y
                ids = temp
              count = ids.length
              #console.log 'ids.length  ->  '+ids.length
              if (not count and count != 0)
                #console.log 'no ids for '+resolveobj.name+' so resolving undefined'
                r.resolve(undefined)
              else if count == 0
                #console.log 'resolving [] for '+resolveobj.name+' since empty array in record'
                @[resolveobj.name] = []
                r.resolve([])
              else
                ids.forEach (_id) =>
                  ((id) =>
                    --count
                    if resolveobj.storedirectly
                      #console.log '** storedirectly creating array or hash object immediately..'
                      @createObjectFromRecord(r, resolveobj, count, id)
                    else
                      #console.log 'SuperModel loadFromIds trying to get '+resolveobj.name+' with id "'+id+'"'
                      if (!id or id == ' ') and @[resolveobj.name]
                        #console.log 'resolving existing array for '+resolveobj.name+' since this was empty'
                        #console.dir @[resolveobj.name]
                        r.resolve(@[resolveobj.name])
                      else
                        #console.log 'calling resolveObj for id '+id
                        @resolveObj(resolveobj, id, r, count)
                  )(_id)
              #console.log 'resolveobjids '+resolveobj.name+' ('+(typeof ids)+') ids length are.. '+ids.length
              #console.dir ids

          #if debug then console.log '------- property '+resolveobj.name+' now set to '+@[resolveobj.name]
        )(robj)

    all(allpromises, error).then( (results) =>
      #console.log '<------------------------------------------------ loadfromIds done for '+@.constructor.type+' '+@id+' '+model.length+' properties'
      #console.dir results
      alldone.resolve(results)
    ,error)
    return alldone

  resolveObj: (resolveobj, id, r, count) =>
    if typeof id != 'string'
      console.log '%%%%%%%%%%%%%%%%%%% ERROR: Supermodel.resolveObj given a non-string as id!! resolveObj was:'
      console.dir resolveobj
      console.log 'id was:'
      console.dir id
      process.exit(-1)
    #console.log '************************************* resolveObj called in '+@type+' for id '+id+' typeof '+(typeof id)
    #console.dir id
    OMgr.getObject(id, resolveobj.type).then( (oo) =>
      if oo
        #console.log 'SuperModel found existing instance of '+resolveobj.name+' type '+resolveobj.type+' in OStore'
        @insertObj(resolveobj, oo)
        if count == 0
          #console.log 'SuperModel resolving '+resolveobj.name+' type '+resolveobj.type+' immediately'
          #console.dir oo
          r.resolve(oo)
      else
        if debug then console.log 'SuperModel did not find obj '+resolveobj.name+' ['+id+'] of type '+resolveobj.type+' in OStore. Getting from DB. typeof of id prop is '+(typeof id)
        #console.dir resolveobj
        DB.get(resolveobj.type, [id]).then( (records) =>
          record = undefined
          if records and records[0] then record = records[0]
          #console.log 'supermodel resolveObj got back from DB.get '+record
          if not record
            #console.log 'SuperModel::loadFromIds got back null record from DB for type '+resolveobj.type+' and id '+id
            #console.log 'current content is'
            #console.dir @[resolveobj.name]
            if count == 0 then r.resolve(@[resolveobj.name])
          else
            #console.log '** resolveObj no obj found and no record for id '+id+' type '+resolveobj.type
            if not id or not resolveobj.type
              r.resolve(null)
            else
              #console.log 'calling createObjectFromRecord for '+id+' type '+resolveobj.type
              @createObjectFromRecord(r, resolveobj, count, record)
        , error)
    , error)

  createObjectFromRecord: (r, resolveobj, count, record)=>
    #if debug then console.log '################################## supermodel createObjectFromRecord called'
    #if debug then console.dir resolveobj
    #if debug then console.log 'record.....'
    #if debug then console.dir record
    if (Array.isArray(record))
      throw(new Error('got array instead of record in supermodel createObjectFromRecord !!!'))

    if record and record.type
      SuperModel.resolver.createObjectFrom(record).then( (obj) =>
        if not obj
          #console.log ' Hmm. Missing object reference. Sad Face.'
          #console.dir record
          if count == 0 then r.resolve(null)
        else
          #console.log 'object '+resolveobj.name+' type '+resolveobj.type+' created: '+obj.id
          @insertObj(resolveobj, obj)
          if count == 0
            #console.log '---- count zero'
            r.resolve(obj)
      , error)
    else
      r.resolve()

  insertObj: (ro, o) =>
    OMgr.storeObject(o)
    if ro.array == true
      #if debug then console.log 'inserting obj '+ro.type+' as array'
      @[ro.name].push(o)
    else if ro.hashtable == true
      #if debug then console.log 'inserting obj '+ro.type+' as hashtable'
      if ro.keyproperty then property = ro.keyproperty else property = 'name'
      @[ro.name][o[property]] = o
    else
      #if debug then console.log 'inserting obj '+ro.type+' as direct reference'
      @[ro.name] = o
    OMgr.storeObject(o)


module.exports = SuperModel;
