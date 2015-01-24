class ClientEndpoints

  @endpoints =[]

  @registerEndpoint: (address, sendFunc) ->
    console.log 'registerEndpoint called for address '+address
    @endpoints[address] = sendFunc

  @removeEndpoint: (address) ->
    console.log 'deleting endpoint '+address
    delete @endpoints[address]

  @sendToEndpoint: (address, msg) ->
    console.log 'sendToEndpoint called. endpoints are..'
    console.dir @endpoints
    @endpoints[address](msg)

module.exports = ClientEndpoints
