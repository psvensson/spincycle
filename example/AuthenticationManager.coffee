# A very simple bare-bones authenticationmanager for spincycle
# It is called by the SpinCycle message-router for every message and its task is to decorate each message with a user object.
# A user object must have a unique 'id' property

defer           = require('node-promise').defer
uuid            = require('node-uuid')

class AuthenticationManager

  constructor: ()->
    @anonymousUsers = []
    console.log '** new AuthMgr created **'

  # The messagerouter will make sure the message contains a 'client' property which will be unique for each client (made up of its ip-address + port)
  # This can be used to recognize and map recurring users between messages
  decorateMessageWithUser: (message) =>
    q = defer()
    # Either we look up the user by client key or we create a super-simple user (containing only an 'id' property) and storing that in our hashtable
    user = @anonymousUsers[message.client] or
      id: uuid.v4()
    message.user = user
    q.resolve(message)
    @anonymousUsers[message.client] = user
    return q

  # When a user sends a 'registerForUpdatesOn' message to SpinCycle, this method will be called once to allow or disallow the user to be apply to subscribe to project changes of an object
  canUserReadFromThisObject: (obj, user) =>
    true # not much checking, eh?

  # When a user sends a 'updateObject' message, this method gets called to allow or disallow updating of the object
  canUserWriteToThisObject: (obj, user) =>
    true # same here

  # When a user sends a '_create'+<object_type> message, this method gets called to allow or disallow creating of the object
  canUserCreateThisObject: (type, user) =>
    true # same here

  # When a user sends a '_create'+<object_type> message, this method gets called to allow or disallow creating of the object
  canUserListTheseObjects: (type, user) =>
    true # same here
 
module.exports = AuthenticationManager