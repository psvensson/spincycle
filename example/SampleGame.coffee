SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
uuid            = require('node-uuid')


class SampleGame extends SuperModel

  constructor: (@record={}) ->

    q = defer()

    @id         = @record.id
    @name       = @record.name or 'game_'+uuid.v4()
    @type       = 'game'

    if not @id
      @id = uuid.v4()
      @serialize()

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

module.exports = SampleGame