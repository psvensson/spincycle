SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')
SamplePlayer    = require('./SamplePlayer')

class SampleGame extends SuperModel

  @type       = 'SampleGame'
  @model =
    [
      {name: 'players', public: true,   array: true,   type: 'SamplePlayer', ids: 'players' }
      {name: 'name',    public: true,   value: 'name', default: 'game_'+uuid.v4() }
    ]

  constructor: (@record) ->
    return super

  postCreate: (q) =>
    if @players.length == 0
      @createPlayers().then () =>
        console.log 'SampleGame players created...'
        console.dir @
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
        #console.dir player
        @players.push player
        player.serialize()
        console.log 'serializing player '+player.name
      @serialize()
      q.resolve()

    return q


module.exports = SampleGame