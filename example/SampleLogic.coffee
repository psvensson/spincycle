e = require('../lib/EventManager')
Game = require('./SampleGame')

class SampleLogic

  @gamecount = 0

  constructor: (@messageRouter) ->
    @games = []
    @messageRouter.addTarget('listGames',   '<noargs>', @onListPlayerGames)
    @messageRouter.addTarget('newGame',     '<noargs>', @onNewGame)


  onNewGame: (msg) =>
    new Game({name: 'New Game '+(SampleLogic.gamecount++)}).then (game)=>
      @games.push game
      msg.replyFunc({status: e.general.SUCCESS, info: 'game "'+game.name+'" created'});

  onListPlayerGames: (msg) =>
    rv = []
    console.log 'onListPlayerGames for player '+msg.user.id
    for name, game of @games
      console.log '   onListPlayerGames listing game "'+name+'"'
      rv .push game.toClient()
    msg.replyFunc({status: e.general.SUCCESS, info: '', payload: rv})


module.exports = SampleLogic