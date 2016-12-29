SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinApp extends SuperModel

  @type       = 'SpinApp'
  @model =
    [
      {name: 'name',            public: true,   value: 'name',    default: 'Spin App' }
      {name: 'comment',         public: true,   value: 'comment',    default: ' ' }
      {name: 'endpoint',        public: true,   value: 'endpoint',    default: '/spinapp' }
      {name: 'targetModule',    public: true,   value: 'targetModule',    type: 'SpinModule', default: ' '   }
      {name: 'targetInput',     public: true,   value: 'targetInput',    default: ' ' }
      {name: 'version',         public: true,   value: 'version', default: '0.0' }
    ]

  constructor: (@record) ->
    return super

  postCreate: (q) =>
    q.resolve(@)


module.exports = SpinApp