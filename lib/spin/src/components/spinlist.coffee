define(['ractive', 'components/listelement'], (Ractive, listelement) =>
  spinlist = Ractive.extend({
    components: {listelement: listelement}
    isolated: false,
    data: () ->
      list: []
      header: 'List'
      labels: 'name'
      getLabelFor: (i) ->
        el = this.get 'list.'+i
        rv = ''
        this.get('labels').split(',').forEach (label)-> rv += el[label]
        rv
    template: """
      <h4>{{header}}</h4>
      <ul class="mdl-list">
      {{#list:i}}
        <li class="mdl-list__item">{{ getLabelFor(i) }}</li>
      {{/}}
      </ul>
      """
  })
  console.log 'spinlist defined'
  return spinlist
)

