debug = process.env["DEBUG"]

class ClientEndpoints

  @endpoints        = []
  @ondisconnectcbs  = []
  @onconnectcbs     = [] 

  @registerEndpoint: (address, sendFunc) ->
    #console.log 'ClientEndpoints.registerEndpoint called for address '+address
    @endpoints[address] = sendFunc
    @onconnectcbs.forEach (cb) => cb(address)

  @removeEndpoint: (address) ->
    if debug then console.log 'deleting endpoint '+address
    delete @endpoints[address]
    @ondisconnectcbs.forEach (cb) => cb(address)

  @sendToEndpoint: (address, msg) ->
    #console.log 'sendToEndpoint "'+address+'" called. endpoints are..'
    #console.dir @endpoints
    func = @endpoints[address]
    if func
      func(msg)
    else
      console.log '** no endpoint found for address '+address

  @exists: (address) =>
    rv = @endpoints[address]
    #console.log 'ClientEndpoints.exists called for '+address+' -> '+rv
    rv

  @onDisconnect: (cb) =>
    @ondisconnectcbs.push cb

  @onConnect: (cb) =>
    @onconnectcbs.push cb



module.exports = ClientEndpoints
