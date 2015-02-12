e     = require('../lib/EventManager')
Game  = require('./SampleGame')
DB    = require('../lib/DB')

class SampleLogic

  @gamecount = 0

  constructor: (@messageRouter) ->
    @games = []
    DB.all 'SampleGame', (games) =>
      console.log ' setting all games to '+games
      console.dir(games)
      games.forEach (gamerecord) =>
        # We only need to do this manually for top-level object models. Any references will be resolved, required, instantiated and put where they should recursively
        # For example the playerids array will be resolved to actual player objects and put in a players array on each game object
        new Game(gamerecord).then (game) =>
          game.serialize()
          console.log '--- adding game '+game.name
          @games.push(game)
      console.log 'added '+@games.length+' games from storage'
    @messageRouter.addTarget('listGames',         '<noargs>', @onListPlayerGames)
    @messageRouter.addTarget('listGamePlayers',   'gameId', @onListGamePlayers)
    @messageRouter.addTarget('newGame',           '<noargs>', @onNewGame)


  onNewGame: (msg) =>
    console.log 'New Game called'
    new Game({name: 'New Game '+(SampleLogic.gamecount++)}).then (game)=>
      console.log '-- new game '+game.name+' created --'
      game.serialize()
      @games.push game
      msg.replyFunc({status: e.general.SUCCESS, info: 'game "'+game.name+'" created'});

  onListPlayerGames: (msg) =>
    console.log("got "+@games.length+" games");
    rv = []
    console.log 'onListPlayerGames for player '+msg.user.id
    console.dir @games
    @games.forEach (game) ->
      console.log '   onListPlayerGames listing game "'+game.name+'"'
      rv.push game.toClient()
    msg.replyFunc({status: e.general.SUCCESS, info: '', payload: rv})

  onListGamePlayers: (msg) =>
    game = null
    @games.forEach (lgame) =>
      game = lgame if lgame.id == msg.gameById
    if game
      rv = []
      game.players.forEach (player) -> rv.push player.toClient()
      msg.replyFunc({status: e.general.SUCCESS, info: '', payload: rv})
    else
      msg.replyFunc({status: e.general.FAILURE, info: 'no game found with that id', payload:'' })

module.exports = SampleLogic