View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
Range = ace.require("ace/range").Range
Problem = require './problem'
SpellDebugView = require './spell_debug_view'
SpellToolbarView = require './spell_toolbar_view'

module.exports = class SpellView extends View
  id: 'spell-view'
  className: 'shown'
  template: template
  controlsEnabled: true
  eventsSuppressed: true
  writable: true

  subscriptions:
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'surface:frame-changed': 'onFrameChanged'
    'god:new-world-created': 'onNewWorld'
    'god:user-code-problem': 'onUserCodeProblem'
    'tome:manual-cast': 'onManualCast'
    'tome:reload-code': 'onCodeReload'
    'tome:spell-changed': 'onSpellChanged'
    'level:session-will-save': 'onSessionWillSave'
    'modal-closed': 'focus'
    'focus-editor': 'focus'
    'tome:spell-statement-index-updated': 'onStatementIndexUpdated'
    'spell-beautify': 'onSpellBeautify'

  events:
    'mouseout': 'onMouseOut'

  constructor: (options) ->
    super options
    @session = options.session
    @session.on 'change:multiplayer', @onMultiplayerChanged, @
    @spell = options.spell
    @problems = {}
    @writable = false unless me.team in @spell.permissions.readwrite  # TODO: make this do anything
    @highlightCurrentLine = _.throttle @highlightCurrentLine, 100

  afterRender: ->
    super()
    @createACE()
    @createACEShortcuts()
    @fillACE()
    if @session.get('multiplayer')
      @createFirepad()
    else
      # needs to happen after the code generating this view is complete
      setTimeout @onLoaded, 1

  createACE: ->
    # Test themes and settings here: http://ace.ajax.org/build/kitchen-sink.html
    @ace = ace.edit @$el.find('.ace')[0]
    @aceSession = @ace.getSession()
    @aceDoc = @aceSession.getDocument()
    @aceSession.setUseWorker false
    @aceSession.setMode 'ace/mode/javascript'
    @aceSession.setWrapLimitRange null
    @aceSession.setUseWrapMode true
    @aceSession.setNewLineMode "unix"
    @aceSession.setUseSoftTabs true
    @ace.setTheme 'ace/theme/textmate'
    @ace.setDisplayIndentGuides false
    @ace.setShowPrintMargin false
    @ace.setShowInvisibles false
    @ace.setBehavioursEnabled false
    @ace.setAnimatedScroll true
    @toggleControls null, @writable
    @aceSession.selection.on 'changeCursor', @onCursorActivity
    $(@ace.container).find('.ace_gutter').on 'click', '.ace_error, .ace_warning, .ace_info', @onAnnotationClick

  createACEShortcuts: ->
    @aceCommands = aceCommands = []
    ace = @ace
    addCommand = (c) ->
      ace.commands.addCommand c
      aceCommands.push c.name
    addCommand
      name: 'run-code'
      bindKey: {win: 'Shift-Enter|Ctrl-Enter|Ctrl-S', mac: 'Shift-Enter|Command-Enter|Ctrl-Enter|Command-S|Ctrl-S'}
      exec: -> Backbone.Mediator.publish 'tome:manual-cast', {}
    addCommand
      name: 'toggle-playing'
      bindKey: {win: 'Ctrl-P', mac: 'Command-P|Ctrl-P'}
      exec: -> Backbone.Mediator.publish 'level-toggle-playing'
    addCommand
      name: 'end-current-script'
      bindKey: {win: 'Shift-Space', mac: 'Shift-Space'}
      exec: -> Backbone.Mediator.publish 'level:shift-space-pressed'
    addCommand
      name: 'end-all-scripts'
      bindKey: {win: 'Escape', mac: 'Escape'}
      exec: -> Backbone.Mediator.publish 'level:escape-pressed'
    addCommand
      name: 'toggle-grid'
      bindKey: {win: 'Ctrl-G', mac: 'Command-G|Ctrl-G'}
      exec: -> Backbone.Mediator.publish 'level-toggle-grid'
    addCommand
      name: 'toggle-debug'
      bindKey: {win: 'Ctrl-\\', mac: 'Command-\\|Ctrl-\\'}
      exec: -> Backbone.Mediator.publish 'level-toggle-debug'
    addCommand
      name: 'toggle-pathfinding'
      bindKey: {win: 'Ctrl-O', mac: 'Command-O|Ctrl-O'}
      exec: -> Backbone.Mediator.publish 'level-toggle-pathfinding'
    addCommand
      name: 'level-scrub-forward'
      bindKey: {win: 'Ctrl-]', mac: 'Command-]|Ctrl-]'}
      exec: -> Backbone.Mediator.publish 'level-scrub-forward'
    addCommand
      name: 'level-scrub-back'
      bindKey: {win: 'Ctrl-[', mac: 'Command-[|Ctrl-]'}
      exec: -> Backbone.Mediator.publish 'level-scrub-back'
    addCommand
      name: 'spell-step-forward'
      bindKey: {win: 'Ctrl-Alt-]', mac: 'Command-Alt-]|Ctrl-Alt-]'}
      exec: -> Backbone.Mediator.publish 'spell-step-forward'
    addCommand
      name: 'spell-step-backward'
      bindKey: {win: 'Ctrl-Alt-[', mac: 'Command-Alt-[|Ctrl-Alt-]'}
      exec: -> Backbone.Mediator.publish 'spell-step-backward'
    addCommand
      name: 'spell-beautify'
      bindKey: {win: 'Ctrl-Shift-B', mac: 'Command-Shift-B|Ctrl-Shift-B'}
      exec: -> Backbone.Mediator.publish 'spell-beautify'

  fillACE: ->
    @ace.setValue @spell.source
    @ace.clearSelection()

  onMultiplayerChanged: ->
    if @session.get('multiplayer')
      @createFirepad()
    else
      @firepad?.dispose()

  createFirepad: ->
     # load from firebase or the original source if there's nothing there
    return if @firepadLoading
    @eventsSuppressed = true
    @loaded = false
    @previousSource = @ace.getValue()
    @ace.setValue('')
    fireURL = 'https://codecombat.firebaseio.com/' + @spell.pathComponents.join('/')
    @fireRef = new Firebase fireURL
    firepadOptions = userId: me.id
    @firepad = Firepad.fromACE @fireRef, @ace, firepadOptions
    @firepad.on 'ready', @onFirepadLoaded
    @firepadLoading = true

  onFirepadLoaded: =>
    @firepadLoading = false
    firepadSource = @ace.getValue()
    if firepadSource
      @spell.source = firepadSource
    else
      @ace.setValue @previousSource
      @ace.clearSelection()
    @onLoaded()

  onLoaded: =>
    @spell.transpile @spell.source
    @spell.loaded = true
    Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
    @eventsSuppressed = false  # Now that the initial change is in, we can start running any changed code
    @createToolbarView()

  createDebugView: ->
    @debugView = new SpellDebugView ace: @ace, thang: @thang
    @$el.append @debugView.render().$el.hide()

  createToolbarView: ->
    @toolbarView = new SpellToolbarView ace: @ace
    @$el.append @toolbarView.render().$el

  onMouseOut: (e) ->
    @debugView.onMouseOut e

  getSource: ->
    @ace.getValue()  # could also do @firepad.getText()

  setThang: (thang) ->
    @focus()
    return if thang.id is @thang?.id
    @thang = thang
    @spellThang = @spell.thangs[@thang.id]
    @createDebugView() unless @debugView
    @debugView.thang = @thang
    @toolbarView?.toggleFlow false
    @updateAether false, true
    @highlightCurrentLine()

  cast: ->
    Backbone.Mediator.publish 'tome:cast-spell', spell: @spell, thang: @thang

  notifySpellChanged: =>
    Backbone.Mediator.publish 'tome:spell-changed', spell: @spell

  notifyEditingEnded: =>
    return if @aceDoc.undergoingFirepadOperation  # from my Firepad ACE adapter
    Backbone.Mediator.publish('tome:editing-ended')

  notifyEditingBegan: =>
    return if @aceDoc.undergoingFirepadOperation  # from my Firepad ACE adapter
    Backbone.Mediator.publish('tome:editing-began')

  onManualCast: (e) ->
    cast = @$el.parent().length
    @recompile cast
    @focus() if cast

  onCodeReload: (e) ->
    return unless e.spell is @spell
    @reloadCode true

  reloadCode: (cast=true) ->
    @updateACEText @spell.originalSource
    @recompile cast

  recompileIfNeeded: =>
    @recompile() if @recompileNeeded

  recompile: (cast=true) ->
    @setRecompileNeeded false
    return if @spell.source is @getSource()
    @spell.transpile @getSource()
    @updateAether true, false
    @cast() if cast
    @notifySpellChanged()

  updateACEText: (source) ->
    @eventsSuppressed = true
    if @firepad
      @firepad.setText source
    else
      @ace.setValue source
    @eventsSuppressed = false
    @ace.resize true  # hack: @ace may not have updated its text properly, so we force it to refresh

  # Called from CastButtonView initially and whenever the delay is changed
  setAutocastDelay: (@autocastDelay) ->
    @createOnCodeChangeHandlers()

  createOnCodeChangeHandlers: ->
    @aceDoc.removeListener 'change', @onCodeChangeMetaHandler if @onCodeChangeMetaHandler
    autocastDelay = @autocastDelay ? 3000
    onSignificantChange = [
      _.debounce @setRecompileNeeded, autocastDelay - 100
      @currentAutocastHandler = _.debounce @recompileIfNeeded, autocastDelay
    ]
    onAnyChange = [
      _.debounce @updateAether, 500
      _.debounce @notifyEditingEnded, 1000
      _.throttle @notifyEditingBegan, 250
      _.throttle @notifySpellChanged, 300
    ]
    @onCodeChangeMetaHandler = =>
      return if @eventsSuppressed
      if not @spellThang or @spell.hasChangedSignificantly @getSource(), @spellThang.aether.raw
        callback() for callback in onSignificantChange  # Do these first
      callback() for callback in onAnyChange  # Then these
    @aceDoc.on 'change', @onCodeChangeMetaHandler

  setRecompileNeeded: (needed=true) =>
    if needed
      @recompileNeeded = needed  # and @recompileValid  # todo, remove if not caring about validity
    else
      @recompileNeeded = false

  onCursorActivity: =>
    @currentAutocastHandler?()

  # Design for a simpler system?
  # * Turn off ACE's JSHint worker
  # * Keep Aether linting, debounced, on any significant change
  # - Don't send runtime errors from in-progress worlds
  # - All problems just vanish when you make any change to the code
  # * You wouldn't accept any Aether updates/runtime information/errors unless its code was current when you got it
  # * Store the last run Aether in each spellThang and use it whenever its code actually is current
  #   This suffers from the problem that any whitespace/comment changes will lose your info, but what else
  #   could you do other than somehow maintain a mapping from current to original code locations?
  #   I guess you could use dynamic markers for problem ranges and keep annotations/alerts in when insignificant
  #   changes happen, but always treat any change in the (trimmed) number of lines as a significant change.
  #   Ooh, that's pretty nice. Gets you most of the way there and is simple.
  # - All problems have a master representation as a Problem, and we can easily generate all Problems from
  #   any Aether instance. Then when we switch contexts in any way, we clear, recreate, and reapply the Problems.
  # * Problem alerts will have their own templated ProblemAlertViews
  # * We'll only show the first problem alert, and it will always be at the bottom.
  #   Annotations and problem ranges can show all, I guess.
  # * The editor will reserve space for one annotation as a codeless area.
  # - Problem alerts and ranges will only show on fully cast worlds. Annotations will show continually.

  updateAether: (force=false, fromCodeChange=true) =>
    # Depending on whether we have any code changes, significant code changes, or have switched
    # to a new spellThang, we may want to refresh our Aether display.
    return unless aether = @spellThang?.aether
    source = @getSource()
    codeHasChangedSignificantly = force or @spell.hasChangedSignificantly source, aether.raw
    needsUpdate = codeHasChangedSignificantly or @spellThang isnt @lastUpdatedAetherSpellThang
    return if not needsUpdate and aether is @displayedAether
    castAether = @spellThang.castAether
    codeIsAsCast = castAether and not @spell.hasChangedSignificantly source, castAether.raw
    aether = castAether if codeIsAsCast
    return if not needsUpdate and aether is @displayedAether

    # Now that that's figured out, perform the update.
    @clearAetherDisplay()
    aether.transpile source if codeHasChangedSignificantly and not codeIsAsCast
    @displayAether aether
    @lastUpdatedAetherSpellThang = @spellThang
    @guessWhetherFinished aether if fromCodeChange

  clearAetherDisplay: ->
    problem.destroy() for problem in @problems
    @problems = []
    @aceSession.setAnnotations []
    @highlightCurrentLine {}  # This'll remove all highlights

  displayAether: (aether) ->
    @displayedAether = aether
    isCast = not _.isEmpty(aether.metrics) or _.some aether.problems.errors, {type: 'runtime'}
    @problems = []
    annotations = []
    for aetherProblem, problemIndex in aether.getAllProblems()
      @problems.push problem = new Problem aether, aetherProblem, @ace, isCast and problemIndex is 0, isCast
      annotations.push problem.annotation if problem.annotation
    @aceSession.setAnnotations annotations
    @highlightCurrentLine aether.flow unless _.isEmpty aether.flow
    #console.log '  and we could do the metrics', aether.metrics unless _.isEmpty aether.metrics
    #console.log '  and we could do the style', aether.style unless _.isEmpty aether.style
    #console.log '  and we could do the visualization', aether.visualization unless _.isEmpty aether.visualization
    # Could use the user-code-problem style... or we could leave that to other places.
    @ace[if @problems.length then 'setStyle' else 'unsetStyle'] 'user-code-problem'
    Backbone.Mediator.publish 'tome:problems-updated', spell: @spell, problems: @problems, isCast: isCast
    @ace.resize()

  # Autocast:
  # Goes immediately if the code is a) changed and b) complete/valid and c) the cursor is at beginning or end of a line
  # We originall thought it would:
  # - Go after specified delay if a) and b) but not c)
  # - Go only when manually cast or deselecting a Thang when there are errors
  # But the error message display was delayed, so now trying:
  # - Go after specified delay if a) and not b) or c)
  guessWhetherFinished: (aether) ->
    return if @autocastDelay > 60000
    #@recompileValid = not aether.getAllProblems().length
    valid = not aether.getAllProblems().length
    cursorPosition = @ace.getCursorPosition()
    currentLine = @aceDoc.$lines[cursorPosition.row].replace(/[ \t]*\/\/[^"']*/g, '').trimRight()  # trim // unless inside "
    endOfLine = cursorPosition.column >= currentLine.length  # just typed a semicolon or brace, for example
    beginningOfLine = not currentLine.substr(0, cursorPosition.column).trim().length  # uncommenting code, for example
    #console.log "finished?", valid, endOfLine, beginningOfLine, cursorPosition, currentLine.length, aether, new Date() - 0, currentLine
    if valid and endOfLine or beginningOfLine
      @recompile()
      #console.log "recompile now!"
    #else if not valid
    #  # if this works, we can get rid of all @recompileValid logic
    #  console.log "not valid, but so we'll wait to do it in", @autocastDelay + "ms"
    #else
    #  console.log "valid but not at end of line; recompile in", @autocastDelay + "ms"

  onSpellChanged: (e) ->
    @spellHasChanged = true

  onSessionWillSave: (e) ->
    return unless @spellHasChanged
    setTimeout(=>
      unless @spellHasChanged
        @$el.find('.save-status').finish().show().fadeOut(2000)
    , 1000)
    @spellHasChanged = false

  onUserCodeProblem: (e) ->
    return @onInfiniteLoop e if e.problem.id is "runtime_InfiniteLoop"
    return unless e.problem.userInfo.methodName is @spell.name
    return unless spellThang = _.find @spell.thangs, (spellThang, thangID) -> thangID is e.problem.userInfo.thangID
    return if @spell.hasChangedSignificantly @getSource()  # don't show this error if we've since edited the code
    spellThang.aether.addProblem e.problem
    @lastUpdatedAetherSpellThang = null  # force a refresh without a re-transpile
    @updateAether false, false

  onInfiniteLoop: (e) ->
    return unless @spellThang
    @spellThang.aether.addProblem e.problem
    @lastUpdatedAetherSpellThang = null  # force a refresh without a re-transpile
    @updateAether false, false

  onNewWorld: (e) ->
    @spell.removeThangID thangID for thangID of @spell.thangs when not e.world.getThangByID thangID
    for thangID, spellThang of @spell.thangs
      thang = e.world.getThangByID(thangID)
      aether = e.world.userCodeMap[thangID]?[@spell.name]  # Might not be there if this is a new Programmable Thang.
      spellThang.castAether = aether
      spellThang.aether = @spell.createAether thang
      #console.log thangID, @spell.spellKey, "ran", aether.metrics.callsExecuted, "times over", aether.metrics.statementsExecuted, "statements, with max recursion depth", aether.metrics.maxDepth, "and full flow/metrics", aether.metrics, aether.flow
    @spell.transpile()
    @updateAether false, false

  # --------------------------------------------------------------------------------------------------

  focus: ->
    # TODO: it's a hack checking if a modal is visible; the events should be removed somehow
    # but this view is not part of the normal subview destroying because of how it's swapped
    return unless @controlsEnabled and @writable and $('.modal:visible').length is 0
    return if @ace.isFocused()
    @ace.focus()
    @ace.clearSelection()

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang?.id
    @thang = e.selectedThang  # update our thang to the current version
    @highlightCurrentLine()

  onStatementIndexUpdated: (e) ->
    return unless e.ace is @ace
    @highlightCurrentLine()

  highlightCurrentLine: (flow) =>
    # TODO: move this whole thing into SpellDebugView or somewhere?
    @highlightComments() unless @destroyed
    flow ?= @spellThang?.castAether?.flow
    return unless flow
    executed = []
    matched = false
    states = flow.states ? []
    currentCallIndex = null
    for callState, callNumber in states
      if not currentCallIndex? and callState.userInfo?.time > @thang.world.age
        currentCallIndex = callNumber - 1
      if matched
        executed.pop()
        break
      executed.push []
      for state, statementNumber in callState.statements
        if state.userInfo?.time > @thang.world.age
          matched = true
          break
        _.last(executed).push state
        #state.executing = true if state.userInfo?.time is @thang.world.age  # no work
    currentCallIndex ?= callNumber - 1
    #console.log "got call index", currentCallIndex, "for time", @thang.world.age, "out of", states.length

    # TODO: don't redo the markers if they haven't actually changed
    for markerRange in (@markerRanges ?= [])
      markerRange.start.detach()
      markerRange.end.detach()
      @aceSession.removeMarker markerRange.id
    @markerRanges = []
    @debugView.setVariableStates {}
    @aceSession.removeGutterDecoration row, 'executing' for row in [0 ... @aceSession.getLength()]
    $(@ace.container).find('.ace_gutter-cell.executing').removeClass('executing')
    if not executed.length or (@spell.name is "plan" and @spellThang.castAether.metrics.statementsExecuted < 20)
      @toolbarView?.toggleFlow false
      return
    lastExecuted = _.last executed
    @toolbarView?.toggleFlow true
    statementIndex = Math.max 0, lastExecuted.length - 1
    @toolbarView?.setCallState states[currentCallIndex], statementIndex, currentCallIndex, @spellThang.castAether.metrics
    marked = {}
    lastExecuted = lastExecuted[0 .. @toolbarView.statementIndex] if @toolbarView?.statementIndex?
    for state, i in lastExecuted
      [start, end] = state.range
      clazz = if i is lastExecuted.length - 1 then 'executing' else 'executed'
      if clazz is 'executed'
        continue if marked[start.row]
        marked[start.row] = true
        markerType = "fullLine"
      else
        @debugView.setVariableStates state.variables
        markerType = "text"
      markerRange = new Range start.row, start.col, end.row, end.col
      markerRange.start = @aceDoc.createAnchor markerRange.start
      markerRange.end = @aceDoc.createAnchor markerRange.end
      markerRange.id = @aceSession.addMarker markerRange, clazz, markerType
      @markerRanges.push markerRange
      @aceSession.addGutterDecoration start.row, clazz if clazz is 'executing'
    null

  highlightComments: ->
    lines = $(@ace.container).find('.ace_text-layer .ace_line_group')
    session = @aceSession
    $(@ace.container).find('.ace_gutter-cell').each (index, el) ->
      line = $(lines[index])
      session.removeGutterDecoration index, 'comment-line'
      if line.find('.ace_comment').length
        session.addGutterDecoration index, 'comment-line'

  onAnnotationClick: ->
    alertBox = $("<div class='alert alert-info fade in'>#{msg}</div>")
    offset = $(@).offset()
    offset.left -= 162  # default width of the Bootstrap alert here
    alertBox.css(offset).css('z-index', 500).css('position', 'absolute')
    $('body').append(alertBox.alert())
    _.delay (-> alertBox.alert('close')), 2500

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, @writable
  toggleControls: (e, enabled) ->
    return if e?.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled and @writable
    disabled = not enabled
    $('body').focus() if disabled and $(document.activeElement).is('.ace_text-input')
    @ace.setReadOnly disabled
    @ace[if disabled then "setStyle" else "unsetStyle"] "disabled"
    @toggleBackground()

  toggleBackground: =>
    # TODO: make the background an actual background and do the CSS trick
    # used in spell_list_entry.sass for disabling
    background = @$el.find('.code-background')[0]
    if background.naturalWidth is 0  # not loaded yet
      return _.delay @toggleBackground, 100
    filters.revertImage background if @controlsEnabled
    filters.darkenImage background, 0.8 unless @controlsEnabled

  onSpellBeautify: (e) ->
    return unless @spellThang and (@ace.isFocused() or e.spell is @spell)
    ugly = @getSource()
    pretty = @spellThang.aether.beautify ugly
    @ace.setValue pretty

  dismiss: ->
    @recompile() if @spell.hasChangedSignificantly @getSource()

  destroy: ->
    $(@ace?.container).find('.ace_gutter').off 'click', '.ace_error, .ace_warning, .ace_info', @onAnnotationClick
    @firepad?.dispose()
    @ace?.commands.removeCommand command for command in @aceCommands
    @ace?.destroy()
    @ace = null
    @aceDoc?.off 'change', @onCodeChangeMetaHandler
    @aceDoc = null
    @aceSession?.selection.off 'changeCursor', @onCursorActivity
    @aceSession = null
    @debugView?.destroy()
    @spell = null
    @session.off 'change:multiplayer', @onMultiplayerChanged, @
    for fat in ['notifySpellChanged', 'notifyEditingEnded', 'notifyEditingBegan', 'onFirepadLoaded', 'onLoaded', 'toggleBackground', 'setRecompileNeeded', 'onCursorActivity', 'highlightCurrentLine', 'updateAether', 'onCodeChangeMetaHandler', 'recompileIfNeeded', 'currentAutocastHandler']
      @[fat] = null
    super()
