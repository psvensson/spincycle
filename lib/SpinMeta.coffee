SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinMeta extends SuperModel
  @type       = 'SpinMeta'
  @model =
    [
      { name: 'knownModels',    public: true,   value: 'knownModels',    default: ['SpinApp','SpinModule','SpinFunction','SpinTag'] }
    ]

  constructor: (@record={}) ->
    return super

  postCreate: (q) =>
    q.resolve(@)


module.exports = SpinMeta