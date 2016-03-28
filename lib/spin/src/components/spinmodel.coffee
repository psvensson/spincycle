define(['ractive'], (Ractive) =>
  spinmodel = Ractive.extend({
    isolated: false,

    data: () ->
      model: ''
      getPropertyFor: (prop) => @get('model')[prop]

    template: '
    <div>
      {{#model:prop}}
        <div>{{prop}} - {{getPropertyFor(prop)}}</div>
      {{/model}}
    </div>'
  })
  console.log 'spinmodel defined'
  return spinmodel
)

