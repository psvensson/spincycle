sys         = require("util")
googleapis  = require('node-google-api')

class GDS

  authorize: =>
    # First, try to retrieve credentials from Compute Engine metadata server.
    @credentials = new googleapis.auth.Compute()
    # Then, fallback on JWT credentials.
    @credentials.authorize ((computeErr) ->
      if computeErr
        errors = "compute auth error": computeErr
        if process.env["DATASTORE_SERVICE_ACCOUNT"]
          @credentials = new googleapis.auth.JWT(process.env["DATASTORE_SERVICE_ACCOUNT"], process.env["DATASTORE_PRIVATE_KEY_FILE"], SCOPES)
          @credentials.authorize ((jwtErr) ->
            if jwtErr
              errors["jwt auth error"] = jwtErr
              @emit "error", errors
              return
            @connect()
            return
          ).bind(this)
        else
          sys.puts sys.inspect(errors)
      else
        @authorized = true
      return
    ).bind(this)
    return

  connect: =>
    # Build the API bindings for the current version.
    # Bind the datastore client to datasetId and get the datasets
    # resource.
    googleapis.discover("datastore", "v1beta2").withAuthClient(@credentials).execute ((err, client) ->
      if err
        console.log "google datastore connection error : "+ err
        return
      @datastore = client.datastore.withDefaultParams(datasetId: @datasetId).datasets
      return
    ).bind(this)
    return

  set: (type, obj, callback) =>
    entity =
      key:
        path: [kind: type]
      properties: obj

    @datastore.commit(
      mutation:
        insertAutoId: [entity]
      mode: "NON_TRANSACTIONAL"
    ).execute callback

  lookup: (type, name, callback) =>

    # Get entities by key.

    # Set the transaction, so we get a consistent snapshot of the
    # value at the time the transaction started.

    # Add one entity key to the lookup request, with only one
    # `path` element (i.e. no parent).
    @datastore.lookup(
      readOptions:
        transaction: @transaction

      keys: [path: [
        kind: type
        name: name
      ]]

      # Get the entity from the response if found.
    ).execute ((err, result) ->
      if err
        console.log "google datastore error", err
        return
      entity = result.found[0].entity  if result.found
      callback(entity)

    ).bind(this)
    return

module.exports = GDS
