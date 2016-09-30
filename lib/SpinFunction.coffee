SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinFunction extends SuperModel

  @type       = 'SpinFunction'
  @model =
    [
      {name: 'name',        public: true,   value: 'name',    default: 'Spin Function' }
      {name: 'code',        public: true,   value: 'code',    default: ' ' }
      {name: 'version',     public: true,   value: 'version', default: '0.1' }
    ]

  constructor: (@record) ->
    return super

  postCreate: (q) =>
    q.resolve(@) 


    

module.exports = SpinFunction