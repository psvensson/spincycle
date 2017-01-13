SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

console.log('----- SuperModel require for SpinTag is ')
console.dir(SuperModel)

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