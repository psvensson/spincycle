SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')
SamplePlayer    = require('./SamplePlayer')

class SampleGame extends SuperModel

  constructor: (@record={}) ->

    q = defer()

    @id         = @record.id or uuid.v4()
    @playerids  = @record.playerids
    @name       = @record.name or 'game_'+uuid.v4()
    @type       = 'SampleGame'
    @players     = []

    resolvearr =
      [
        {name: 'players',    type: 'SamplePlayer', ids: @playerids }
      ]

    @loadFromIds(resolvearr).then () =>
      console.log 'resolved game '+@.id+' ok'
      if @players.length == 0
        @createPlayers().then () =>
          q.resolve(@)
      else
        q.resolve(@)

    return q

  createPlayers: () =>
    console.log 'creating sample players'
    q = defer()
    @players = []
    all([new SamplePlayer(), new SamplePlayer()]).then (results) =>
      console.log 'sample players created'
      results.forEach (player) -> player.serialize()
      @players = results
      q.resolve()
    return q

  toClient: () =>
    @getRecord()

  getRecord: () =>
    record =
      id:           @id
      name:         @name
      type:         @type
      playerids:    @players.map (player) -> player.id

    return record

module.exports = SampleGame