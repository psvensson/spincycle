Roach = require('roachjs')

Class cockroach

  constructor: () ->
    @client = new Roach({uri: 'http://127.0.0.1:8080'})


module.exports = cockroach