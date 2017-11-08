CocoClass = require 'core/CocoClass'
CocoView = require 'views/core/CocoView'
{scriptMatchesEventPrereqs} = require './../world/script_event_prereqs'
utils = require 'core/utils'

allScriptModules = []
allScriptModules.push(require './SpriteScriptModule')
allScriptModules.push(require './DOMScriptModule')
allScriptModules.push(require './SurfaceScriptModule')
allScriptModules.push(require './PlaybackScriptModule')
allScriptModules.push(require './SoundScriptModule')


DEFAULT_BOT_MOVE_DURATION = 500
DEFAULT_SCRUB_DURATION = 1000

module.exports = ScriptManager = class ScriptManager extends CocoClass
  scriptInProgress: false
  currentNoteGroup: null
  currentTimeouts: []
  worldLoading: true
  ignoreEvents: false
  quiet: false

  triggered: []
  ended: []
  noteGroupQueue: []
  originalScripts: [] # use these later when you want to revert to an original state

  subscriptions:
    'script:end-current-script': 'onEndNoteGroup'
    'level:loading-view-unveiling': -> @setWorldLoading(false)
    'level:restarted': 'onLevelRestarted'
    'level:shift-space-pressed': 'onEndNoteGroup'
    'level:escape-pressed': 'onEndAll'

  shortcuts:
    '⇧+space, space, enter': -> Backbone.Mediator.publish 'level:shift-space-pressed', {}
    'escape': -> Backbone.Mediator.publish 'level:escape-pressed', {}

  # SETUP / TEARDOWN

  constructor: (options) ->
    super(options)
    @originalScripts = @filterScripts(options.scripts)
    @session = options.session
    @levelID = options.levelID
    @debugScripts = application.isIPadApp or utils.getQueryVariable 'dev'
    @initProperties()
    @addScriptSubscriptions()
    @beginTicking()

  setScripts: (newScripts) ->
    @originalScripts = @filterScripts(newScripts)
    @quiet = true
    @initProperties()
    @loadFromSession()
    @quiet = false
    @addScriptSubscriptions()
    @run()

  filterScripts: (scripts) ->
    _.filter scripts, (script) ->
      return true if me.isAdmin()
      return true unless script.id in ['Intro Dialogue', 'Failure Dialogue',  'Success Dialogue']
      return false unless serverConfig.enableNarrative?
      return false if (me.get('testGroupNumber') % 8) < 4 # Groups 0-3 dont see narrative
      true

  initProperties: ->
    @endAll({force:true}) if @scriptInProgress
    @triggered = []
    @ended = []
    @noteGroupQueue = []
    @scripts = $.extend(true, [], @originalScripts)

  addScriptSubscriptions: ->
    idNum = 0
    makeCallback = (channel) => (event) => @onNote(channel, event)
    for script in @scripts
      script.id = (idNum++).toString() unless script.id
      callback = makeCallback(script.channel) # curry in the channel argument
      @addNewSubscription(script.channel, callback)

  beginTicking: ->
    @tickInterval = setInterval @tick, 5000

  tick: =>
    scriptStates = {}
    now = new Date()
    for script in @scripts
      scriptStates[script.id] =
        timeSinceLastEnded: (if script.lastEnded then now - script.lastEnded else 0) / 1000
        timeSinceLastTriggered: (if script.lastTriggered then now - script.lastTriggered else 0) / 1000

    stateEvent =
      scriptRunning: @currentNoteGroup?.scriptID or ''
      noteGroupRunning: @currentNoteGroup?.name or ''
      scriptStates: scriptStates
      timeSinceLastScriptEnded: (if @lastScriptEnded then now - @lastScriptEnded else 0) / 1000

    Backbone.Mediator.publish 'script:tick', stateEvent  # Used to trigger level scripts.

  loadFromSession: ->
    # load the queue with note groups to skip through
    @addEndedScriptsFromSession()
    @addPartiallyEndedScriptFromSession()
    for noteGroup in @noteGroupQueue
      @processNoteGroup(noteGroup)

  addPartiallyEndedScriptFromSession: ->
    scripts = @session.get('state').scripts
    return unless scripts?.currentScript
    script = _.find @scripts, {id: scripts.currentScript}
    return unless script
    @triggered.push(script.id)
    noteChain = @processScript(script)
    return unless noteChain
    if scripts.currentScriptOffset
      noteGroup.skipMe = true for noteGroup in noteChain[..scripts.currentScriptOffset-1]
    @addNoteChain(noteChain, false)

  addEndedScriptsFromSession: ->
    scripts = @session.get('state').scripts
    return unless scripts
    endedObj = scripts['ended'] or {}
    sortedPairs = _.sortBy(_.pairs(endedObj), (pair) -> pair[1])
    scriptsToSkip = (p[0] for p in sortedPairs)
    for scriptID in scriptsToSkip
      script = _.find @scripts, {id: scriptID}
      unless script
        console.warn 'Couldn\'t find script for', scriptID, 'from scripts', @scripts, 'when restoring session scripts.'
        continue
      continue if script.repeats # repeating scripts are not 'rerun'
      @triggered.push(scriptID)
      @ended.push(scriptID)
      noteChain = @processScript(script)
      return unless noteChain
      noteGroup.skipMe = true for noteGroup in noteChain
      @addNoteChain(noteChain, false)

  setWorldLoading: (@worldLoading) ->
    @run() unless @worldLoading

  initializeCamera: ->
    # Fire off the first bounds-setting script now, before we're actually running any other ones.
    for script in @scripts
      for note in script.noteChain or []
        if note.surface?.focus?
          surfaceModule = _.find note.modules or [], (module) -> module.surfaceCameraNote
          cameraNote = surfaceModule.surfaceCameraNote true
          @publishNote cameraNote
          return

  destroy: ->
    @onEndAll()
    clearInterval @tickInterval
    super()

  # TRIGGERERING NOTES

  onNote: (channel, event) ->
    return if @ignoreEvents
    for script in @scripts
      alreadyTriggered = script.id in @triggered
      continue unless script.channel is channel
      continue if alreadyTriggered and not script.repeats
      continue if script.lastTriggered? and script.repeats is 'session'
      continue if script.lastTriggered? and new Date().getTime() - script.lastTriggered < 1
      continue if script.neverRun

      if script.notAfter
        for scriptID in script.notAfter
          if scriptID in @triggered
            script.neverRun = true
            break
        continue if script.neverRun

      continue unless @scriptPrereqsSatisfied(script)
      continue unless scriptMatchesEventPrereqs(script, event)
      # everything passed!
      console.debug "SCRIPT: Running script '#{script.id}'" if @debugScripts
      script.lastTriggered = new Date().getTime()
      @triggered.push(script.id) unless alreadyTriggered
      noteChain = @processScript(script)
      if not noteChain then return @trackScriptCompletions (script.id)
      @addNoteChain(noteChain)
      @run()

  scriptPrereqsSatisfied: (script) ->
    _.every(script.scriptPrereqs or [], (prereq) => prereq in @triggered)

  processScript: (script) ->
    noteChain = script.noteChain
    return null unless noteChain?.length
    noteGroup.scriptID = script.id for noteGroup in noteChain
    lastNoteGroup = noteChain[noteChain.length - 1]
    lastNoteGroup.isLast = true
    return noteChain

  addNoteChain: (noteChain, clearYields=true) ->
    @processNoteGroup(noteGroup) for noteGroup in noteChain
    noteGroup.index = i for noteGroup, i in noteChain
    if clearYields
      noteGroup.skipMe = true for noteGroup in @noteGroupQueue when noteGroup.script.yields
    @noteGroupQueue.push noteGroup for noteGroup in noteChain
    @endYieldingNote()

  processNoteGroup: (noteGroup) ->
    return if noteGroup.modules?
    if noteGroup.playback?.scrub?
      noteGroup.playback.scrub.duration ?= DEFAULT_SCRUB_DURATION
    noteGroup.sprites ?= []
    for sprite in noteGroup.sprites
      if sprite.move?
        sprite.move.duration ?= DEFAULT_BOT_MOVE_DURATION
      sprite.id ?= 'Hero Placeholder'
    noteGroup.script ?= {}
    noteGroup.script.yields ?= true
    noteGroup.script.skippable ?= true
    noteGroup.modules = (new Module(noteGroup) for Module in allScriptModules when Module.neededFor(noteGroup))

  endYieldingNote: ->
    if @scriptInProgress and @currentNoteGroup?.script.yields
      @endNoteGroup()
      return true

  # STARTING NOTES

  run: ->
    # catch all for analyzing the current state and doing whatever needs to happen next
    return if @scriptInProgress
    @skipAhead()
    return unless @noteGroupQueue.length
    nextNoteGroup = @noteGroupQueue[0]
    return if @worldLoading and nextNoteGroup.skipMe
    return if @worldLoading and not nextNoteGroup.script?.beforeLoad
    @noteGroupQueue = @noteGroupQueue[1..]
    @currentNoteGroup = nextNoteGroup
    @notifyScriptStateChanged()
    @scriptInProgress = true
    @currentTimeouts = []
    scriptLabel = "#{nextNoteGroup.scriptID} - #{nextNoteGroup.name}"
    console.debug "SCRIPT: Starting note group '#{nextNoteGroup.name}'" if @debugScripts
    for module in nextNoteGroup.modules
      @processNote(note, nextNoteGroup) for note in module.startNotes()
    if nextNoteGroup.script.duration
      f = => @onNoteGroupTimeout? nextNoteGroup
      setTimeout(f, nextNoteGroup.script.duration)
    Backbone.Mediator.publish 'script:note-group-started', {}

  skipAhead: ->
    return if @worldLoading
    return unless @noteGroupQueue[0]?.skipMe
    @ignoreEvents = true
    for noteGroup, i in @noteGroupQueue
      break unless noteGroup.skipMe
      console.debug "SCRIPT: Skipping note group '#{noteGroup.name}'" if @debugScripts
      @processNoteGroup(noteGroup)
      for module in noteGroup.modules
        notes = module.skipNotes()
        @processNote(note, noteGroup) for note in notes
      @trackScriptCompletionsFromNoteGroup(noteGroup)
    @noteGroupQueue = @noteGroupQueue[i..]
    @ignoreEvents = false

  processNote: (note, noteGroup) ->
    note.event ?= {}
    if note.delay
      f = => @sendDelayedNote noteGroup, note
      @currentTimeouts.push setTimeout(f, note.delay)
    else
      @publishNote(note)

  sendDelayedNote: (noteGroup, note) ->
    # some events should only happen after the bot has moved into position
    return unless noteGroup is @currentNoteGroup
    @publishNote(note)

  publishNote: (note) ->
    Backbone.Mediator.publish note.channel, note.event ? {}

  # ENDING NOTES

  onLevelRestarted: ->
    @quiet = true
    @endAll({force:true})
    @initProperties()
    @resetThings()
    Backbone.Mediator.publish 'script:reset', {}
    @quiet = false
    @run()

  onEndNoteGroup: (e) ->
    # press enter
    return unless @currentNoteGroup?.script.skippable
    @endNoteGroup()
    @run()

  endNoteGroup: ->
    return if @ending # kill infinite loops right here
    @ending = true
    return unless @currentNoteGroup?
    scriptLabel = "#{@currentNoteGroup.scriptID} - #{@currentNoteGroup.name}"
    console.debug "SCRIPT: Ending note group '#{@currentNoteGroup.name}'" if @debugScripts
    clearTimeout(timeout) for timeout in @currentTimeouts
    for module in @currentNoteGroup.modules
      @processNote(note, @currentNoteGroup) for note in module.endNotes()
    Backbone.Mediator.publish 'script:note-group-ended', {} unless @quiet
    @scriptInProgress = false
    @trackScriptCompletionsFromNoteGroup(@currentNoteGroup)
    @currentNoteGroup = null
    unless @noteGroupQueue.length
      @notifyScriptStateChanged()
      @resetThings()
    @ending = false

  onEndAll: (e) ->
    # Escape was pressed.
    @endAll()

  endAll: (options) ->
    options ?= {}
    if @scriptInProgress
      return if (not @currentNoteGroup.script.skippable) and (not options.force)
      @endNoteGroup()

    for noteGroup, i in @noteGroupQueue
      if ((noteGroup.script?.skippable) is false) and not options.force
        @noteGroupQueue = @noteGroupQueue[i..]
        @run()
        @notifyScriptStateChanged()
        return

      @processNoteGroup(noteGroup)
      for module in noteGroup.modules
        notes = module.skipNotes()
        @processNote(note, noteGroup) for note in notes unless @quiet
      @trackScriptCompletionsFromNoteGroup(noteGroup) unless @quiet

    @noteGroupQueue = []

    @resetThings()
    @notifyScriptStateChanged()

  onNoteGroupTimeout: (noteGroup) ->
    return unless noteGroup is @currentNoteGroup
    @endNoteGroup()
    @run()

  resetThings: ->
    Backbone.Mediator.publish 'level:enable-controls', {}
    Backbone.Mediator.publish 'level:set-letterbox', { on: false }

  trackScriptCompletionsFromNoteGroup: (noteGroup) ->
    return unless noteGroup.isLast
    @trackScriptCompletions(noteGroup.scriptID)

  trackScriptCompletions: (scriptID) ->
    return if @quiet
    @ended.push(scriptID) unless scriptID in @ended
    for script in @scripts
      if script.id is scriptID
        script.lastEnded = new Date()
    @lastScriptEnded = new Date()
    Backbone.Mediator.publish 'script:ended', {scriptID: scriptID}

  notifyScriptStateChanged: ->
    return if @quiet
    event =
      currentScript: @currentNoteGroup?.scriptID or null
      currentScriptOffset: @currentNoteGroup?.index or 0
    Backbone.Mediator.publish 'script:state-changed', event
