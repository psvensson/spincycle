define(['spinclient', 'ractive', 'components/spinlist'], (spinclient, Ractive, spinlist) =>

  modelspinlist = Ractive.extend({
    components: {spinlist: spinlist}
    isolated: false,

    data: () ->
      type: ''
      onSelected: ''
      list: []
      skipamount: 10
      limit: 10
      selectedindex: 0
      qprop: 'name'
      qval: ''

      getListForModel: () =>
        console.log 'getListForModel'
        q = {property: @get('qprop'), value: @get('qval') or '', limit: @get('limit'), skip: @get('skipamount')*@get('selectedindex')}
        console.log '---- query sent to server is..'
        console.dir q
        spinclient.emitMessage({ target:'_list'+@get('type')+'s', query: q}).then (newlist) =>
          console.log '* search got back list of '+newlist.length+' items'
          tmp = []
          newlist.forEach (item)->
            spinclient.objects[item.id] = item
            tmp.push item
          @set('list',tmp)

      onDeleted: (_o) =>
        o = _o.context
        type = @get('type')
        console.log 'delete model clicked for '+o.id
        console.dir o
        spinclient.emitMessage({ target:'_delete'+type, obj: {type: type, id: o.id}}).then (dres) ->
          console.log 'delete result'
          console.dir dres

    #---------------------------------------------------------------------------

    oninit: () ->
      console.log 'modelspinlist oninit'
      @on 'onSelected', (e) ->
        select = @get('onSelected')
        if select then select(e)

      @get('getListForModel')()

      type = @get('type')
      spinclient.emitMessage({ target:'registerForPopulationChangesFor', type: type }).then () -> console.log 'registered for population changed for type '+type
      spinclient.registerListener({
        message: 'POPULATION_UPDATE', callback: (update)=>
          console.log 'got population update callback'
          console.dir update
          list = @get('list')
          if update.added
            list.push update.added
            @set('list', list)
          else
            idx = -1
            list.forEach (el,i) -> if el.id == update.removed.id then idx = i
            if idx > -1 then list.splice(idx,1)
            @set('list', list)
      })

    onNewModel: () ->
      console.log 'new model clicked'
      type = @get('type')
      spinclient.emitMessage({ target:'_create'+type, obj: {type: type}}).then (newmodel) ->
        console.log 'create result'
        console.dir newmodel



    template: """
      <div style='display:flex; flex-direction: column'>
        <button on-click='onNewModel()' class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
          New {{type}}
        </button>
        <spinlist list='{{list}}' header="{{type}}" onSelected='{{onSelected}}' onDeleted='{{onDeleted}}'></spinlist>
      </div>
      """
  })
  console.log 'modelspinlist defined'
  return modelspinlist
)

