SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinModule extends SuperModel

  @type       = 'SpinModule'
  @model =
    [
      {name: 'name',        public: true,   value: 'name', default: 'Spin Module' }
      # input elements look like; { name: 'xxx', destinationModule: 'yyyy', destinationFunction: 'zzzz'}
      # This way it's easy to support modules in modules hierarchically. Default is that a module input goes to one of tis own functions, but
      # It's now very simple to just refer to another modules and a function in that, if needed.
      { name: 'inputs',     public: true,   value: 'inputs', default: [] }
      { name: 'outputs',    public: true,   array: true,  type: 'SpinModule',  ids: 'outputs' }
    ]

  constructor: (@record) ->
    return super

  postCreate: (q) =>
      q.resolve(@) 



module.exports = SpinModule