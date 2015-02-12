SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
uuid            = require('node-uuid')

class SamplePlayer extends SuperModel

  constructor: (@record={}) ->

    q = defer()

    @id         = @record.id or uuid.v4()
    @name       = @record.name or 'player_'+uuid.v4()
    @type       = 'SamplePlayer'

    q.resolve(@)
    return q

  toClient: () =>
    @getRecord()

  getRecord: () =>
    record =
      id:           @id
      name:         @name
      type:         @type

    return record

module.exports = SamplePlayer