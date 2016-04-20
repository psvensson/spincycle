define(['ractive', 'components/mdldialog'], (Ractive, mdldialog) =>

  spinlist = Ractive.extend({
    components: {mdldialog: mdldialog}
    isolated: false

    data: () ->
      list: []
      guid: ''
      header: 'List'
      labels: 'name'
      onSelected: ''
      onDeleted: ''
      getLabelFor: (i) ->
        el = this.get 'list.'+i
        rv = ''
        if el then this.get('labels').split(',').forEach (label)-> rv += el[label]
        rv

    oninit: () ->
      console.log 'spinlist created'
      @set('guid', @_guid)
      console.dir @get('list')
      @on 'itemSelected', (e) =>
        console.log 'spinlist onselected'
        selected = @get('onSelected')
        console.dir selected
        if selected then selected(e)
      @on 'deleted', (e) ->
        console.log('* item delete clicked')
        deleted = @get('onDeleted')
        if deleted then deleted(e)

    onDialogItemSelected:(e) ->
      console.log 'onDialogItemSelected'
      console.dir e

    onSelectModel: ()->
      console.log 'open model selection dialog'
      window.publish 'modeldialogopen', {cb: @onDialogItemSelected, type: @get('type') }

    template: """
      <div style='display:flex; flex-direction: column'>
        <h4 style='margin-bottom:0'>{{header}}</h4>
        <ul class="mdl-list" style='margin-top:0'>
          {{#list:i}}
          <div style='display:flex; flex-direction: row'>
            <i on-click="deleted" class="mdl-color-text--blue-grey-400 material-icons" role="presentation">delete</i>
            <li class="mdl-list__item" style="min-height:30px; padding-top:0; padding-bottom:0" on-click='itemSelected'>{{ getLabelFor(i) }}</li>
          </div>
        {{/}}
        </ul>
      </div>
      """
  })
  console.log 'spinlist defined'
  return spinlist
)

