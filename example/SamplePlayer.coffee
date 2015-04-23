SuperModel      = require('../lib/SuperModel')
defer           = require('node-promise').defer
uuid            = require('node-uuid')

class SamplePlayer extends SuperModel

  @type       = 'SamplePlayer'

  @model =
    [
      {name: 'name', public: true, value: 'name', default:  'player_'+uuid.v4()}
    ]

  constructor: (@record={}) ->
    return super

module.exports = SamplePlayer