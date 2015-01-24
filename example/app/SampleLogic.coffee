e = reuire('../lib/EventManager')

class SampleLogic

  constructor: (@messageRouter) ->
    @games = []
    @messageRouter.addTarget('listPlayerGames',   '<noargs>', @onListPlayerGames)

  onListPlayerGames: () =>
    onListPlayerGames: (msg) =>
    rv = []
    console.log 'onListPlayerGames for player '+msg.user.id
    for name, game of @games
      console.log '   onListPlayerGames listing game "'+name+'"'
      rv .push game.toClient()
    msg.replyFunc(e.event(e.general.SUCCESS, rv))


module.exports = SampleLogic