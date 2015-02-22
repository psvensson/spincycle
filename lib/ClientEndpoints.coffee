class ClientEndpoints

  @endpoints =[]

  @registerEndpoint: (address, sendFunc) ->
    console.log 'registerEndpoint called for address '+address
    @endpoints[address] = sendFunc

  @removeEndpoint: (address) ->
    console.log 'deleting endpoint '+address
    delete @endpoints[address]

  @sendToEndpoint: (address, msg) ->
    #console.log 'sendToEndpoint "'+address+'" called. endpoints are..'
    #console.dir @endpoints
    func = @endpoints[address]
    if func
      func(msg)
    else
      console.log '** no endpoint found for address '+address

module.exports = ClientEndpoints
