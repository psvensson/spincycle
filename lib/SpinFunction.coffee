SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinFunction extends SuperModel

  @type       = 'SpinFunction'
  @model =
    [
      {name: 'name',        public: true,   value: 'name',    default: 'Spin Function' }
      {name: 'comment',     public: true,   value: 'comment',    default: ' ' }
      {name: 'code',        public: true,   value: 'code',    default: ' ', code:true }
      {name: 'testdata',    public: true,   value: 'testdata',    default: '{}', code:true }
      {name: 'testfunction', public: true,   value: 'testfunction',    default: 'var testdata = this.testdata;this.codefunc(testdata);', code:true }
      {name: 'testassertion', public: true,   value: 'testassertion',    default: 'return arg.value == 1;', code:true }
      {name: 'version',     public: true,   value: 'version', default: '0.0' }
    ]

  constructor: (@record) ->
    return super

  postCreate: (q) =>
    q.resolve(@) 


module.exports = SpinFunction