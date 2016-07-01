e     = require('../lib/EventManager')
Game  = require('./SampleGame')
SamplePlayer = require('./SamplePlayer')
DB    = require('../lib/DB')
ResolveModule   = require('../lib/ResolveModule')

class SampleLogic

  @gamecount = 0

  constructor: (@messageRouter) ->
    @games = []
    DB.createDatabases(['samplegame', 'sampleplayer']).then (results)=>
      console.log ' DB init done..'
      console.dir results
    DB.all 'SampleGame', (games) =>
      console.log ' setting all games to '+games
      console.dir(games)
      if(games.length == 0)
        console.log 'No games found! Creating one...'
        new Game({name: 'New Game '+(SampleLogic.gamecount++)}).then (game)=>
          console.log 'SampleLogic: -- new game '+game.name+' created --'
          game.serialize()
          @games.push game
      games.forEach (gamerecord) =>
        # We only need to do this manually for top-level object models. Any references will be resolved, required, instantiated and put where they should recursively
        # For example the playerids array will be resolved to actual player objects and put in a players array on each game object
        new Game(gamerecord).then (game)=>
          @games.push(game)
      console.log 'added '+@games.length+' games from storage'

    @messageRouter.addTarget('listGames',         '<noargs>', @onListPlayerGames)
    @messageRouter.addTarget('listGamePlayers',   'gameId',   @onListGamePlayers)
    @messageRouter.addTarget('newGame',           '<noargs>', @onNewGame)

    @messageRouter.objectManager.expose('SampleGame')
    @messageRouter.objectManager.expose('SamplePlayer')

    ResolveModule.modulecache['SampleGame'] = Game
    ResolveModule.modulecache['SamplePlayer'] = SamplePlayer

    @messageRouter.open()

  onNewGame: (msg) =>
    console.log 'SampleLogic: New Game called'
    new Game({name: 'New Game '+(SampleLogic.gamecount++)}).then (game)=>
      console.log 'SampleLogic: -- new game '+game.name+' created --'
      game.serialize()
      @games.push game
      msg.replyFunc({status: e.general.SUCCESS, info: 'game "'+game.name+'" created'});

  onListPlayerGames: (msg) =>
    console.log("got "+@games.length+" games");
    rv = []
    console.log 'onListPlayerGames for player '+msg.user.id
    #console.dir @games
    @games.forEach (game) ->
      console.log 'onListPlayerGames listing game "'+game.name+'"'
      rv.push game.id
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