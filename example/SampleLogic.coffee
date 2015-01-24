e = require('../lib/EventManager')
Game = require('./SampleGame')

class SampleLogic

  constructor: (@messageRouter) ->
    @games = []
    @messageRouter.addTarget('listGames',   '<noargs>', @onListPlayerGames)
    @messageRouter.addTarget('newGame',     '<noargs>', @onNewGame)


  onNewGame: (msg) =>
    new Game().then (game)=>
      @games.push game
      msg.replyFunc(e.event(e.general.SUCCESS, 'game "'+game.name+'" created'));

  onListPlayerGames: (msg) =>
    rv = []
    console.log 'onListPlayerGames for player '+msg.user.id
    for name, game of @games
      console.log '   onListPlayerGames listing game "'+name+'"'
      rv .push game.toClient()
    msg.replyFunc(e.event(e.general.SUCCESS, rv))


module.exports = SampleLogic