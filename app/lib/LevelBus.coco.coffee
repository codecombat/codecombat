Bus = require './Bus'
{me} = require 'core/auth'
LevelSession = require 'models/LevelSession'
utils = require 'core/utils'
tagger = require 'lib/SolutionConceptTagger'
store = require('core/store')

module.exports = class LevelBus extends Bus

  @get: (levelID, sessionID) ->
    docName = "play/level/#{levelID}/#{sessionID}"
    return Bus.getFromCache(docName) or new LevelBus docName

  subscriptions:
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
    'tome:winnability-updated': 'onWinnabilityUpdated'
    'application:idle-changed': 'onIdleChanged'
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'god:new-world-created': 'onNewWorldCreated'

  constructor: ->
    super(arguments...)
    @changedSessionProperties = {}
    saveDelay = window.serverConfig?.sessionSaveDelay
    [wait, maxWait] = switch
      when not application.isProduction or not saveDelay then [1, 5]  # Save quickly in development.
      when me.isAnonymous() then [saveDelay.anonymous.min, saveDelay.anonymous.max]
      else [saveDelay.registered.min, saveDelay.registered.max]
    @saveSession = _.debounce @reallySaveSession, wait * 1000, {maxWait: maxWait * 1000}
    @playerIsIdle = false
    @vuexDestroyFunctions = []
    @vuexDestroyFunctions.push store.watch(
      (state) -> state.game.timesCodeRun
      (timesCodeRun) =>
        @session.set({timesCodeRun})
        @changedSessionProperties.timesCodeRun = true
    )
    @vuexDestroyFunctions.push store.watch(
      (state) -> state.game.timesAutocompleteUsed
      (timesAutocompleteUsed) =>
        @session.set({timesAutocompleteUsed})
        @changedSessionProperties.timesAutocompleteUsed = true
    )

  init: ->
    super()
    @fireScriptsRef = @fireRef?.child('scripts')

  setSession: (@session) ->
    @timerIntervalID = setInterval(@incrementSessionPlaytime, 1000)

  onIdleChanged: (e) ->
    @playerIsIdle = e.idle

  incrementSessionPlaytime: =>
    if @playerIsIdle then return
    @changedSessionProperties.playtime = true
    @session.set('playtime', (@session.get('playtime') ? 0) + 1)
    if store.state.game.hintsVisible
      @session.set('hintTime', (@session.get('hintTime') ? 0) + 1)
      @changedSessionProperties.hintTime = true

  onPoint: ->
    return true

  onMeSynced: =>
    super()

  join: ->
    super()

  disconnect: ->
    @fireScriptsRef?.off()
    @fireScriptsRef = null
    super()

  removeFirebaseData: (callback) ->
    return callback?() unless @myConnection
    @myConnection.child('connected')
    @fireRef.remove()
    @onDisconnect.cancel(-> callback?())

  # UPDATING FIREBASE AND SESSION

  onEditingBegan: -> #@wizardRef?.child('editing').set(true)  # no more wizards
  onEditingEnded: -> #@wizardRef?.child('editing').set(false)  # no more wizards

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

  onWinnabilityUpdated: (e) ->
    return unless @onPoint() and e.winnable
    return unless e.level.get('slug') in ['ace-of-coders', 'elemental-wars', 'the-battle-of-sky-span', 'tesla-tesoro', 'escort-duty', 'treasure-games', 'king-of-the-hill']  # Mirror matches don't otherwise show victory, so we win here.  # TODO: remove once these levels are configured as mirror matches
    return unless e.level.get('mirrorMatch')  # Mirror matches don't otherwise show victory, so we win here.
    return if @session.get('state')?.complete
    @onVictory()

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
    scripts = state.scripts ? {}
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

  onVictory: (e) ->
    return unless @onPoint()
    return if e and e.capstoneInProgress
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
      unless me.isStudent()
        # don't undo success, this property is for keying off achievements for home users
        # do undo for students, though, so this property can be used in teacher assessment tabs
        continue if oldGoalStates[goalKey]?.status is 'success' and goalState.status isnt 'success'
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

  # Debounced as saveSession
  reallySaveSession: ->
    return if _.isEmpty @changedSessionProperties
    # don't let peeking admins mess with the session accidentally
    return unless @session.get('creator') is me.id
    return if @session.fake
    if @changedSessionProperties.code
      @updateSessionConcepts()
    Backbone.Mediator.publish 'level:session-will-save', session: @session
    patch = {}
    patch[prop] = @session.get(prop) for prop of @changedSessionProperties
    @changedSessionProperties = {}

    # since updates are coming fast and loose for session objects
    # don't let what the server returns overwrite changes since the save began
    tempSession = new LevelSession _id: @session.id
    tempSession.save(patch, {patch: true, type: 'PUT'})

  updateSessionConcepts: ->
    return unless @session.get('codeLanguage') in ['javascript', 'python']
    try
      tags = tagger({ast: @session.lastAST, language: @session.get('codeLanguage')})
      tags = _.without(tags, 'basic_syntax')
      @session.set('codeConcepts', tags)
      @changedSessionProperties.codeConcepts = true
    catch e
      # Just in case the concept tagger system breaks. Esper needed fixing to handle
      # the Python skulpt AST, the concept tagger is not fully tested, and this is a
      # critical piece of code, so want to make sure this can fail gracefully.
      console.error('Unable to parse concepts from this AST.')
      console.error(e)


  destroy: ->
    clearInterval(@timerIntervalID)
    for destroyFunction in @vuexDestroyFunctions
      destroyFunction()
    super()
