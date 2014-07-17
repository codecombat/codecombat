Bus = require './Bus'
{me} = require 'lib/auth'
LevelSession = require 'models/LevelSession'

module.exports = class LevelBus extends Bus

  @get: (levelID, sessionID) ->
    docName = "play/level/#{levelID}/#{sessionID}"
    return Bus.getFromCache(docName) or new LevelBus docName

  subscriptions:
    'self-wizard:target-changed': 'onSelfWizardTargetChanged'
    'tome:editing-began': 'onEditingBegan'
    'tome:editing-ended': 'onEditingEnded'
    'script:state-changed': 'onScriptStateChanged'
    'script:ended': 'onScriptEnded'
    'script:reset': 'onScriptReset'
    'surface:frame-changed': 'onFrameChanged'
    'surface:sprite-selected': 'onSpriteSelected'
    'level-set-playing': 'onSetPlaying'
    'level-show-victory': 'onVictory'
    'tome:spell-changed': 'onSpellChanged'
    'tome:spell-created': 'onSpellCreated'
    'application:idle-changed': 'onIdleChanged'

  constructor: ->
    super(arguments...)
    @changedSessionProperties = {}
    @saveSession = _.debounce(@saveSession, 1000, {maxWait: 5000})
    @playerIsIdle = false

  init: ->
    super()
    @fireScriptsRef = @fireRef?.child('scripts')

  setSession: (@session) ->
    @listenTo(@session, 'change:multiplayer', @onMultiplayerChanged)
    @timerIntervalID = setInterval(@incrementSessionPlaytime, 1000)

  onIdleChanged: (e) ->
    @playerIsIdle = e.idle

  incrementSessionPlaytime: =>
    if @playerIsIdle then return
    @changedSessionProperties.playtime = true
    @session.set('playtime', @session.get('playtime') + 1)

  onPoint: ->
    return true unless @session?.get('multiplayer')
    super()

  onSelfWizardTargetChanged: =>
    wizardSprite = @getSelfWizard()
    @wizardRef?.child('targetPos').set(wizardSprite?.targetPos or null)
    @wizardRef?.child('targetSprite').set(wizardSprite?.targetSprite?.thang.id or null)

  onMeSynced: =>
    super()
    @wizardRef?.child('wizardColor1').set(me.get('wizardColor1') or 0.0)

  join: ->
    super()
    @wizardRef = @myConnection.child('wizard')
    wizardSprite = @getSelfWizard()
    @wizardRef?.child('targetPos').set(wizardSprite?.targetPos or null)
    @wizardRef?.child('targetSprite').set(wizardSprite?.targetSprite?.thang.id or null)
    @wizardRef?.child('wizardColor1').set(me.get('wizardColor1') or 0.0)

  disconnect: ->
    @wizardRef?.off()
    @wizardRef = null
    @fireScriptsRef?.off()
    @fireScriptsRef = null
    super()

  removeFirebaseData: (callback) ->
    return callback?() unless @myConnection
    @myConnection.child('connected')
    @fireRef.remove()
    @onDisconnect.cancel(-> callback?())

  getSelfWizard: ->
    e = {}
    Backbone.Mediator.publish('echo-self-wizard-sprite', e)
    return e.payload

  # UPDATING FIREBASE AND SESSION

  onEditingBegan: -> @wizardRef?.child('editing').set(true)
  onEditingEnded: -> @wizardRef?.child('editing').set(false)

  # HACK: Backbone does not work with nested documents, but we want to
  #   patch only those props that have changed. Look into plugins to
  #   give Backbone support for nested docs and update the code here.

  # TODO: The LevelBus doesn't need to be in charge of updating the
  #   LevelSession object. Either break this off into a separate class
  #   or have the LevelSession object listen for all these events itself.

  setSpells: (spells) ->
    @onSpellCreated spell: spell for spellKey, spell of spells

  onSpellChanged: (e) ->
    return unless @onPoint()
    code = @session.get('code')
    code ?= {}
    parts = e.spell.spellKey.split('/')

    code[parts[0]] ?= {}
    code[parts[0]][parts[1]] = e.spell.getSource()
    @changedSessionProperties.code = true
    @session.set({'code': code})
    @saveSession()

  onSpellCreated: (e) ->
    return unless @onPoint()
    spellTeam = e.spell.team
    @teamSpellMap ?= {}
    @teamSpellMap[spellTeam] ?= []

    unless e.spell.spellKey in @teamSpellMap[spellTeam]
      @teamSpellMap[spellTeam].push e.spell.spellKey
    @changedSessionProperties.teamSpells = true
    @session.set({'teamSpells': @teamSpellMap})
    @saveSession()
    if spellTeam is me.team or spellTeam is 'common'
      @onSpellChanged e  # Save the new spell to the session, too.

  onScriptStateChanged: (e) ->
    return unless @onPoint()
    @fireScriptsRef?.update(e)
    state = @session.get('state')
    scripts = state.scripts
    scripts.currentScript = e.currentScript
    scripts.currentScriptOffset = e.currentScriptOffset
    @changedSessionProperties.state = true
    @session.set('state', state)
    @saveSession()

  onScriptEnded: (e) ->
    return unless @onPoint()
    state = @session.get('state')
    scripts = state.scripts
    scripts.ended ?= {}
    return if scripts.ended[e.scriptID]?
    index = _.keys(scripts.ended).length + 1
    @fireScriptsRef?.child('ended').child(e.scriptID).set(index)
    scripts.ended[e.scriptID] = index
    @session.set('state', state)
    @changedSessionProperties.state = true
    @saveSession()

  onScriptReset: ->
    return unless @onPoint()
    @fireScriptsRef?.set({})
    state = @session.get('state')
    state.scripts = {}
    state.complete = false
    @session.set('state', state)
    @changedSessionProperties.state = true
    @saveSession()

  onFrameChanged: (e) ->
    return unless @onPoint()
    state = @session.get('state')
    state.frame = e.frame
    @session.set('state', state)
    @changedSessionProperties.state = true
    @saveSession()

  onSpriteSelected: (e) ->
    return unless @onPoint()
    state = @session.get('state')
    state.selected = e.thang?.id or null
    @session.set('state', state)
    @changedSessionProperties.state = true
    @saveSession()

  onSetPlaying: (e) ->
    return unless @onPoint()
    state = @session.get('state')
    state.playing = e.playing
    @session.set('state', state)
    @changedSessionProperties.state = true
    @saveSession()

  onVictory: ->
    return unless @onPoint()
    state = @session.get('state')
    state.complete = true
    @session.set('state', state)
    @changedSessionProperties.state = true
    @saveSession()

  onPlayerJoined: (snapshot) =>
    super(arguments...)
    return unless @onPoint()
    players = @session.get('players')
    players ?= {}
    player = snapshot.val()
    return if players[player.id]?
    players[player.id] = {}
    @session.set('players', players)
    @changedSessionProperties.players = true
    @saveSession()

  onChatAdded: (snapshot) =>
    super(arguments...)
    chat = @session.get('chat')
    chat ?= []
    message = snapshot.val()
    return if message.system
    chat.push(message)
    chat = chat[chat.length-50...] if chat.length > 50
    @session.set('chat', chat)
    @changedSessionProperties.chat = true
    @saveSession()

  onMultiplayerChanged: ->
    @changedSessionProperties.multiplayer = true
    @session.updatePermissions()
    @changedSessionProperties.permissions = true
    @saveSession()

  saveSession: ->
    return if _.isEmpty @changedSessionProperties
    # don't let peeking admins mess with the session accidentally
    return unless @session.get('multiplayer') or @session.get('creator') is me.id
    Backbone.Mediator.publish 'level:session-will-save', session: @session
    patch = {}
    patch[prop] = @session.get(prop) for prop of @changedSessionProperties
    @changedSessionProperties = {}

    # since updates are coming fast and loose for session objects
    # don't let what the server returns overwrite changes since the save began
    tempSession = new LevelSession _id: @session.id
    tempSession.save(patch, {patch: true})

  destroy: ->
    clearInterval(@timerIntervalID)
    super()
