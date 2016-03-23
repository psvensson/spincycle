define(['ractive', 'components/listelement'], (Ractive, listelement) =>
  spinlist = Ractive.extend({
    components: {listelement: listelement}
    isolated: false,
    data: () ->
      list: []
      header: 'List'
      labels: 'name'
      onSelected: ''
      getLabelFor: (i) ->
        el = this.get 'list.'+i
        rv = ''
        this.get('labels').split(',').forEach (label)-> rv += el[label]
        rv
    oninit: () ->
      @on 'itemSelected', (e) ->
        select = @get('onSelected')
        if select then select(e)
    template: """
      <div style='display:flex; flex-direction: column'>
        <h4 style='margin-bottom:0'>{{header}}</h4>
        <ul class="mdl-list" style='margin-top:0'>
        {{#list:i}}
          <li class="mdl-list__item" on-click='itemSelected'>{{ getLabelFor(i) }}</li>
        {{/}}
        </ul>
      </div>
      """
  })
  console.log 'spinlist defined'
  return spinlist
)

