SuperModel      = require('./SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone

class SpinModule extends SuperModel

  @type       = 'SpinModule'
  @model =
    [
      {name: 'name',                    public: true,   value: 'name', default: 'Spin Module' }

      # input elements look like; {destinationModule: 'yyyy', destinationFunction: 'zzzz'}
      # This way it's easy to support modules in modules hierarchically. Default is that a module input goes to one of tis own functions, but
      # It's now very simple to just refer to another modules and a function in that, if needed.
      { name: 'inputs',                 public: true,   value: 'inputs', default: [] }

      # outputs is just an array of named output hooks
      { name: 'outputs',                public: true,   value: 'outputs', default: [] }

      # moduleConnetion elemnt look like this; {startNodule: 'xxx', endModule: 'yyy, startOutputName: 'zzz', endInputIndex: 'qqq'}
      { name: 'moduleConnections',      public: true,   value: 'moduleConnections', default: [] }
      { name: 'state',                  public: true,   value: 'state', default: {} }

      # The naked function inside a module are referred in the 'inputs' array as {destinationModule: <this module>, destinationFunction: <one of these function in this array>
      { name: 'functions',              public: true,   ids: 'functions', array: true,  type: 'SpinFunction', default: [] }

      # This is a list of modules that this modules has inside itself and which can have connections definted in 'moduleConnections'
      { name: 'modules',                public: true,   ids: 'modules', array: true,  type: 'SpinModule', default: [] }

      { name: 'tests',                  public: true,   value: 'tests', default: [] }
      { name: 'version',     public: true,   value: 'version', default: '0.0' }
    ]

  constructor: (@record) ->
    return super
    

  postCreate: (q) =>
    q.resolve(@)



module.exports = SpinModule