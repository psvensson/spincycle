SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
all             = require('node-promise').allOrNone
uuid            = require('node-uuid')
SamplePlayer    = require('./SamplePlayer')

class SampleGame extends SuperModel

  constructor: (@record, noload) ->

    q = defer()

    @id         = @record.id or uuid.v4()
    @playerids  = @record.playerids or []
    @name       = @record.name or 'game_'+uuid.v4()
    @type       = 'SampleGame'
    @players     = {}

    resolvearr =
      [
        {name: 'players', hashtable: true,   type: 'SamplePlayer', ids: @playerids }
      ]

    if noload
      if @playerids.length == 0
        @createPlayers().then () =>
          console.log 'Samplegame::constructor. playerids are..'
          console.dir @playerids
          q.resolve(@)
    else
      @loadFromIds(resolvearr).then () =>
        console.log 'resolved game '+@.id+' ok'
        if @playerids.length == 0
          @createPlayers().then () =>
            q.resolve(@)
        else
          console.log 'game loaded from db...'
          console.dir(@)
          q.resolve(@)

    return q

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

  toClient: () =>
    @getRecord()

  getRecord: () =>
    record =
      id:           @id
      name:         @name
      type:         @type
      playerids:    @players.map (player) -> player.id
    for k,v in @players
      record.playerids.push v.id


    return record

module.exports = SampleGame