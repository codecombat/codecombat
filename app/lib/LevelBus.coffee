Bus = require './Bus'
{me} = require 'core/auth'
LevelSession = require 'models/LevelSession'
utils = require 'core/utils'

module.exports = class LevelBus extends Bus

  @get: (levelID, sessionID) ->
    docName = "play/level/#{levelID}/#{sessionID}"
    return Bus.getFromCache(docName) or new LevelBus docName

  subscriptions:
    'self-wizard:target-changed': 'onSelfWizardTargetChanged'
    'self-wizard:created': 'onSelfWizardCreated'
    'tome:editing-began': 'onEditingBegan'
    'tome:editing-ended': 'onEditingEnded'
    'script:state-changed': 'onScriptStateChanged'
    'script:ended': 'onScriptEnded'
    'script:reset': 'onScriptReset'
    'surface:sprite-selected': 'onSpriteSelected'
    'level:show-victory': 'onVictory'
    'tome:spell-changed': 'onSpellChanged'
    'tome:spell-created': 'onSpellCreated'
    'tome:cast-spells': 'onCastSpells'
    'application:idle-changed': 'onIdleChanged'
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'god:new-world-created': 'onNewWorldCreated'

  constructor: ->
    super(arguments...)
    @changedSessionProperties = {}
    if document.location.href.search('codecombat.com') isnt -1
      @saveSession = _.debounce(@reallySaveSession, 4000, {maxWait: 10000})  # Save slower on production.
    else
      @saveSession = _.debounce(@reallySaveSession, 1000, {maxWait: 5000})  # Save quickly in development.
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
    @session.set('playtime', (@session.get('playtime') ? 0) + 1)

  onPoint: ->
    return true unless @session?.get('multiplayer')
    super()

  onSelfWizardCreated: (e) ->
    @selfWizardLank = e.sprite

  onSelfWizardTargetChanged: (e) ->
    @wizardRef?.child('targetPos').set(@selfWizardLank?.targetPos or null)
    @wizardRef?.child('targetSprite').set(@selfWizardLank?.targetSprite?.thang.id or null)

  onMeSynced: =>
    super()
    @wizardRef?.child('wizardColor1').set(me.get('wizardColor1') or 0.0)

  join: ->
    super()
    @wizardRef = @myConnection.child('wizard')
    @wizardRef?.child('targetPos').set(@selfWizardLank?.targetPos or null)
    @wizardRef?.child('targetSprite').set(@selfWizardLank?.targetSprite?.thang.id or null)
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
    if spellTeam is me.team or (e.spell.otherSession and spellTeam isnt e.spell.otherSession.get('team'))
      # https://github.com/codecombat/codecombat/issues/81
      @onSpellChanged e  # Save the new spell to the session, too.

  onCastSpells: (e) ->
    return unless @onPoint() and e.realTime
    # We have incremented state.submissionCount and reset state.flagHistory.
    @changedSessionProperties.state = true
    @saveSession()

  onNewWorldCreated: (e) ->
    return unless @onPoint()
    # Record the flag history.
    state = @session.get('state')
    flagHistory = (flag for flag in e.world.flagHistory when flag.source isnt 'code')
    return if _.isEqual state.flagHistory, flagHistory
    state.flagHistory = flagHistory
    @changedSessionProperties.state = true
    @session.set('state', state)
    @saveSession()

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
    #state.complete = false  # Keep it complete once ever completed.
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

  onVictory: ->
    return unless @onPoint()
    state = @session.get('state')
    state.complete = true
    @session.set('state', state)
    @changedSessionProperties.state = true
    @reallySaveSession()  # Make sure it saves right away; don't debounce it.

  onNewGoalStates: (e) ->
    # TODO: this log doesn't capture when null-status goals are being set during world streaming. Where can they be coming from?
    goalStates = e.goalStates
    return console.error("Somehow trying to save null goal states!", newGoalStates) if _.find(newGoalStates, (gs) -> not gs.status)

    return unless e.overallStatus is 'success'
    newGoalStates = goalStates
    state = @session.get('state')
    oldGoalStates = state.goalStates or {}

    changed = false
    for goalKey, goalState of newGoalStates
      continue if oldGoalStates[goalKey]?.status is 'success' and goalState.status isnt 'success' # don't undo success, this property is for keying off achievements
      continue if utils.kindaEqual state.goalStates?[goalKey], goalState # Only save when goals really change
      changed = true
      oldGoalStates[goalKey] = _.cloneDeep newGoalStates[goalKey]

    if changed
      state.goalStates = oldGoalStates
      @session.set 'state', state
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

  # Debounced as saveSession
  reallySaveSession: ->
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
    tempSession.save(patch, {patch: true, type: 'PUT'})

  destroy: ->
    clearInterval(@timerIntervalID)
    super()
