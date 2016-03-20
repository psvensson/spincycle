define(['ractive'], (Ractive) =>
  listelement = Ractive.extend({
    isolated: false,
    template: '<div>Bar</div>'
  })
  console.log 'listelement defined'
  return listelement
)

