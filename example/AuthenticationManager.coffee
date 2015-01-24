# A very simple bare-bones authenticationmanager for spincycle
# It is called by the SpinCycle message-router for every message and its task is to decorate each message with a user object.
# A user object must have a unique 'id' property

defer           = require('node-promise').defer
uuid            = require('node-uuid')

class AuthenticationManager

  @constructor: ()->
    @anonymousUsers = []

  # The messagerouter will make sure the message contains a 'client' property which will be unique for each client (made up of its ip-address + port)
  # This can be used to recognize and map recurring users between messages
  @decorateMessageWithUser: (message) =>
    q = defer()
    # Either we look up the user by client key or we create s super-simple user (containing only an 'id' property) and storing that in our hashtable
    user = @anonymousUsers[message.client] or
      id: uuid.v4()
    message.user = user
    q.resolve(user)
    @anonymousUsers[message.client] = user
    return q

  # When a user send a 'registerForUpdatesOn' message to SpinCycle, this method will be called once to allow or disallow the user to be apply to subscribe to project changes of an object
  @canUserReadFromThisObject: (obj, user) =>
    true # not much checking, eh?

  # When a user send a 'updateObject' message, this method gets called to allow or disallow updating of the object
  @canUserWriteToThisObject: (obj, user) =>
    true # same here

module.exports = AuthenticationManager