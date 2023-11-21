CocoClass = require 'core/CocoClass'

{me} = require 'core/auth'

CHAT_SIZE_LIMIT = 500 # no more than 500 messages

module.exports = Bus = class Bus extends CocoClass
  joined: null
  players: null

  @get: (docName) -> return @getFromCache or new Bus docName
  @getFromCache: (docName) -> return Bus.activeBuses[docName]
  @activeBuses: {}
  @fireHost: 'https://codecombat.firebaseio.com'

  constructor: (@docName) ->
    super()
    @players = {}
    Bus.activeBuses[@docName] = @

  subscriptions:
    'auth:me-synced': 'onMeSynced'

  connect: ->
    # Put Firebase back in bower if you want to use this
    Backbone.Mediator.publish 'bus:connecting', {bus: @}
    Firebase.goOnline()
    @fireRef = new Firebase(Bus.fireHost + '/' + @docName)
    @fireRef.once 'value', @onFireOpen

  onFireOpen: (snapshot) =>
    if @destroyed
      console.log("Leaving '#{@docName}' because class has been destroyed.")
      return
    @init()
    Backbone.Mediator.publish 'bus:connected', {bus: @}

  disconnect: ->
    @fireRef?.off()
    @fireRef = null
    @fireChatRef?.off()
    @fireChatRef = null
    @firePlayersRef?.off()
    @firePlayersRef = null
    @myConnection?.off()
    @myConnection = null
    @joined = false
    Backbone.Mediator.publish 'bus:disconnected', {bus: @}

  init: ->
    """
    Init happens when we're connected.
    """
    @fireChatRef = @fireRef.child('chat')
    @firePlayersRef = @fireRef.child('players')
    @join()
    @listenForChanges()
    @sendMessage('/me joined.', true)

  join: ->
    @joined = true
    @myConnection = @firePlayersRef.child(me.id)
    @myConnection.set({id: me.id, name: me.get('name'), connected: true})
    @onDisconnect = @myConnection.child('connected').onDisconnect()
    @onDisconnect.set(false)

  listenForChanges: ->
    @fireChatRef.limit(CHAT_SIZE_LIMIT).on 'child_added', @onChatAdded
    @firePlayersRef.on 'child_added', @onPlayerJoined
    @firePlayersRef.on 'child_removed', @onPlayerLeft
    @firePlayersRef.on 'child_changed', @onPlayerChanged

  onChatAdded: (snapshot) =>
    Backbone.Mediator.publish('bus:new-message', {message: snapshot.val(), bus: @})

  onPlayerJoined: (snapshot) =>
    player = snapshot.val()
    return unless player.connected
    @players[player.id] = player
    Backbone.Mediator.publish('bus:player-joined', {player: player, bus: @})

  onPlayerLeft: (snapshot) =>
    val = snapshot.val()
    return unless val
    player = @players[val.id]
    return unless player
    delete @players[player.id]
    Backbone.Mediator.publish('bus:player-left', {player: player, bus: @})

  onPlayerChanged: (snapshot) =>
    player = snapshot.val()
    wasConnected = @players[player.id]?.connected
    @players[player.id] = player
    @onPlayerLeft(snapshot) if wasConnected and not player.connected
    @onPlayerJoined(snapshot) if player.connected and not wasConnected
    Backbone.Mediator.publish('bus:player-states-changed', {states: @players, bus: @})

  onMeSynced: ->
    @myConnection?.child('name').set(me.get('name'))

  countPlayers: -> _.size(@players)

  onPoint: ->
    # simple way to elect somone to do jobs that don't need to be done by each player
    ids = _.keys(@players)
    ids.sort()
    return ids[0] is me.id

  # MESSAGING

  sendSystemMessage: (content) ->
    @sendMessage(content, true)

  sendMessage: (content, system=false) ->
    MAX_MESSAGE_LENGTH = 400
    message =
      content: content[... MAX_MESSAGE_LENGTH]
      authorName: me.displayName()
      authorID: me.id
      dateMade: new Date()
    message.system = system if system
    @fireChatRef.push(message)

  # TEARDOWN

  destroy: ->
    @sendMessage('/me left.', true) if @joined
    delete Bus.activeBuses[@docName] if @docName of Bus.activeBuses
    @disconnect()
    super()
