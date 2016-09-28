e     = require('../lib/EventManager')
SampleGame  = require('./SampleGame')
SamplePlayer = require('./SamplePlayer')
DB    = require('../lib/DB')
HttpMethod = require('../lib/HttpMethod')
ResolveModule   = require('../lib/ResolveModule')

class SampleLogic

  @gamecount = 0

  constructor: (@messageRouter) ->
    @games = []
    console.log '--------------------------------- SampleLogic contructor -------------------------------'
    @messageRouter.objectManager.expose('SampleGame')
    @messageRouter.objectManager.expose('SamplePlayer')

    ResolveModule.modulecache['SampleGame'] = SampleGame
    ResolveModule.modulecache['SamplePlayer'] = SamplePlayer

    DB.createDatabases(['SampleGame','SamplePlayer']).then ()=>
      console.log ' SampleLogic DB init done..'
      DB.getOrCreateObjectByRecord({id:17, name: 'fooGame', type: 'SampleGame', createdBy: 'SYSTEM', createdAt: Date.now()}).then (game)=>
        console.log 'got first game'
        game.serialize()
        @messageRouter.open()

module.exports = SampleLogic