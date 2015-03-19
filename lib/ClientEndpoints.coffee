class ClientEndpoints

  @endpoints        = []
  @ondisconnectcbs  = []
  @onconnectcbs     = []

  @registerEndpoint: (address, sendFunc) ->
    console.log 'registerEndpoint called for address '+address
    @endpoints[address] = sendFunc
    @onconnectcbs.forEach (cb) => cb(adr)

  @removeEndpoint: (address) ->
    console.log 'deleting endpoint '+address
    delete @endpoints[address]
    @ondisconnectcbs.forEach (cb) => cb(adr)

  @sendToEndpoint: (address, msg) ->
    #console.log 'sendToEndpoint "'+address+'" called. endpoints are..'
    #console.dir @endpoints
    func = @endpoints[address]
    if func
      func(msg)
    else
      console.log '** no endpoint found for address '+address

  @onDisconnect: (cb) =>
    @ondisconnectcbs.push cb

  @onConnect: (cb) =>
    @onconnectcbs.push cb


module.exports = ClientEndpoints
