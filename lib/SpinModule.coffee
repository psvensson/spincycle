SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinModule extends SuperModel

  @type       = 'SpinModule'
  @model =
    [
      {name: 'name',        public: true,   value: 'name', default: 'Spin Module' }
      { name: 'inputs',     public: true,   array: true,  type: 'SpinFunction',  ids: 'inputs' }
      { name: 'outputs',    public: true,   array: true,  type: 'SpinModule',  ids: 'outputs' }
    ]

  constructor: (@record) ->
    return super

  postCreate: (q) =>
      q.resolve(@)



module.exports = SpinModule