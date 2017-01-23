SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinTag extends SuperModel
  @type       = 'SpinTag'
  @model =
    [
      { name: 'name',         public: true,   value: 'name',    default: 'foo' }
      { name: 'modelRef',     public: true,   value: 'modelRef'}
      { name: 'modelType',    public: true,   value: 'modelType'}
    ]

  constructor: (@record={}) ->
    return super

  postCreate: (q) =>
    q.resolve(@)


module.exports = SpinTag