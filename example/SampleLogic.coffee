e = require('../lib/EventManager')

class SampleLogic

  constructor: (@messageRouter) ->
    @games = []
    @messageRouter.addTarget('listGames',   '<noargs>', @onListPlayerGames)


  onListPlayerGames: (msg) =>
    rv = []
    console.log 'onListPlayerGames for player '+msg.user.id
    for name, game of @games
      console.log '   onListPlayerGames listing game "'+name+'"'
      rv .push game.toClient()
    msg.replyFunc(e.event(e.general.SUCCESS, rv))


module.exports = SampleLogic