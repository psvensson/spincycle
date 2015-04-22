SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')
SamplePlayer    = require('./SamplePlayer')

class SampleGame extends SuperModel

  constructor: (@record, noload) ->
    @type       = 'SampleGame'

    @resolvearr =
    [
      {name: 'players', public: true,   hashtable: true,   type: 'SamplePlayer', ids: @record.playerids }
      {name: 'name',    public: true,   value: @record.name or uuid.v4() }
    ]

    return super

  postCreate: (q) =>
    if @playerids.length == 0
      @createPlayers().then () =>
        q.resolve(@)
    else
      q.resolve(@)

  createPlayers: () =>
    console.log 'creating sample players'
    q = defer()
    @players = []
    all([new SamplePlayer(), new SamplePlayer()]).then (results) =>
      console.log 'sample players created'
      results.forEach (player) =>
        console.dir player
        @playerids.push player.id
        @players[player.name] = player
        player.serialize()
        console.log '  serializing player '+player.name

      q.resolve()

    return q


module.exports = SampleGame