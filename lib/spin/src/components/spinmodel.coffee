define(['ractive'], (Ractive) =>
  spinmodel = Ractive.extend({
    isolated: false,

    data: () ->
      model: ''
      getPropertyFor: (prop) => @get('model')[prop]

    template: '
    <div>
      {{#model:prop}}
        <div>
          array = {{prop.array}}
          {{#!prop.array}}
            {{prop}} - {{getPropertyFor(prop)}}
          {{/}}
          {{#prop.array}}
            <button on-click="onSelectModel()" class="mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect">
              Select {{type}}
            </button>
            <spinlist list="{{getPropertyFor(prop)}}" header="{{prop.type}}" onSelected="{{onSelected}}" onDeleted="{{onDeleted}}"></spinlist>
          {{/}}
        </div>
      {{/model}}
    </div>'
  })
  console.log 'spinmodel defined'
  return spinmodel
)

