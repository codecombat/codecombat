# * search for how various places handle or call 'end-current-script' event


CocoClass = require 'lib/CocoClass'
{scriptMatchesEventPrereqs} = require './../world/script_event_prereqs'

allScriptModules = []
allScriptModules.push(require './SpriteScriptModule')
allScriptModules.push(require './DOMScriptModule')
allScriptModules.push(require './SurfaceScriptModule')
allScriptModules.push(require './PlaybackScriptModule')
GoalScriptsModule = require './GoalsScriptModule'
allScriptModules.push(GoalScriptsModule)
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
    'end-current-script': 'onEndNoteGroup'
    'end-all-scripts': 'onEndAll'
    'level:started': -> @setWorldLoading(false)
    'level:restarted': 'onLevelRestarted'
    'level:shift-space-pressed': 'onEndNoteGroup'
    'level:escape-pressed': 'onEndAll'

  shortcuts:
    '⇧+space, space, enter': -> Backbone.Mediator.publish 'level:shift-space-pressed'
    'escape': -> Backbone.Mediator.publish 'level:escape-pressed'

  # SETUP / TEARDOWN

  constructor: (options) ->
    super(options)
    @originalScripts = options.scripts
    @view = options.view
    @session = options.session
    @debugScripts = @view.getQueryVariable 'dev'
    @initProperties()
    @addScriptSubscriptions()

  setScripts: (@originalScripts) ->
    @quiet = true
    @initProperties()
    @loadFromSession()
    @quiet = false
    @run()

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

  loadFromSession: ->
    # load the queue with note groups to skip through
    @addEndedScriptsFromSession()
    @addPartiallyEndedScriptFromSession()
    @fireGoalNotesEarly()

  addPartiallyEndedScriptFromSession: ->
    scripts = @session.get('state').scripts
    return unless scripts?.currentScript
    script = _.find @scripts, {id: scripts.currentScript}
    return unless script
    @triggered.push(script.id)
    noteChain = @processScript(script)
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
        console.warn "Couldn't find script for", scriptID, "from scripts", @scripts, "when restoring session scripts."
        continue
      continue if script.repeats # repeating scripts are not 'rerun'
      @triggered.push(scriptID)
      @ended.push(scriptID)
      noteChain = @processScript(script)
      noteGroup.skipMe = true for noteGroup in noteChain
      @addNoteChain(noteChain, false)

  fireGoalNotesEarly: ->
    for noteGroup in @noteGroupQueue
      @processNoteGroup(noteGroup)
      for module in noteGroup.modules
        if module instanceof GoalScriptsModule
          notes = module.skipNotes()
          @processNote(note, noteGroup) for note in notes

  setWorldLoading: (@worldLoading) ->
    @run() unless @worldLoading

  destroy: ->
    @onEndAll()
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
      console.log "SCRIPT: Running script '#{script.id}'" if @debugScripts
      script.lastTriggered = new Date().getTime()
      @triggered.push(script.id) unless alreadyTriggered
      noteChain = @processScript(script)
      @addNoteChain(noteChain)
      @run()

  scriptPrereqsSatisfied: (script) ->
    _.every(script.scriptPrereqs or [], (prereq) => prereq in @triggered)

  processScript: (script) ->
    noteChain = script.noteChain
    noteGroup.scriptID = script.id for noteGroup in noteChain
    if noteChain.length
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
      sprite.id ?= 'Captain Anya'
    noteGroup.script ?= {}
    noteGroup.script.yields ?= true
    noteGroup.script.skippable ?= true
    noteGroup.modules = (new Module(noteGroup, @view) for Module in allScriptModules when Module.neededFor(noteGroup))

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
    console.log "SCRIPT: Starting note group '#{nextNoteGroup.name}'" if @debugScripts
    for module in nextNoteGroup.modules
      @processNote(note, nextNoteGroup) for note in module.startNotes()
    if nextNoteGroup.script.duration
      f = => @onNoteGroupTimeout? nextNoteGroup
      setTimeout(f, nextNoteGroup.script.duration)
    Backbone.Mediator.publish('note-group-started')

  skipAhead: ->
    return if @worldLoading
    return unless @noteGroupQueue[0]?.skipMe
    @ignoreEvents = true
    for noteGroup, i in @noteGroupQueue
      break unless noteGroup.skipMe
      console.log "SCRIPT: Skipping note group '#{noteGroup.name}'" if @debugScripts
      @processNoteGroup(noteGroup)
      for module in noteGroup.modules
        notes = module.skipNotes()
        @processNote(note, noteGroup) for note in notes
      @trackScriptCompletions(noteGroup)
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
    Backbone.Mediator.publish(note.channel, note.event)

  # ENDING NOTES

  onLevelRestarted: ->
    @quiet = true
    @endAll({force:true})
    @initProperties()
    @resetThings()
    Backbone.Mediator.publish 'script:reset'
    @quiet = false
    @run()

  onEndNoteGroup: (e) ->
    e?.preventDefault()
    # press enter
    return unless @currentNoteGroup?.script.skippable
    @endNoteGroup()
    @run()

  endNoteGroup: ->
    return if @ending # kill infinite loops right here
    @ending = true
    return unless @currentNoteGroup?
    console.log "SCRIPT: Ending note group '#{@currentNoteGroup.name}'" if @debugScripts
    clearTimeout(timeout) for timeout in @currentTimeouts
    for module in @currentNoteGroup.modules
      @processNote(note, @currentNoteGroup) for note in module.endNotes()
    Backbone.Mediator.publish 'note-group-ended' unless @quiet
    @scriptInProgress = false
    @ended.push(@currentNoteGroup.scriptID) if @currentNoteGroup.isLast
    @trackScriptCompletions(@currentNoteGroup)
    @currentNoteGroup = null
    unless @noteGroupQueue.length
      @notifyScriptStateChanged()
      @resetThings()
    @ending = false

  onEndAll: ->
    # press escape
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
        return

      @processNoteGroup(noteGroup)
      for module in noteGroup.modules
        notes = module.skipNotes()
        @processNote(note, noteGroup) for note in notes unless @quiet
      @trackScriptCompletions(noteGroup) unless @quiet

    @noteGroupQueue = []

    @resetThings()

  onNoteGroupTimeout: (noteGroup) ->
    return unless noteGroup is @currentNoteGroup
    @endNoteGroup()
    @run()

  resetThings: ->
    Backbone.Mediator.publish 'level-enable-controls', {}
    Backbone.Mediator.publish 'level-set-letterbox', { on: false }

  trackScriptCompletions: (noteGroup) ->
    return if @quiet
    return unless noteGroup.isLast
    @ended.push(noteGroup.scriptID) unless noteGroup.scriptID in @ended
    Backbone.Mediator.publish 'script:ended', {scriptID: noteGroup.scriptID}

  notifyScriptStateChanged: ->
    return if @quiet
    event =
      currentScript: @currentNoteGroup?.scriptID or null
      currentScriptOffset: @currentNoteGroup?.index or 0
    Backbone.Mediator.publish 'script:state-changed', event
