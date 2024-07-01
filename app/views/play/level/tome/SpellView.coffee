require('app/styles/play/level/tome/spell.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/tome/spell'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
ace = require('lib/aceContainer')
Range = ace.require('ace/range').Range
UndoManager = ace.require('ace/undomanager').UndoManager
Problem = require './Problem'
SpellDebugView = require './SpellDebugView'
SpellTranslationView = require './SpellTranslationView'
SpellToolbarView = require './SpellToolbarView'
LevelComponent = require 'models/LevelComponent'
UserCodeProblem = require 'models/UserCodeProblem'
aceUtils = require 'core/aceUtils'
blocklyUtils = require 'core/blocklyUtils'
{ codeToBlocks, prepareBlockIntelligence } = require 'lib/code-to-blocks'
CodeLog = require 'models/CodeLog'
Autocomplete = require './editor/autocomplete'
TokenIterator = ace.require('ace/token_iterator').TokenIterator
LZString = require 'lz-string'
utils = require 'core/utils'
Aether = require 'lib/aether/aether'
Blockly = require 'blockly'
blocklyUtils.registerBlocklyTheme()
storage = require 'core/storage'
AceDiff = require 'ace-diff'
globalVar = require 'core/globalVar'
fetchJson = require 'core/api/fetch-json'
store = require 'core/store'
require('app/styles/play/level/tome/ace-diff-spell.sass')

PERSIST_BLOCK_STATE = false

module.exports = class SpellView extends CocoView
  id: 'spell-view'
  className: 'shown'
  template: template
  controlsEnabled: true
  eventsSuppressed: true
  writable: true
  languagesThatUseWorkers: ['html']

  keyBindings:
    'default': null
    'vim': 'ace/keyboard/vim'
    'emacs': 'ace/keyboard/emacs'

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'surface:frame-changed': 'onFrameChanged'
    'surface:coordinate-selected': 'onCoordinateSelected'
    'god:new-world-created': 'onNewWorld'
    'god:user-code-problem': 'onUserCodeProblem'
    'god:non-user-code-problem': 'onNonUserCodeProblem'
    'tome:manual-cast': 'onManualCast'
    'tome:spell-changed': 'onSpellChanged'
    'tome:spell-created': 'onSpellCreated'
    'tome:completer-add-user-snippets': 'onAddUserSnippets'
    'level:session-will-save': 'onSessionWillSave'
    'modal:closed': 'focus'
    'tome:focus-editor': 'focus'
    'tome:spell-statement-index-updated': 'onStatementIndexUpdated'
    'tome:change-language': 'onChangeLanguage'
    'tome:change-config': 'onChangeEditorConfig'
    'tome:update-snippets': 'addAutocompleteSnippets'
    'tome:insert-snippet': 'onInsertSnippet'
    'tome:spell-beautify': 'onSpellBeautify'
    'tome:toggle-blocks': 'onToggleBlocks'
    'tome:problems-updated': 'onProblemsUpdated'
    'script:state-changed': 'onScriptStateChange'
    'playback:ended-changed': 'onPlaybackEndedChanged'
    'level:contact-button-pressed': 'onContactButtonPressed'
    'level:show-victory': 'onShowVictory'
    'web-dev:error': 'onWebDevError'
    'tome:palette-updated': 'onPaletteUpdated'
    'level:gather-chat-message-context': 'onGatherChatMessageContext'
    'tome:fix-code': 'onFixCode'
    'level:update-solution': 'onUpdateSolution'
    'level:toggle-solution': 'onToggleSolution'
    'level:close-solution': 'closeSolution'
    'level:streaming-solution': 'onStreamingSolution'
    'websocket:asking-help': 'onAskingHelp'
    'playback:cinematic-playback-started': 'onCinematicPlaybackStarted'
    'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded'
    'blockly:clicked-block': 'onClickedBlock'

  events:
    'mouseout': 'onMouseOut'

  constructor: (options) ->
    @supermodel = options.supermodel
    super options
    @worker = options.worker
    @session = options.session
    @spell = options.spell
    @courseID = options.courseID
    @problems = []
    @savedProblems = {} # Cache saved user code problems to prevent duplicates
    @writable = false unless me.team in @spell.permissions.readwrite  # TODO: make this do anything
    @highlightCurrentLine = _.throttle @highlightCurrentLine, 100
    $(window).on 'resize', @onWindowResize
    @observing = @session.get('creator') isnt me.id
    @spectateView = options.spectateView
    @loadedToken = {}
    @addUserSnippets = _.debounce @reallyAddUserSnippets, 500, {maxWait: 1500, leading: true, trailing: false}
    @teaching = utils.getQueryVariable('teaching', false)
    @urlSession = utils.getQueryVariable('session')

  afterRender: ->
    super()
    @createACE()
    @createACEShortcuts()
    @hookACECustomBehavior()
    unless @spectateView
      try
        @fillACESolution()
      catch err
        console.error("Could not fill ace solution:", err)
    @fillACE()
    @createOnCodeChangeHandlers()
    @lockDefaultCode()
    _.defer @onAllLoaded  # Needs to happen after the code generating this view is complete

  # This ACE is used for the code editor, and is only instantiated once per level.
  createACE: ->
    # Test themes and settings here: http://ace.ajax.org/build/kitchen-sink.html
    aceConfig = me.get('aceConfig') ? {}
    @destroyAceEditor(@ace)
    @ace = ace.edit @$el.find('.ace')[0]
    @aceSession = @ace.getSession()
    # Override setAnnotations so the Ace html worker doesn't clobber our annotations
    @reallySetAnnotations = @aceSession.setAnnotations.bind(@aceSession)
    @aceSession.setAnnotations = (annotations) =>
      previousAnnotations = @aceSession.getAnnotations()
      newAnnotations = _.filter previousAnnotations, (annotation) -> annotation.createdBy? # Keep the ones we generated
        .concat _.reject annotations, (annotation) -> # Ignore this particular info-annotation the html worker generates
          annotation.text is 'Start tag seen without seeing a doctype first. Expected e.g. <!DOCTYPE html>.'
      @reallySetAnnotations newAnnotations
    @aceDoc = @aceSession.getDocument()
    @aceSession.setUseWorker @spell.language in @languagesThatUseWorkers
    @aceSession.setMode aceUtils.aceEditModes[@spell.language]
    @aceSession.setWrapLimitRange null
    @aceSession.setUseWrapMode true
    @aceSession.setNewLineMode 'unix'
    @aceSession.setUseSoftTabs true
    @ace.setTheme 'ace/theme/textmate'
    @ace.setDisplayIndentGuides false
    @ace.setShowPrintMargin false
    @ace.setShowInvisibles false
    @ace.setBehavioursEnabled aceConfig.behaviors
    @ace.setAnimatedScroll true
    @ace.setShowFoldWidgets false
    @ace.setKeyboardHandler @keyBindings[aceConfig.keyBindings ? 'default']
    @ace.$blockScrolling = Infinity
    @ace.on 'mousemove', @onAceMouseMove
    @ace.on 'mouseout', @onAceMouseOut
    @toggleControls null, @writable
    @aceSession.selection.on 'changeCursor', @onCursorActivity
    $(@ace.container).find('.ace_gutter').on 'click mouseenter', '.ace_error, .ace_warning, .ace_info', @onAnnotationClick
    $(@ace.container).find('.ace_gutter').on 'click', @onGutterClick
    liveCompletion = aceConfig.liveCompletion ? true
    classroomLiveCompletion = (@options.classroomAceConfig ? {liveCompletion: true}).liveCompletion
    liveCompletion = classroomLiveCompletion && liveCompletion
    @initAutocomplete liveCompletion

    if @teaching
      console.log('connect provider:', @urlSession)
      @yjsProvider = aceUtils.setupCRDT("#{@urlSession}", me.broadName(), '', @ace)
      @yjsProvider.connections = 1
      @yjsProvider.awareness.on('change', =>
        console.log("provider get connections? ", @yjsProvider.awareness.getStates().size)
        @yjsProvider.connections = @yjsProvider.awareness.getStates().size
      )

    return if @session.get('creator') isnt me.id or @session.fake
    # Create a Spade to 'dig' into Ace.
    @spade = new Spade()
    @spade.track(@ace)
    @spade.createUIEvent "spade-created"
    # If a user is taking longer than 10 minutes, let's log it.
    saveSpadeDelay = 10 * 60 * 1000
    if @options.level.get('releasePhase') is 'beta'
      saveSpadeDelay = 3 * 60 * 1000  # Capture faster for beta levels, to be more likely to get something
    else if Math.random() < 0.05 and _.find(utils.freeAccessLevels, access: 'short', slug: @options.level.get('slug'))
      saveSpadeDelay = 3 * 60 * 1000  # Capture faster for some free levels to compare with beta levels
    @saveSpadeTimeout = setTimeout @saveSpade, saveSpadeDelay

  createACEShortcuts: ->
    @aceCommands = aceCommands = []
    addCommand = (c) =>
      @ace.commands.addCommand c
      aceCommands.push c.name
    addCommand
      name: 'run-code'
      bindKey: {win: 'Shift-Enter|Ctrl-Enter', mac: 'Shift-Enter|Command-Enter|Ctrl-Enter'}
      exec: => Backbone.Mediator.publish 'tome:manual-cast', {realTime: @options.level.isType('game-dev')}
    unless @observing
      addCommand
        name: 'run-code-real-time'
        bindKey: {win: 'Ctrl-Shift-Enter', mac: 'Command-Shift-Enter|Ctrl-Shift-Enter'}
        exec: =>
          doneButton = @$('.done-button:visible')
          if doneButton.length
            doneButton.trigger 'click'
          else if @options.level.get('replayable') and (timeUntilResubmit = @session.timeUntilResubmit()) > 0
            Backbone.Mediator.publish 'tome:manual-cast-denied', timeUntilResubmit: timeUntilResubmit
          else
            Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}
    addCommand
      name: 'no-op'
      bindKey: {win: 'Ctrl-S', mac: 'Command-S|Ctrl-S'}
      exec: ->  # just prevent page save call
    addCommand
      name: 'previous-line'
      bindKey: {mac: 'Ctrl-P'}
      passEvent: true
      exec: => @ace.execCommand 'golineup'  # stop trying to jump to matching paren, I want default Mac/Emacs previous line
    addCommand
      name: 'toggle-playing'
      bindKey: {win: 'Ctrl-P', mac: 'Command-P'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'level:toggle-playing', {}
    addCommand
      name: 'end-current-script'
      bindKey: {win: 'Shift-Space', mac: 'Shift-Space'}
      readOnly: true
      exec: =>
        if @scriptRunning
          Backbone.Mediator.publish 'level:shift-space-pressed', {}
        else
          @ace.insert ' '
    addCommand
      name: 'end-all-scripts'
      bindKey: {win: 'Escape', mac: 'Escape'}
      readOnly: true
      exec: ->
        Backbone.Mediator.publish 'level:escape-pressed', {}
    addCommand
      name: 'unfocus-editor'
      bindKey: {win: 'Escape', mac: 'Escape'}
      readOnly: true
      exec: ->
        return unless utils.isOzaria
        # In screen reader mode, we need to move focus to next element on escape, since tab won't.
        # Next element happens to be #run button, or maybe #update-code button in game-dev.
        # We need this even when you're not in screen reader mode, so you can tab over to enable it.
        if $(document.activeElement).hasClass 'ace_text-input'
          $('#run, #update-code').focus()
    addCommand
      name: 'toggle-grid'
      bindKey: {win: 'Ctrl-G', mac: 'Command-G|Ctrl-G'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'level:toggle-grid', {}
    addCommand
      name: 'toggle-debug'
      bindKey: {win: 'Ctrl-\\', mac: 'Command-\\|Ctrl-\\'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'level:toggle-debug', {}
    addCommand
      name: 'toggle-pathfinding'
      bindKey: {win: 'Ctrl-O', mac: 'Command-O|Ctrl-O'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'level:toggle-pathfinding', {}
    addCommand
      name: 'level-scrub-forward'
      bindKey: {win: 'Ctrl-]', mac: 'Command-]|Ctrl-]'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'level:scrub-forward', {}
    addCommand
      name: 'level-scrub-back'
      bindKey: {win: 'Ctrl-[', mac: 'Command-[|Ctrl-]'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'level:scrub-back', {}
    addCommand
      name: 'spell-step-forward'
      bindKey: {win: 'Ctrl-Alt-]', mac: 'Command-Alt-]|Ctrl-Alt-]'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'tome:spell-step-forward', {}
    addCommand
      name: 'spell-step-backward'
      bindKey: {win: 'Ctrl-Alt-[', mac: 'Command-Alt-[|Ctrl-Alt-]'}
      readOnly: true
      exec: -> Backbone.Mediator.publish 'tome:spell-step-backward', {}
    addCommand
      name: 'spell-beautify'
      bindKey: {win: 'Ctrl-Shift-B', mac: 'Command-Shift-B|Ctrl-Shift-B'}
      exec: -> Backbone.Mediator.publish 'tome:spell-beautify', {}
    addCommand
      name: 'prevent-line-jump'
      bindKey: {win: 'Ctrl-L', mac: 'Command-L'}
      passEvent: true
      exec: ->  # just prevent default ACE go-to-line alert
    addCommand
      # TODO: Restrict to beginner campaign levels like we do backspaceThrottle
      name: 'enter-skip-delimiters'
      bindKey: 'Enter|Return'
      exec: =>
        if @aceSession.selection.isEmpty()
          cursor = @ace.getCursorPosition()
          line = @aceDoc.getLine(cursor.row)
          if delimMatch = line.substring(cursor.column).match /^(["|']?\)+;?)/
            newRange = @ace.getSelectionRange()
            newRange.setStart newRange.start.row, newRange.start.column + delimMatch[1].length
            newRange.setEnd newRange.end.row, newRange.end.column + delimMatch[1].length
            @aceSession.selection.setSelectionRange newRange
        @ace.execCommand 'insertstring', '\n'
    addCommand
      name: 'disable-spaces'
      bindKey: 'Space'
      exec: =>
        disableSpaces = @options.level.get('disableSpaces') or false
        aceConfig = me.get('aceConfig') ? {}
        disableSpaces = false if aceConfig.keyBindings and aceConfig.keyBindings isnt 'default'  # Not in vim/emacs mode
        disableSpaces = false if @spell.language in ['lua', 'java', 'cpp', 'coffeescript', 'html']  # Don't disable for more advanced/experimental languages
        if not disableSpaces or (_.isNumber(disableSpaces) and disableSpaces < me.level())
          return @ace.execCommand 'insertstring', ' '
        line = @aceDoc.getLine @ace.getCursorPosition().row
        return @ace.execCommand 'insertstring', ' ' if @singleLineCommentRegex().test line

    if @options.level.get 'backspaceThrottle'
      addCommand
        name: 'throttle-backspaces'
        bindKey: 'Backspace'
        exec: =>
          # Throttle the backspace speed
          # Slow to 500ms when whitespace at beginning of line is first encountered
          # Slow to 100ms for remaining whitespace at beginning of line
          # Rough testing showed backspaces happen at 150ms when tapping.
          # Backspace speed varies by system when holding, 30ms on fastest Macbook setting.
          nowDate = Date.now()
          if @aceSession.selection.isEmpty()
            cursor = @ace.getCursorPosition()
            line = @aceDoc.getLine(cursor.row)
            if /^\s*$/.test line.substring(0, cursor.column)
              @backspaceThrottleMs ?= 500
              # console.log "SpellView @backspaceThrottleMs=#{@backspaceThrottleMs}"
              # console.log 'SpellView lastBackspace diff', nowDate - @lastBackspace if @lastBackspace?
              if not @lastBackspace? or nowDate - @lastBackspace > @backspaceThrottleMs
                @backspaceThrottleMs = 100
                @lastBackspace = nowDate
                @ace.remove "left"
              return
          @backspaceThrottleMs = null
          @lastBackspace = nowDate
          @ace.remove "left"


  hookACECustomBehavior: ->
    aceConfig = me.get('aceConfig') ? {}
    @ace.commands.on 'exec', (e) =>
      # When pressing enter with an active selection, just make a new line under it.
      if e.command.name is 'enter-skip-delimiters'
        selection = @ace.selection.getRange()
        unless selection.start.column is selection.end.column and selection.start.row is selection.end.row
          e.editor.execCommand 'gotolineend'
          return true

    # Add visual indent guides
    language = @spell.language
    ensureLineStartsBlock = (line) ->
      return false unless language is "python"
      match = /^\s*([^#]+)/.exec(line)
      return false if not match?
      return /:\s*$/.test(match[1])

    @indentDivMarkers = []

    @aceSession.addDynamicMarker
      update: (_, markerLayer, session, config) =>
        Range = ace.require('ace/range').Range

        foldWidgets = @aceSession.foldWidgets
        return if not foldWidgets?

        lines = @aceDoc.getAllLines()
        startOfRow = (r) ->
          str = lines[r]
          ar = str.match(/^\s*/)
          ar.pop().length

        colors = [{border: '74,144,226', fill: '108,162,226'}, {border: '132,180,235', fill: '230,237,245'}]

        @indentDivMarkers.forEach((node) -> node.remove())
        @indentDivMarkers = []

        for row in [0..@aceSession.getLength()]
          foldWidgets[row] = @aceSession.getFoldWidget(row) unless foldWidgets[row]?
          continue unless foldWidgets? and foldWidgets[row] is "start"
          try
            docRange = @aceSession.getFoldWidgetRange(row)
          catch error
            console.warn "Couldn't find fold widget docRange for row #{row}:", error
          if not docRange?
            guess = startOfRow(row)
            docRange = new Range(row,guess,row,guess+4)

          continue unless ensureLineStartsBlock(lines[row])

          if /^\s+$/.test lines[docRange.end.row+1]
            docRange.end.row += 1

          xstart = startOfRow(row)
          if language is 'python'
            requiredIndent = new RegExp '^' + new Array(Math.floor(xstart / 4 + 1)).join('(    |\t)') + '(    |\t)+(\\S|\\s*$)'
            for crow in [docRange.start.row+1..docRange.end.row]
              unless requiredIndent.test lines[crow]
                docRange.end.row = crow - 1
                break

          rstart = @aceSession.documentToScreenPosition docRange.start.row, docRange.start.column
          rend = @aceSession.documentToScreenPosition docRange.end.row, docRange.end.column
          range = new Range rstart.row, rstart.column, rend.row, rend.column
          level = Math.floor(xstart / 4)
          color = colors[level % colors.length]
          bw = 3
          to = markerLayer.$getTop(range.start.row, config)
          t = markerLayer.$getTop(range.start.row + 1, config)
          h = config.lineHeight * (range.end.row - range.start.row)
          l = markerLayer.$padding + xstart * config.characterWidth
          # w = (data.i - data.b) * config.characterWidth
          w = 4 * config.characterWidth
          fw = config.characterWidth * ( @aceSession.getScreenLastRowColumn(range.start.row) - xstart )

          lineAbove = document.createElement "div"
          lineAbove.setAttribute "style", """
            position: absolute; top: #{to}px; left: #{l}px; width: #{fw+bw}px; height: #{config.lineHeight}px;
            border: #{bw}px solid rgba(#{color.border},1); border-left: none;
          """

          indentedBlock = document.createElement "div"
          indentedBlock.setAttribute "style", """
            position: absolute; top: #{t}px; left: #{l}px; width: #{w}px; height: #{h}px; background-color: rgba(#{color.fill},0.5);
            border-right: #{bw}px solid rgba(#{color.border},1); border-bottom: #{bw}px solid rgba(#{color.border},1);
          """

          indentVisualMarker = document.createElement "div"
          indentVisualMarker.appendChild(lineAbove)
          indentVisualMarker.appendChild(indentedBlock)

          @indentDivMarkers.push(indentVisualMarker)

        markerLayer.elt("indent-highlight")
        parentNode = markerLayer.element.childNodes[markerLayer.i - 1] ? markerLayer.element.lastChild
        parentNode.appendChild(indentVisualMarker) for indentVisualMarker in @indentDivMarkers

  fillACE: ->
    @ace.setValue @spell.source
    @aceSession.setUndoManager(new UndoManager())
    @ace.clearSelection()
    @addBlockly() if @options.blocks

  onPaletteUpdated: (e) ->
    return if @propertyEntryGroups
    @propertyEntryGroups = e.entryGroups
    if @awaitingBlockly
      @addBlockly()
      @awaitingBlockly = false

  addBlockly: ->
    unless @propertyEntryGroups
      @awaitingBlockly = true
      return
    codeLanguage = @spell.language
    @blocklyToolbox = blocklyUtils.createBlocklyToolbox({ @propertyEntryGroups, codeLanguage, codeFormat: @options.codeFormat, level: @options.level })
    # codeToBlocks prepareBlockIntelligence function needs the JavaScript version of the toolbox
    @blocklyToolboxJS = if codeLanguage is 'javascript' then @blocklyToolbox else blocklyUtils.createBlocklyToolbox({ @propertyEntryGroups, codeLanguage: 'javascript', codeFormat: @options.codeFormat, level: @options.level })
    targetDiv = @$('.blockly-container')
    blocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox: @blocklyToolbox, codeLanguage, codeFormat: @options.codeFormat, product: @options.level.get('product') or 'codecombat' })
    @blockly = Blockly.inject targetDiv[0], blocklyOptions
    @blocklyActive = true
    blocklyUtils.initializeBlocklyTooltips()
    if @onCodeChangeMetaHandler
      @blockly.addChangeListener @onBlocklyEvent

    @lastBlocklyState = if PERSIST_BLOCK_STATE and not @session.fake then storage.load "lastBlocklyState_#{@options.level.get('original')}_#{@session.id}" else null
    if @lastBlocklyState
      @awaitingBlocklySerialization = true
      blocklyUtils.loadBlocklyState { blocklyState: @lastBlocklyState, blockly: @blockly }
      for block in @blockly.getAllBlocks() when block.type is 'comment'
        # Make long comments not so long. (The full comments will be visible, wrapped, in text version anyway.)
        # TODO: do we like this?
        block.setCollapsed true
      @recompile()
    else
      # Initialize Blockly from the text code
      @awaitingBlocklySerialization = true
      @aceToBlockly true

    @resizeBlockly()

  getBlocklySource: ->
    blocklyUtils.getBlocklySource @blockly, { codeLanguage: @spell.language, product: @options.level.get('product', true) or 'codecombat' }

  onClickedBlock: (e) ->
    # We monkey-patch Blockly egregiously to make this work
    return unless $(e.block).parents('.blocklyFlyout').length
    return if e.block.classList?[0] is 'blocklyEditableText'  # Number?
    # This is a block in the toolbox flyout. If we can, let's just directly add it to the end of our program.
    blockNode = e.block
    blockNode = blockNode.parentNode while not blockNode.dataset?.id and blockNode.parentNode
    return unless blockNode.dataset?.id
    # Method 1: try to create the block from the flyout
    newBlock = blocklyUtils.createBlockById workspace: @blockly, id: blockNode.dataset.id, codeLanguage: @spell.language
    return if newBlock
    # Method 2: try to use its tooltip. Doesn't update if you changed the flyout block (for example, from "up" to "down")
    blockSource = e.block.tooltip?.docFormatter?.doc?.example
    if not blockSource
      # Method 3: try to use our autocomplete snippets. (Should we even use this? Also doesn't update.)
      method = e.text.trim().split(/\s/g)[0].trim()
      matchingSnippet = _.find (_.values(@autocomplete?.snippetManager?.snippetMap?._ or {})), (snippet) ->
        snippet.tabTrigger is method and snippet.autocompletePriority > 0  # Don't pull in auto-added snippets
      blockSource = matchingSnippet?.content
    return unless blockSource
    source = @getSource()
    lastLine = _.last(source.split('\n'))
    indent = lastLine.match(/^\s*/)[0]
    if /\S/.test(lastLine)
      source += '\n' + indent
    source += blockSource + '\n' + indent
    @updateACEText source
    @aceToBlockly()
    if @options.level.get('product') is 'codecombat-junior'
      @recompile()
    null

  onBlocklyEvent: (e) =>
    # console.log "--------- Got Blockly Event #{e.type} ------------", e
    if e.type is Blockly.Events.FINISHED_LOADING
      @awaitingBlocklySerialization = false

    return unless e.type in blocklyUtils.blocklyMutationEvents
    { blocklySource, blocklySourceRaw } = @blocklyToAce e

    return unless blocklySource and e.type in blocklyUtils.blocklyFinishedMutationEvents and blocklySource.trim().replace(/\n\s*\n/g, '\n') isnt @spell.source.trim().replace(/\n\s*\n/g, '\n')
    # Sometimes move event happens when blocks are moving around during a drag, but the drag isn't done. e.reason including 'drag' means it's done, 'connect' happens when clicked-to-insert.
    return if e.type is Blockly.Events.BLOCK_MOVE and not ('drag' in (e.reason or [])) and not ('connect' in (e.reason or []))

    if blocklySourceRaw isnt blocklySource
      # Blocks -> code processing introduced a significant change and should rewrite the blocks to match that change
      # Example: removing newlines so that blocks snap together
      @aceToBlockly(true)

    if @options.level.get('product') is 'codecombat-junior'
      # Immediate code execution on each significant block change that produces a program that differs by more than newlines
      @recompile()
    else
      @notifySpellChanged()
    return

  blocklyToAce: ->
    return {} if @awaitingBlocklySerialization
    return {} if @eventsSuppressed
    return {} unless @blockly
    { blocklyState, blocklySource, combined, blocklySourceRaw } = @getBlocklySource()
    @lastBlocklyState = blocklyState
    aceSource = @getSource()

    # For debugging, including Blockly JSON serialization
    #return if combined is aceSource
    #console.log 'B2A: Changing ace source from', aceSource, 'to', combined
    #@updateACEText combined

    # Don't update Ace if BLockly output code hasn't changed or only differs by Blockly removing newlines
    return { blocklySource, blocklySourceRaw } if blocklySource is aceSource
    return { blocklySource, blocklySourceRaw } if blocklySource.replace(/(?:[ \t]*\r?\n){2,}/g, '\n') is aceSource.replace(/(?:[ \t]*\r?\n){2,}/g, '\n')
    #console.log 'B2A: Changing ace source from', aceSource, 'to', blocklySource, 'with state', blocklyState
    @updateACEText blocklySource

    if PERSIST_BLOCK_STATE and not @session.fake
      storage.save "lastBlocklyState_#{@options.level.get('original')}_#{@session.id}", blocklyState

    return { blocklySource, blocklySourceRaw }

  aceToBlockly: (force) =>
    return if @eventsSuppressed and not force
    return unless @blockly
    { blocklyState, blocklySource, blocklySourceRaw } = @getBlocklySource()
    unless @codeToBlocksPrepData
      try
        @codeToBlocksPrepData = prepareBlockIntelligence { toolbox: @blocklyToolboxJS, blocklyState, workspace: @blockly }
      catch err
        console.error 'Error preparing Blockly code to blocks conversion:', err
        return
    aceSource = @ace.getValue()
    if @options.level.get('product') is 'codecombat-junior'
      # Remove extra newlines so that Junior blocks stay together
      aceSource = aceSource.replace(/(?:[ \t]*\r?\n){2,}/g, '\n')
    # Don't update Blockly if code hasn't changed
    return if aceSource and aceSource is blocklySourceRaw
    try
      newBlocklyState = codeToBlocks { code: aceSource, originalCode: @spell.originalSource, codeLanguage: @spell.language, toolbox: @blocklyToolbox, blocklyState, prepData: @codeToBlocksPrepData }
    catch err
      console.log "Couldn't parse code to get new blockly state:", err, '\nCode:', aceSource
      return

    if blocklyUtils.isEqualBlocklyState newBlocklyState, @lastBlocklyState
      #console.log 'new blockly state is the same as it ever was, so not updating blockly; new', newBlocklyState, 'old', @lastBlocklyState
      return
    else
      #console.log 'new blockly state', newBlocklyState, 'is different from last blockly state', @lastBlocklyState
    #console.log 'A2B: Changing blockly source from', blocklySource, 'to', aceSource
    @eventsSuppressed = true
    @awaitingBlocklySerialization = true
    #console.log 'would set to', newBlocklyState
    blocklyUtils.loadBlocklyState { blocklyState: newBlocklyState, blockly: @blockly }
    #@resizeBlockly()  # Needed?
    @eventsSuppressed = false
    @lastBlocklyState = newBlocklyState

  lockDefaultCode: (force=false) ->
    # TODO: Lock default indent for an empty line?
    lockDefaultCode = @options.level.get('lockDefaultCode') or false
    if not lockDefaultCode or (_.isNumber(lockDefaultCode) and lockDefaultCode < me.level())
      return
    return unless @spell.source is @spell.originalSource or force
    aceConfig = me.get('aceConfig') ? {}
    return if aceConfig.keyBindings and aceConfig.keyBindings isnt 'default'  # Don't lock in vim/emacs mode

    console.info 'Locking down default code.'

    intersects = =>
      return true for range in @readOnlyRanges when @ace.getSelectionRange().intersects(range)
      false

    intersectsLeft = =>
      leftRange = @ace.getSelectionRange().clone()
      if leftRange.start.column > 0
        leftRange.setStart leftRange.start.row, leftRange.start.column - 1
      else if leftRange.start.row > 0
        leftRange.setStart leftRange.start.row - 1, 0
      return true for range in @readOnlyRanges when leftRange.intersects(range)
      false

    intersectsRight = =>
      rightRange = @ace.getSelectionRange().clone()
      if rightRange.end.column < @aceDoc.getLine(rightRange.end.row).length
        rightRange.setEnd rightRange.end.row, rightRange.end.column + 1
      else if rightRange.start.row < @aceDoc.getLength() - 1
        rightRange.setEnd rightRange.end.row + 1, 0
      return true for range in @readOnlyRanges when rightRange.intersects(range)
      false

    # TODO: Performance: Consider removing, may be dead code.
    pulseLockedCode = ->
      $('.locked-code').finish().addClass('pulsating').effect('shake', times: 1, distance: 2, direction: 'down').removeClass('pulsating')

    # TODO: Performance: Consider removing, may be dead code.
    preventReadonly = (next) ->
      if intersects()
        pulseLockedCode()
        return true
      next?()

    interceptCommand = (obj, method, wrapper) ->
      orig = obj[method]
      obj[method] = ->
        args = Array.prototype.slice.call arguments
        wrapper => orig.apply obj, args
      obj[method]

    finishRange = (row, startRow, startColumn) =>
      range = new Range startRow, startColumn, row, @aceSession.getLine(row).length - 1
      range.start = @aceDoc.createAnchor range.start
      range.end = @aceDoc.createAnchor range.end
      range.end.$insertRight = true
      @readOnlyRanges.push range

    # Remove previous locked code highlighting
    if @lockedCodeMarkerIDs?
      @aceSession.removeMarker marker for marker in @lockedCodeMarkerIDs
    @lockedCodeMarkerIDs = []

    # Create locked default code text ranges
    @readOnlyRanges = []
    if @spell.language in ['python', 'coffeescript']
      # Lock contiguous section of default code
      # Only works for languages without closing delimeters on blocks currently
      lines = @aceDoc.getAllLines()
      for line, row in lines when not /^\s*$/.test(line)
        lastRow = row
      if lastRow?
        @readOnlyRanges.push new Range 0, 0, lastRow, lines[lastRow].length - 1

    # TODO: Highlighting does not work for multiple ranges
    # TODO: Everything looks correct except the actual result.
    # TODO: https://github.com/codecombat/codecombat/issues/1852
    # else
    #   # Create a read-only range for each chunk of text not separated by an empty line
    #   startRow = startColumn = null
    #   for row in [0...@aceSession.getLength()]
    #     unless /^\s*$/.test @aceSession.getLine(row)
    #       unless startRow? and startColumn?
    #         startRow = row
    #         startColumn = 0
    #     else
    #       if startRow? and startColumn?
    #         finishRange row - 1, startRow, startColumn
    #         startRow = startColumn = null
    #   if startRow? and startColumn?
    #     finishRange @aceSession.getLength() - 1, startRow, startColumn

    # Highlight locked ranges
    for range in @readOnlyRanges
      @lockedCodeMarkerIDs.push @aceSession.addMarker range, 'locked-code', 'fullLine'

    # Override write operations that intersect with default code
    interceptCommand @ace, 'onPaste', preventReadonly
    interceptCommand @ace, 'onCut', preventReadonly
    # TODO: can we use interceptCommand for this too?  'exec' and 'onExec' did not work.
    @ace.commands.on 'exec', (e) =>
      e.stopPropagation()
      e.preventDefault()
      if (e.command.name is 'insertstring' and intersects()) or
         (e.command.name in ['Backspace', 'throttle-backspaces'] and intersectsLeft()) or
         (e.command.name is 'del' and intersectsRight())
        @autocomplete?.off?()
        pulseLockedCode() # TODO: Performance: Consider removing, may be dead code.
        return false
      else if e.command.name in ['enter-skip-delimiters', 'Enter', 'Return']
        if intersects()
          e.editor.navigateDown 1
          e.editor.navigateLineStart()
          return false
        else if e.command.name in ['Enter', 'Return'] and not e.editor?.completer?.popup?.isOpen
          @autocomplete?.on?()
          return e.editor.execCommand 'enter-skip-delimiters'
      @autocomplete?.on?()
      e.command.exec e.editor, e.args or {}

  initAutocomplete: (@autocompleteOn) ->
    # TODO: Turn on more autocompletion based on level sophistication
    # TODO: E.g. using the language default snippets yields a bunch of crazy non-beginner suggestions
    # TODO: Options logic shouldn't exist both here and in updateAutocomplete()
    return if @spell.language is 'html'
    popupFontSizePx = @options.level.get('autocompleteFontSizePx') ? 16
    @autocomplete = new Autocomplete @ace,
      basic: false
      liveCompletion: false
      snippetsLangDefaults: false
      completers:
        keywords: false
        snippets: @autocompleteOn
      autoLineEndings:
        javascript: if @options.level.get('product') is 'codecombat-junior' then '' else ';'
        java: ';'
        c_cpp: ';' # Match ace editor language mode
      popupFontSizePx: popupFontSizePx
      popupLineHeightPx: 1.5 * popupFontSizePx
      popupWidthPx: 380

  updateAutocomplete: (@autocompleteOn) ->
    @autocomplete?.set 'snippets', @autocompleteOn

  reallyAddUserSnippets: (source, lang, session) ->
    return unless @autocomplete and @autocompleteOn
    return if @options.level.get('product') is 'codecombat-junior'
    return if me.level() < 15  # Don't do this until later, to avoid custom user snippets before they are useful
    newIdentifiers = aceUtils.parseUserSnippets(source, lang, session)
    # console.log 'debug newIdentifiers: ', newIdentifiers
    @autocomplete?.addCustomSnippets Object.values(newIdentifiers), @editorLang if @editorLang?

  addAutocompleteSnippets: (e) ->
    # Snippet entry format:
    # content: code inserted into document
    # meta: displayed right-justfied in popup
    # name: displayed left-justified in popup, and what's being matched
    # tabTrigger: fallback for name field
    return unless @autocomplete and @autocompleteOn
    @autocomplete.addCodeCombatSnippets @options.level, @, e

  translateFindNearest: ->
    # If they have advanced glasses but are playing a level which assumes earlier glasses, we'll adjust the sample code to use the more advanced APIs instead.
    oldSource = @getSource()
    newSource = oldSource.replace /(self:|self.|this.|@)findNearestEnemy\(\)/g, "$1findNearest($1findEnemies())"
    newSource = newSource.replace /(self:|self.|this.|@)findNearestItem\(\)/g, "$1findNearest($1findItems())"
    return if oldSource is newSource
    @spell.originalSource = newSource
    @updateACEText newSource
    _.delay (=> @recompile?()), 1000

  onAllLoaded: =>
    @fetchToken(@spell.source, @spell.language).then (token) =>
      @spell.transpile token
      @spell.loaded = true
      Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
      @eventsSuppressed = false  # Now that the initial change is in, we can start running any changed code
      @createToolbarView()
      @updateHTML create: true if @options.level.isType('web-dev')

  createDebugView: ->
    return if @options.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder')  # We'll turn this on later, maybe, but not yet.
    @debugView = new SpellDebugView ace: @ace, thang: @thang, spell:@spell
    @$el.append @debugView.render().$el.hide()

  createTranslationView: ->
    @translationView = new SpellTranslationView { @ace, @supermodel }
    @$el.append @translationView.render().$el.hide()

  createToolbarView: ->
    @toolbarView = new SpellToolbarView ace: @ace
    @$el.append @toolbarView.render().$el

  onMouseOut: (e) ->
    @debugView?.onMouseOut e

  onContactButtonPressed: (e) ->
    @saveSpade()

  getSource: ->
    @ace.getValue()

  setThang: (thang) ->
    @focus()
    @lastScreenLineCount = null
    @updateLines()
    return if thang.id is @thang?.id
    @thang = thang
    @spellThang = @spell.thang
    @createDebugView() unless @debugView
    @debugView?.thang = @thang
    @createTranslationView() unless @translationView
    @toolbarView?.toggleFlow false
    @updateAether false, false
    # @addAutocompleteSnippets()
    @highlightCurrentLine()

  cast: (preload=false, realTime=false, justBegin=false, cinematic=false) ->
    Backbone.Mediator.publish 'tome:cast-spell', { @spell, @thang, preload, realTime, justBegin, cinematic }

  notifySpellChanged: =>
    return if @destroyed
    Backbone.Mediator.publish 'tome:spell-changed', spell: @spell

  notifyEditingEnded: =>
    return if @destroyed
    Backbone.Mediator.publish 'tome:editing-ended', {}

  notifyEditingBegan: =>
    return if @destroyed
    Backbone.Mediator.publish 'tome:editing-began', {}

  updateSolutionLines: (ace, aceCls, areaId) =>
    screenLineCount = ace.getSession().getScreenLength()
    # wrap the updateAceLine to avoid throttle mess up different params(aceCls)
    @updateAceLines(screenLineCount, ace, aceCls, areaId)
    ace.resize(true)

  updateAceLines: (screenLineCount, ace=@ace, aceCls='.ace', areaId='#code-area') =>
    # Figure out how many lines we should set ace to and update it.
    # Also update spell palette size and position, if it is shown.
    isCinematic = $('#level-view').hasClass('cinematic')
    hasBlocks = @blocklyActive
    tomePosition = if $('#tome-view').offset()?.top > 100 then 'bottom' else 'right'
    lineHeight = ace.renderer.lineHeight or 20
    spellPaletteView = $('#tome-view #spell-palette-view')
    spellTopBarHeight = $('#spell-top-bar-view').outerHeight()
    controlBarHeight = $('#control-bar-view').outerHeight()
    if spellTopBarHeight is 0 and parseInt($('#control-bar-view').css('left'), 10) > 0
      # Spell top bar isn't there, but we've stacked level control bar above editor instead
      spellTopBarHeight = controlBarHeight
    spellPaletteHeight = switch
      when hasBlocks then 0
      when aceCls == '.ace' then spellPaletteView.find('.properties-this').outerHeight()
      else 0
    windowHeight = $(window).innerHeight()
    topOffset = $(aceCls).offset()?.top or 0
    spellPaletteAllowedMinHeight = Math.min spellPaletteHeight, 0.4 * (windowHeight  - topOffset)
    spellPaletteAllowedMinHeight = Math.max 75, spellPaletteAllowedMinHeight if spellPaletteHeight > 0  # At least room for four props
    runButtonHeight = if aceCls == '.ace' then 75 else 0
    gameHeight = $('#game-area').innerHeight()
    heightScale = if aceCls == '.ace' then 1 else 0.5

    # If the spell palette is too tall, we'll need to shrink it.
    maxHeightOffset = 0
    minHeightOffset = if hasBlocks or isCinematic then 0 else 100
    maxHeight = windowHeight - topOffset - spellPaletteAllowedMinHeight - maxHeightOffset - runButtonHeight
    minHeight = Math.min maxHeight * heightScale, Math.min(gameHeight, windowHeight) - spellPaletteHeight - minHeightOffset
    minHeight = maxHeight if hasBlocks or isCinematic

    spellPaletteShown = spellPaletteHeight > 0
    minLinesBuffer = if spellPaletteShown then 0 else 2
    minLinesBuffer = 0 if hasBlocks or isCinematic
    hardMinLines = if tomePosition is 'bottom' then 5 else 8
    linesAtMinHeight = Math.max(hardMinLines, Math.floor(minHeight / lineHeight - minLinesBuffer))
    linesAtMaxHeight = Math.floor(maxHeight / lineHeight)
    lines = Math.max linesAtMinHeight, Math.min(screenLineCount + 2, linesAtMaxHeight), hardMinLines
    lines = 8 if _.isNaN lines

    if aceCls is '.ace'
      ace.setOptions minLines: lines, maxLines: lines
    else
      solutionLines = Math.min(lines, screenLineCount + 2)
      ace.setOptions minLines: solutionLines, maxLines: solutionLines

    return unless spellPaletteShown and aceCls is '.ace'
    # Move spell palette up, overlapping us a bit
    spellTopMargin = parseInt(@$el.css('marginTop'), 10)
    spellTopPadding = parseInt(@$el.css('paddingTop'), 10)
    spellBottomPadding = parseInt(@$el.css('paddingBottom'), 10)
    verticalOverlap = 10
    newTop = spellTopMargin + spellTopPadding + lineHeight * lines + spellBottomPadding - verticalOverlap
    spellPaletteAllowedMaxHeight = Math.min(spellPaletteHeight, Math.max(spellPaletteAllowedMinHeight, windowHeight - newTop - spellTopBarHeight))
    spellPaletteView.css top: newTop
    spellPaletteView.find('.properties-scroll-container').css height: Math.min(spellPaletteHeight, windowHeight - newTop - spellTopBarHeight)

    codeAreaBottom = if spellPaletteHeight then spellPaletteAllowedMaxHeight else 0
    $(areaId).css('bottom', codeAreaBottom)
    # console.log { lineHeight, spellTopBarHeight, controlBarHeight, spellPaletteHeight, windowHeight, topOffset, spellPaletteAllowedMinHeight, spellPaletteAllowedMaxHeight, gameHeight, heightScale, maxHeightOffset, minHeightOffset, minHeight, maxHeight, spellPaletteShown, minLinesBuffer, linesAtMinHeight, linesAtMaxHeight, lines, aceCls, areaId, codeAreaBottom, spellTopMargin, spellTopPadding, spellBottomPadding, verticalOverlap, newTop }

  updateLines: =>
    # Make sure there are always blank lines for the player to type on, and that the editor resizes to the height of the lines.
    return if @destroyed
    lineCount = @aceDoc.getLength()
    lastLine = @aceDoc.$lines[lineCount - 1]
    if /\S/.test lastLine
      cursorPosition = @ace.getCursorPosition()
      wasAtEnd = cursorPosition.row is lineCount - 1 and cursorPosition.column is lastLine.length
      @aceDoc.insertNewLine row: lineCount, column: 0  #lastLine.length
      @ace.navigateLeft(1) if wasAtEnd
      ++lineCount
      # Force the popup back
      @ace?.completer?.showPopup(@ace)

    screenLineCount = @aceSession.getScreenLength()
    if screenLineCount isnt @lastScreenLineCount
      @lastScreenLineCount = screenLineCount
      @updateAceLines(screenLineCount)

    if @firstEntryToScrollLine? and @ace?.renderer?.$cursorLayer?.config
      @ace.scrollToLine @firstEntryToScrollLine, true, true
      @firstEntryToScrollLine = undefined

    # Determine how wide the editor can/should be, in terms of max code line length in current code and solution
    isJunior = @options.level.get('product', true) is 'codecombat-junior'
    isWebDev = @options.level.isType('web-dev')
    lineLengthWrappingComments = (line) =>
      if @singleLineCommentOnlyRegex().test(line)
        # 85% of CodeCombat solution lines are under 60 characters; longer ones are mostly comments, Java/C++, or advanced
        return Math.min(line.length, 60)
      return line.length
    lineLengthWithoutComments = (line) =>
      if @singleLineCommentOnlyRegex().test(line)
        return 0
      return line.length
    currentCodeLineLengthFunction = if @blocklyActive then lineLengthWithoutComments else lineLengthWrappingComments
    longestLineChars = Math.max @aceDoc.getAllLines().map(currentCodeLineLengthFunction)...
    solution = store.getters['game/getSolutionSrc'](@spell.language)
    if solution
      longestLineChars = Math.max longestLineChars, solution.split('\n').map(lineLengthWithoutComments)...
    wrapperIndentationChars = { cpp: 4, java: 8 }[@spell.language] or 0  # main, class + main
    if longestLineChars < 8
      # No (complete) lines of code yet, so let's guess at how long a line will be
      # A long Junior line might be like this (28 characters):
      # for (let i = 0; i < 5; ++i) {
      # A long CodeCombat line might be like this (39 characters):
      #     var enemy = hero.findNearestEnemy();
      longestLineChars = (if isJunior then 30 else 40) + wrapperIndentationChars
    longestLineChars = Math.max(longestLineChars, 40) if isWebDev
    hardMinCodeChars = switch
      when isJunior then 16 + wrapperIndentationChars
      when @blocklyActive then 18 + wrapperIndentationChars
      else 29  # Enough for two spell palette columns
    hardMaxCodeChars = (if isJunior is 'codecombat-junior' then 40 else 80) + wrapperIndentationChars
    desiredCodeChars = Math.min(hardMaxCodeChars, Math.max(hardMinCodeChars, longestLineChars + 1))
    previousDesiredCodeChars = @codeChars?.desired
    @codeChars = min: hardMinCodeChars, max: hardMaxCodeChars, desired: desiredCodeChars
    resizing = false
    if previousDesiredCodeChars and desiredCodeChars isnt previousDesiredCodeChars
      if not @resizeWindowDebounced
        resizeWindow = => $(window).trigger('resize') unless @destroyed
        @resizeWindowDebounced = _.debounce resizeWindow, 600
      resizing = true
      @resizeWindowDebounced()

    return unless @blocklyActive
    # Determine how wide the workspace and toolbox can/should be
    currentScale = @blockly.getScale()
    desiredToolboxWidth = @$el.find('.blocklyFlyout').width() / currentScale
    desiredWorkspaceWidth = Math.max desiredToolboxWidth + 30, @blockly.getBlocksBoundingBox().getWidth() + 40

    # TODO: DRY from PlayLevelView
    tomePosition = if $('#tome-view').offset()?.top > 100 then 'bottom' else 'right'
    availableWidth = $(window).width()
    availableWidth -= ($(window).height() - 50) * 924 / 589 if tomePosition is 'right'
    availableWidth -= desiredCodeChars * 410.47 / 57 + 30 + 41 + 30 if @options.codeFormat is 'blocks-and-code'
    availableWidth = Math.max availableWidth, $(window).width() * (if @options.codeFormat is 'blocks-and-code' then 0.2 else 0.3)
    # Split the difference between current desires and the min/max with zoom, as low as 0.5 or as high as 1.5
    if desiredToolboxWidth + desiredWorkspaceWidth > availableWidth
      desiredScale = Math.max 0.5, Math.min 1, availableWidth / (desiredToolboxWidth + desiredWorkspaceWidth)
    else if desiredToolboxWidth + desiredWorkspaceWidth < 0.8 * availableWidth
      desiredScale = Math.max 1, Math.min 1.5, 0.8 * availableWidth / (desiredToolboxWidth + desiredWorkspaceWidth)
    else
      desiredScale = currentScale
    desiredScale = (desiredScale + currentScale) / 2
    if Math.abs(desiredScale - currentScale) > 0.02
      @blockly.setScale desiredScale
    else
      desiredScale = currentScale
    desiredToolboxWidth *= desiredScale
    desiredWorkspaceWidth *= desiredScale

    minToolboxWidth = 144
    maxToolboxWidth = if isJunior then 221 else 346
    @toolboxWidth = min: minToolboxWidth, max: maxToolboxWidth, desired: Math.min(maxToolboxWidth, Math.max(minToolboxWidth, desiredToolboxWidth))
    minWorkspaceWidth = 128
    maxWorkspaceWidth = if isJunior then 512 else 665
    @workspaceWidth = min: minWorkspaceWidth, max: maxWorkspaceWidth, desired: Math.min(maxWorkspaceWidth, Math.max(minWorkspaceWidth, desiredWorkspaceWidth))
    previousDesiredWorkspaceWidth = @workspaceWidth?.desired
    if previousDesiredWorkspaceWidth and desiredWorkspaceWidth isnt previousDesiredWorkspaceWidth and not resizing
      if not @resizeWindowDebounced
        resizeWindow = => $(window).trigger('resize') unless @destroyed
        @resizeWindowDebounced = _.debounce resizeWindow, 600
      resizing = true
      @resizeWindowDebounced()
    return

  hideProblemAlert: ->
    return if @destroyed
    Backbone.Mediator.publish 'tome:hide-problem-alert', {}

  saveSpade: =>
    return if @destroyed or not @spade
    @spade.createUIEvent "saving-spade"
    spadeEvents = @spade.compile()
    condensedEvents = @spade.condense(spadeEvents)
    # Uncomment the below lines for a debug panel to display inside the level
    # uncondensedEvents = @spade.expand(condensedEvents)
    # @spade.debugPlay(uncondensedEvents)

    return unless condensedEvents.length
    compressedEvents = LZString.compressToUTF16(JSON.stringify(condensedEvents))
    codeLog = new CodeLog({
      sessionID: @options.session.id
      level:
        original: @options.level.get 'original'
        majorVersion: (@options.level.get 'version').major
      levelSlug: @options.level.get 'slug'
      userID: @options.session.get 'creator'
      log: compressedEvents
    })

    codeLog.save()

  onShowVictory: (e) ->
    if @spade?
      @spade.createUIEvent "victory-shown"
    if @saveSpadeTimeout?
      window.clearTimeout @saveSpadeTimeout
      @saveSpadeTimeout = null
      if @options.level.get('releasePhase') is 'beta'
        @saveSpade()
      else if Math.random() < 0.05 and _.find(utils.freeAccessLevels, access: 'short', slug: @options.level.get('slug'))
        @saveSpade()

  onManualCast: (e) ->
    if @spade?
      @spade.createUIEvent "code-run"
    cast = @$el.parent().length
    @recompile cast, e.realTime, false
    @focus() if cast
    if @options.level.isType('web-dev')
      @sourceAtLastCast = @getSource()
      @ace.setStyle 'spell-cast'
      @updateHTML create: true

  reloadCode: (cast=true) ->
    @spell.reloadCode() if cast
    @thang = @spell.thang.thang
    @updateACEText @spell.originalSource
    @aceToBlockly()
    @lockDefaultCode true
    @recompile cast
    Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
    @hasSetInitialCursor = false
    @highlightCurrentLine()
    @updateLines()
    if @spade?
      @spade.createUIEvent "code-reset"

  recompile: (cast=true, realTime=false, cinematic=false) ->
    @fetchTokenForSource().then (source) =>
      readableSource = Aether.getTokenSource(source)
      hasChanged = @spell.source isnt readableSource
      if hasChanged
        @spell.transpile source
        @updateAether true, false
      if cast  #and (hasChanged or realTime)  # just always cast now
        @cast(false, realTime, false, cinematic)
      if hasChanged
        @notifySpellChanged()

  updateACEText: (source) ->
    @eventsSuppressed = true
    @ace.setValue source
    @ace.clearSelection()
    @aceSession.setUndoManager(new UndoManager())
    @eventsSuppressed = false
    try
      @ace.resize true  # hack: @ace may not have updated its text properly, so we force it to refresh
    catch error
      console.warn 'Error resizing ACE after an update:', error

  createOnCodeChangeHandlers: ->
    @aceDoc.removeListener 'change', @onCodeChangeMetaHandler if @onCodeChangeMetaHandler
    onSignificantChange = []
    onAnyChange = [
      _.debounce @updateAether, if @options.level.isType('game-dev') then 10 else 500
      _.debounce @notifyEditingEnded, 1000
      _.throttle @notifyEditingBegan, 250
      _.throttle @notifySpellChanged, 300
      _.throttle @updateLines, 500
      _.throttle @hideProblemAlert, 500
      _.throttle @aceToBlockly, 500
    ]
    onSignificantChange.push _.debounce @checkRequiredCode, 750 if @options.level.get 'requiredCode'
    onSignificantChange.push _.debounce @checkSuspectCode, 750 if @options.level.get 'suspectCode'
    onAnyChange.push _.throttle @updateHTML, 10 if @options.level.isType('web-dev')

    @onCodeChangeMetaHandler = =>
      return if @eventsSuppressed
      #@playSound 'code-change', volume: 0.5  # Currently not using this sound.
      if @spellThang
        @spell.hasChangedSignificantly @getSource(), @spellThang.aether.raw, (hasChanged) =>
          if not @spellThang or hasChanged
            callback() for callback in onSignificantChange  # Do these first
          callback() for callback in onAnyChange  # Then these
    @aceDoc.on 'change', @onCodeChangeMetaHandler

    if @blockly
      @blockly.addChangeListener @onBlocklyEvent

  onCursorActivity: =>  # Used to refresh autocast delay; doesn't do anything at the moment.

  updateHTML: (options={}) =>
    # TODO: Merge with onSpellChanged
    # NOTE: Consider what goes in onManualCast only
    if @spell.hasChanged(@spell.getSource(), @sourceAtLastCast)
      @ace.unsetStyle 'spell-cast' # NOTE: Doesn't do anything for web-dev as of this writing, including for consistency
    @clearWebDevErrors()
    Backbone.Mediator.publish 'tome:html-updated', html: @spell.constructHTML(@getSource()), create: Boolean(options.create)

  # Design for a simpler system?
  # * Keep Aether linting, debounced, on any significant change
  # - All problems just vanish when you make any change to the code
  # * You wouldn't accept any Aether updates/runtime information/errors unless its code was current when you got it
  # * Store the last run Aether in each spellThang and use it whenever its code actually is current.
  #   Use dynamic markers for problem ranges and keep annotations/alerts in when insignificant
  #   changes happen, but always treat any change in the (trimmed) number of lines as a significant change.
  # - All problems have a master representation as a Problem, and we can easily generate all Problems from
  #   any Aether instance. Then when we switch contexts in any way, we clear, recreate, and reapply the Problems.
  # * Problem alerts have their own templated ProblemAlertViews.
  # * We'll only show the first problem alert, and it will always be at the bottom.
  #   Annotations and problem ranges can show all, I guess.
  # * The editor will reserve space for one annotation as a codeless area.
  # - Problem alerts and ranges will only show on fully cast worlds. Annotations will show continually.

  fetchToken: (source, language) =>
    if language not in ['java', 'cpp']
      return Promise.resolve(source)
    else if source of @loadedToken
      return Promise.resolve(@loadedToken[source])

    headers =  { 'Accept': 'application/json', 'Content-Type': 'application/json' }
    m = document.cookie.match(/JWT=([a-zA-Z0-9.]+)/)
    service = window?.localStorage?.kodeKeeperService or "https://asm14w94nk.execute-api.us-east-1.amazonaws.com/service/parse-code-kodekeeper"
    fetch service, {method: 'POST', mode:'cors', headers:headers, body:JSON.stringify({code: source, language: language})}
    .then (x) => x.json()
    .then (x) =>
      @loadedToken = {} # only cache 1 source
      @loadedToken[source] = x.token;
      return x.token

  fetchTokenForSource: () =>
    source = @ace.getValue()
    @fetchToken(source, @spell.language)

  updateAether: (force=false, fromCodeChange=true) =>
    # Depending on whether we have any code changes, significant code changes, or have switched
    # to a new spellThang, we may want to refresh our Aether display.
    return unless aether = @spellThang?.aether
    @fetchTokenForSource().then (source) =>
      readableSource = Aether.getTokenSource(source)
      @spell.hasChangedSignificantly source, aether.raw, (hasChanged) =>
        codeHasChangedSignificantly = force or hasChanged
        needsUpdate = codeHasChangedSignificantly or @spellThang isnt @lastUpdatedAetherSpellThang
        return if not needsUpdate and aether is @displayedAether
        castAether = @spellThang.castAether
        codeIsAsCast = castAether and readableSource is castAether.raw
        aether = castAether if codeIsAsCast
        return if not needsUpdate and aether is @displayedAether

        # Now that that's figured out, perform the update.
        # The web worker Aether won't track state, so don't have to worry about updating it
        finishUpdatingAether = (aether) =>
          @clearAetherDisplay() # In case problems were added since last clearing
          @displayAether aether, codeIsAsCast
          @lastUpdatedAetherSpellThang = @spellThang
          @guessWhetherFinished aether if fromCodeChange

        @clearAetherDisplay()
        if codeHasChangedSignificantly and not codeIsAsCast
          if @worker
            workerMessage =
              function: 'transpile'
              spellKey: @spell.spellKey
              source: source

            @worker.addEventListener 'message', (e) =>
              workerData = JSON.parse e.data
              if workerData.function is 'transpile' and workerData.spellKey is @spell.spellKey
                @worker.removeEventListener 'message', arguments.callee, false
                aether.problems = workerData.problems
                aether.raw = readableSource
                finishUpdatingAether(aether)
            @worker.postMessage JSON.stringify(workerMessage)
          else
            aether.transpile source
            finishUpdatingAether(aether)
        else
          finishUpdatingAether(aether)

  # Each problem-generating piece (aether, web-dev, ace html worker) clears its own problems/annotations
  clearAetherDisplay: ->
    @clearProblemsCreatedBy 'aether'
    @highlightCurrentLine {}  # This'll remove all highlights

  clearWebDevErrors: ->
    @clearProblemsCreatedBy 'web-dev-iframe'

  clearProblemsCreatedBy: (createdBy) ->
    if @aceSession?
      nonAetherAnnotations = _.reject @aceSession.getAnnotations(), (annotation) -> annotation.createdBy is createdBy
      @reallySetAnnotations nonAetherAnnotations

    problemsToClear = _.filter @problems, (p) -> p.createdBy is createdBy
    problemsToClear.forEach (problem) -> problem.destroy()
    @problems = _.difference @problems, problemsToClear
    Backbone.Mediator.publish 'tome:problems-updated', spell: @spell, problems: @problems, isCast: false

  convertAetherProblems: (aether, aetherProblems, isCast) ->
    # TODO: Functional-ify
    _.unique(aetherProblems, (p) -> p.userInfo?.key).map (aetherProblem) =>
      new Problem { aether, aetherProblem, @ace, isCast, levelID: @options.levelID }

  displayAether: (aether, isCast=false) ->
    @displayedAether = aether
    return unless @ace?
    isCast = isCast or not _.isEmpty(aether.metrics) or _.some aether.getAllProblems(), {type: 'runtime'}
    annotations = @aceSession.getAnnotations()

    newProblems = @convertAetherProblems(aether, aether.getAllProblems(), isCast)
    annotations.push problem.annotation for problem in newProblems when problem.annotation
    if isCast
      @displayProblemBanner(newProblems[0]) if newProblems[0]
      @saveUserCodeProblem(aether, problem.aetherProblem) for problem in newProblems
    @problems = @problems.concat(newProblems)

    @aceSession.setAnnotations annotations
    @highlightCurrentLine aether.flow unless _.isEmpty aether.flow
    #console.log '  and we could do the metrics', aether.metrics unless _.isEmpty aether.metrics
    #console.log '  and we could do the style', aether.style unless _.isEmpty aether.style
    #console.log '  and we could do the visualization', aether.visualization unless _.isEmpty aether.visualization
    Backbone.Mediator.publish 'tome:problems-updated', spell: @spell, problems: @problems, isCast: isCast
    @ace.resize()

  # Tell ProblemAlertView to display this problem (only)
  displayProblemBanner: (problem) ->
    if @spade?
      @spade.createUIEvent "code-error"
    lineOffsetPx = 0
    if problem.row?
      for i in [0...problem.row]
        lineOffsetPx += @aceSession.getRowLength(i) * @ace.renderer.lineHeight
      lineOffsetPx -= @ace.session.getScrollTop()
    if problem.level not in ['info', 'warning']
      Backbone.Mediator.publish 'playback:stop-cinematic-playback', {}
      # TODO: find a way to also show problem alert if it's compile-time, and/or not enter cinematic mode at all
    Backbone.Mediator.publish 'tome:show-problem-alert', problem: problem, lineOffsetPx: Math.max lineOffsetPx, 0

  # Gets the number of lines before the start of <script> content in the usercode
  # Because Errors report their line number relative to the <script> tag
  linesBeforeScript: (html) ->
    # TODO: refactor, make it work with multiple scripts. What to do when error is in level-creator's code?
    _.size(html.split('<script>')[0].match(/\n/g))

  addAnnotation: (annotation) ->
    annotations = @aceSession.getAnnotations()
    annotations.push annotation
    @reallySetAnnotations annotations

  # Handle errors from the web-dev iframe asynchronously
  onWebDevError: (error) ->
    # TODO: Refactor this and the Aether problem flow to share as much as possible.
    # TODO: Handle when the error is in our code, not theirs
    # Compensate for line number being relative to <script> tag
    offsetError = _.merge {}, error, { line: error.line + @linesBeforeScript(@getSource()) }
    userCodeHasChangedSinceLastCast = @spell.hasChanged(@spell.getSource(), @sourceAtLastCast)
    problem = new Problem({ error: offsetError, @ace, levelID: @options.levelID, userCodeHasChangedSinceLastCast })
    # Ignore the Problem if we already know about it
    if _.any(@problems, (preexistingProblem) -> problem.isEqual(preexistingProblem))
      problem.destroy()
    else # Ok, the problem is worth keeping
      @problems.push problem
      @displayProblemBanner(problem)

      # @saveUserCodeProblem(aether, aetherProblem) # TODO: Enable saving of web-dev user code problems
      @addAnnotation(problem.annotation) if problem.annotation
      Backbone.Mediator.publish 'tome:problems-updated', spell: @spell, problems: @problems, isCast: false

  onProblemsUpdated: ({ spell, problems, isCast }) ->
    # This just handles some ace styles for now; other things handle @problems changes elsewhere
    if @ace?
      @ace[if problems.length then 'setStyle' else 'unsetStyle'] 'user-code-problem'
      @ace[if isCast then 'setStyle' else 'unsetStyle'] 'spell-cast' # Does this still do anything?

  saveUserCodeProblem: (aether, aetherProblem) ->
    # Skip duplicate problems
    hashValue = aether.raw + aetherProblem.message
    return if hashValue of @savedProblems
    @savedProblems[hashValue] = true
    sampleRate = Math.max(1, (me.level()-2) * 2) * 0.01 # Reduce number of errors reported on earlier levels
    return unless Math.random() < sampleRate
    # Save new problem
    ucp = @createUserCodeProblem aether, aetherProblem
    ucp.save()
    null

  createUserCodeProblem: (aether, aetherProblem) ->
    ucp = new UserCodeProblem()
    ucp.set 'code', aether.raw
    if aetherProblem.range
      rawLines = aether.raw.split '\n'
      errorLines = rawLines.slice aetherProblem.range[0].row, aetherProblem.range[1].row + 1
      ucp.set 'codeSnippet', errorLines.join '\n'
    ucp.set 'errHint', aetherProblem.hint if aetherProblem.hint
    ucp.set 'errId', aetherProblem.id if aetherProblem.id
    ucp.set 'errCode', aetherProblem.errorCode if aetherProblem.errorCode
    ucp.set 'errLevel', aetherProblem.level if aetherProblem.level
    if aetherProblem.message
      ucp.set 'errMessage', aetherProblem.message
      # Save error message without 'Line N: ' prefix
      messageNoLineInfo = aetherProblem.message
      if lineInfoMatch = messageNoLineInfo.match /^Line [0-9]+\: /
        messageNoLineInfo = messageNoLineInfo.slice(lineInfoMatch[0].length)
      ucp.set 'errMessageNoLineInfo', messageNoLineInfo
    ucp.set 'errRange', aetherProblem.range if aetherProblem.range
    ucp.set 'errType', aetherProblem.type if aetherProblem.type
    ucp.set 'language', aether.language.id if aether.language?.id
    ucp.set 'levelID', @options.levelID if @options.levelID
    ucp

  # Autocast (preload the world in the background):
  # Goes immediately if the code is a) changed and b) complete/valid and c) the cursor is at beginning or end of a line
  # We originally thought it would:
  # - Go after specified delay if a) and b) but not c)
  # - Go only when manually cast or deselecting a Thang when there are errors
  # But the error message display was delayed, so now trying:
  # - Go after specified delay if a) and not b) or c)
  guessWhetherFinished: (aether) ->
    valid = not aether.getAllProblems().length
    return true if @blocklyActive
    return unless valid
    cursorPosition = @ace.getCursorPosition()
    currentLine = _.string.rtrim(@aceDoc.$lines[cursorPosition.row].replace(@singleLineCommentRegex(), ''))  # trim // unless inside "
    endOfLine = cursorPosition.column >= currentLine.length  # just typed a semicolon or brace, for example
    beginningOfLine = not currentLine.substr(0, cursorPosition.column).trim().length  # uncommenting code, for example
    incompleteThis = /^(s|se|sel|self|t|th|thi|this|g|ga|gam|game|h|he|her|hero)$/.test currentLine.trim()
    #console.log "finished=#{valid and (endOfLine or beginningOfLine) and not incompleteThis}", valid, endOfLine, beginningOfLine, incompleteThis, cursorPosition, currentLine.length, aether, new Date() - 0, currentLine
    if not incompleteThis and @options.level.isType('game-dev')
      # TODO: Improve gamedev autocast speed
      @fetchTokenForSource().then (token) =>
        # TODO: This is janky for those languages with a delay
        @spell.transpile token
        @cast(false, false, true)
    else if (endOfLine or beginningOfLine) and not incompleteThis
      @preload()

  singleLineCommentRegex: ->
    if @_singleLineCommentRegex
      @_singleLineCommentRegex.lastIndex = 0
      return @_singleLineCommentRegex
    if @spell.language is 'html'
      commentStart = "#{utils.commentStarts.html}|#{utils.commentStarts.css}|#{utils.commentStarts.javascript}"
    else
      commentStart = utils.commentStarts[@spell.language] or '//'
    @_singleLineCommentRegex = new RegExp "[ \t]*(#{commentStart})[^\"'\n]*"
    @_singleLineCommentRegex

  singleLineCommentOnlyRegex: ->
    if @_singleLineCommentOnlyRegex
      @_singleLineCommentOnlyRegex.lastIndex = 0
      return @_singleLineCommentOnlyRegex
    @_singleLineCommentOnlyRegex = new RegExp( '^' + @singleLineCommentRegex().source)
    @_singleLineCommentOnlyRegex

  commentOutMyCode: ->
    prefix = if @spell.language in ['javascript', 'java', 'cpp'] then 'return;  ' else 'return  '
    comment = prefix + utils.commentStarts[@spell.language]

  preload: ->
    # Send this code over to the God for preloading, but don't change the cast state.
    #console.log 'preload?', @spell.source.indexOf('while'), @spell.source.length, @spellThang?.castAether?.metrics?.statementsExecuted
    return if @spell.source.indexOf('while') isnt -1  # If they're working with while-loops, it's more likely to be an incomplete infinite loop, so don't preload.
    return if @spell.source.length > 500  # Only preload on really short methods
    return if @spellThang?.castAether?.metrics?.statementsExecuted > 2000  # Don't preload if they are running significant amounts of user code
    return if @options.level.isType('web-dev')
    oldSource = @spell.source
    oldSpellThangAether = @spell.thang?.aether.serialize()
    @spell.transpile @getSource()
    @cast true
    @spell.source = oldSource
    for key, value of oldSpellThangAether
      @spell.thang.aether[key] = value

  onAddUserSnippets: ->
    if @spell.team is me.team
      @addUserSnippets(@spell.getSource(), @spell.language, @ace?.getSession?())

  onSpellCreated: (e) ->
    if e.spell.team is me.team
      # ace session won't get correct language mode when created. so we wait for 1.5s
      # 2024.02.13 didn't find bug if no 1.5s delay. so try to shorten it to 0.5s
      setTimeout(() =>
        @addUserSnippets(e.spell.getSource(), e.spell.language, @ace?.getSession?())
      , 500)

  onSpellChanged: (e) ->
    # TODO: Merge with updateHTML
    @spellHasChanged = true

  onAceMouseOut: (e) ->
    Backbone.Mediator.publish("web-dev:stop-hovering-line", {})

  onAceMouseMove: (e) =>
    return if @destroyed
    row = e.getDocumentPosition().row
    return if row is @lastRowHovered # Don't spam repeated messages for the same line
    @lastRowHovered = row
    line = @aceSession.getLine(row)
    Backbone.Mediator.publish("web-dev:hover-line", { row: row, line })
    null

  onSessionWillSave: (e) ->
    return unless @spellHasChanged and me.isAdmin()
    setTimeout(=>
      unless @destroyed or @spellHasChanged
        @$el.find('.save-status').finish().show().fadeOut(2000)
    , 1000)
    @spellHasChanged = false

  onUserCodeProblem: (e) ->
    return unless e.god is @options.god
    return @onInfiniteLoop e if e.problem.id is 'runtime_InfiniteLoop'
    return unless e.problem.userInfo.methodName is @spell.name
    return unless @spell.thang?.thang.id is e.problem.userInfo.thangID
    @spell.hasChangedSignificantly @getSource(), null, (hasChanged) =>
      return if hasChanged
      if e.problem.type is 'runtime'
        @spellThang?.castAether?.addProblem e.problem
      else
        @spell.thang.aether.addProblem e.problem
      @lastUpdatedAetherSpellThang = null  # force a refresh without a re-transpile
      @updateAether false, false

  onNonUserCodeProblem: (e) ->
    return unless e.god is @options.god
    return unless @spellThang
    problem = @spellThang.aether.createUserCodeProblem type: 'runtime', kind: 'Unhandled', message: "Unhandled error: #{e.problem.message}"
    @spellThang.aether.addProblem problem
    @spellThang.castAether?.addProblem problem
    @lastUpdatedAetherSpellThang = null  # force a refresh without a re-transpile
    @updateAether false, false  # TODO: doesn't work, error doesn't display

  onInfiniteLoop: (e) ->
    return unless @spellThang
    @spellThang.aether.addProblem e.problem
    @spellThang.castAether?.addProblem e.problem
    @lastUpdatedAetherSpellThang = null  # force a refresh without a re-transpile
    @updateAether false, false

  onNewWorld: (e) ->
    @fetchTokenForSource().then (token) =>
      if thang = e.world.getThangByID @spell.thang?.thang.id
        aether = e.world.userCodeMap[thang.id]?[@spell.name]
        @spell.thang.castAether = aether
        @spell.thang.aether = @spell.createAether thang
        #console.log thang.id, @spell.spellKey, 'ran', aether.metrics.callsExecuted, 'times over', aether.metrics.statementsExecuted, 'statements, with max recursion depth', aether.metrics.maxDepth, 'and full flow/metrics', aether.metrics, aether.flow
      else
        @spell.thang = null


      @spell.transpile token
      @updateAether false, false

  # --------------------------------------------------------------------------------------------------

  focus: ->
    # TODO: it's a hack checking if a modal is visible; the events should be removed somehow
    # but this view is not part of the normal subview destroying because of how it's swapped
    return unless @controlsEnabled and @writable and $('.modal:visible, .shepherd-button:visible').length is 0
    return if @ace.isFocused()
    return if me.get('aceConfig')?.screenReaderMode and utils.isOzaria  # Screen reader users get to control their own focus manually
    return if @blocklyActive
    @ace.focus()
    @ace.clearSelection()

  onFrameChanged: (e) ->
    return unless @spellThang and e.selectedThang?.id is @spellThang?.thang.id
    @thang = e.selectedThang  # update our thang to the current version
    @highlightCurrentLine()

  onCoordinateSelected: (e) ->
    return unless @ace.isFocused() and e.x? and e.y?
    if @spell.language is 'python'
      @ace.insert "{\"x\": #{e.x}, \"y\": #{e.y}}"
    else if @spell.language is 'lua'
      @ace.insert "{x=#{e.x}, y=#{e.y}}"
    else
      @ace.insert "{x: #{e.x}, y: #{e.y}}"
    @highlightCurrentLine()

  onStatementIndexUpdated: (e) ->
    return unless e.ace is @ace
    @highlightCurrentLine()

  highlightCurrentLine: (flow) =>
    # TODO: move this whole thing into SpellDebugView or somewhere?
    @highlightEntryPoints() unless @destroyed
    flow ?= @spellThang?.castAether?.flow
    return unless flow and @thang
    executed = []
    executedRows = {}
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
        executedRows[state.range[0].row] = true
    #state.executing = true if state.userInfo?.time is @thang.world.age  # no work
    currentCallIndex ?= callNumber - 1
    #console.log 'got call index', currentCallIndex, 'for time', @thang.world.age, 'out of', states.length

    @decoratedGutter = @decoratedGutter || {}

    return unless @aceSession?

    # TODO: don't redo the markers if they haven't actually changed
    for markerRange in (@markerRanges ?= [])
      markerRange.start.detach()
      markerRange.end.detach()
      @aceSession.removeMarker markerRange.id
    @markerRanges = []
    for row in [0 ... @aceSession.getLength()]
      unless executedRows[row]
        @aceSession.removeGutterDecoration row, 'executing'
        @aceSession.removeGutterDecoration row, 'executed'
        @decoratedGutter[row] = ''
    lastExecuted = _.last executed
    showToolbarView = executed.length and @spellThang.castAether.metrics.statementsExecuted > 3 and not @options.level.get 'hidesCodeToolbar'  # Hide for a while
    showToolbarView = false  # TODO: fix toolbar styling in new design to have some space for it

    if showToolbarView
      statementIndex = Math.max 0, lastExecuted.length - 1
      @toolbarView?.toggleFlow true
      @toolbarView?.setCallState states[currentCallIndex], statementIndex, currentCallIndex, @spellThang.castAether.metrics
      lastExecuted = lastExecuted[0 .. @toolbarView.statementIndex] if @toolbarView?.statementIndex?
    else
      @toolbarView?.toggleFlow false
      @debugView?.setVariableStates {}
    marked = {}
    gotVariableStates = false
    for state, i in lastExecuted ? []
      [start, end] = state.range
      clazz = if i is lastExecuted.length - 1 then 'executing' else 'executed'
      if clazz is 'executed'
        continue if marked[start.row]
        marked[start.row] = true
        markerType = 'fullLine'
      else
        @debugView?.setVariableStates state.variables
        gotVariableStates = true
        markerType = 'text'
      markerRange = new Range start.row, start.col, end.row, end.col
      markerRange.start = @aceDoc.createAnchor markerRange.start
      markerRange.end = @aceDoc.createAnchor markerRange.end
      markerRange.id = @aceSession.addMarker markerRange, clazz, markerType
      @markerRanges.push markerRange
      if executedRows[start.row] and @decoratedGutter[start.row] isnt clazz
        @aceSession.removeGutterDecoration start.row, @decoratedGutter[start.row] if @decoratedGutter[start.row] isnt ''
        @aceSession.addGutterDecoration start.row, clazz
        @decoratedGutter[start.row] = clazz
        Backbone.Mediator.publish("tome:highlight-line", line:start.row) if application.isIPadApp
        $cinematicParent = $('#cinematic-code-display')
        highlightedIndex = 0
        for sourceLineNumber in [end.row - 3 .. end.row + 3]
          codeLine = _.string.rtrim @aceDoc.$lines[sourceLineNumber]
          $codeLineEl = $cinematicParent.find(".code-line-#{highlightedIndex++}")
          utils.replaceText $codeLineEl.find('.line-number'), if sourceLineNumber >= 0 then sourceLineNumber + 1 else ''
          utils.replaceText $codeLineEl.find('.indentation'), codeLine.match(/\s*/)[0]
          utils.replaceText $codeLineEl.find('.code-text'), _.string.trim(codeLine)

    @debugView?.setVariableStates {} unless gotVariableStates
    null

  highlightEntryPoints: ->
    # Put a yellow arrow in the gutter pointing to each place we expect them to put in code.
    # Usually, this is indicated by a blank line after a comment line, except for the first comment lines.
    # If we need to indicate an entry point on a line that has code, we use ∆ in a comment on that line.
    # If the entry point line has been changed (beyond the most basic shifted lines), we don't point it out.
    return unless @aceDoc?
    lines = @aceDoc.$lines
    originalLines = @spell.originalSource.split '\n'
    session = @aceSession
    commentStart = utils.commentStarts[@spell.language] or '//'
    seenAnEntryPoint = false
    previousLine = null
    previousLineHadComment = false
    previousLineHadCode = false
    previousLineWasBlank = false
    pastIntroComments = false
    for line, index in lines
      session.removeGutterDecoration index, 'entry-point'
      session.removeGutterDecoration index, 'next-entry-point'
      session.removeGutterDecoration index, "entry-point-indent-#{i}" for i in [0, 4, 8, 12, 16]

      lineHasComment = @singleLineCommentRegex().test line
      lineHasCode = line.trim()[0] and not @singleLineCommentOnlyRegex().test line
      lineIsBlank = /^[ \t]*$/.test line
      lineHasExplicitMarker = /[Δ∆]/.test(line)  # Two different identical-seeming delta codepoints

      originalLine = originalLines[index]
      lineHasChanged = line isnt originalLine

      isEntryPoint = lineIsBlank and previousLineHadComment and not previousLineHadCode and pastIntroComments
      if isEntryPoint and lineHasChanged
        # It might just be that the line was shifted around by the player inserting more code.
        # We also look for the unchanged comment line in a new position to find what line we're really on.
        movedIndex = originalLines.indexOf previousLine
        if movedIndex isnt -1 and line is originalLines[movedIndex + 1]
          lineHasChanged = false
        else
          isEntryPoint = false

      if lineHasExplicitMarker
        if lineHasChanged
          if originalLines.indexOf(line) isnt -1
            lineHasChanged = false
            isEntryPoint = true
        else
          isEntryPoint = true

      if isEntryPoint
        session.addGutterDecoration index, 'entry-point'
        unless seenAnEntryPoint
          session.addGutterDecoration index, 'next-entry-point'
          seenAnEntryPoint = true
          unless @hasSetInitialCursor
            @hasSetInitialCursor = true
            @ace.navigateTo index, line.match(/\S/)?.index ? line.length
            @firstEntryToScrollLine = index

        # Shift pointer right based on current indentation
        # TODO: tabs probably need different horizontal offsets than spaces
        indent = 0
        indent++ while /\s/.test(line[indent])
        indent = Math.min(16, Math.floor(indent / 4) * 4)
        session.addGutterDecoration index, "entry-point-indent-#{indent}"

      previousLine = line
      previousLineHadComment = lineHasComment
      previousLineHadCode = lineHasCode
      previousLineWasBlank = lineIsBlank
      pastIntroComments ||= lineHasCode or previousLineWasBlank

  onAnnotationClick: ->
    # @ is the gutter element
    Backbone.Mediator.publish 'tome:jiggle-problem-alert', {}

  onGutterClick: =>
    @ace.clearSelection()

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, @writable
  toggleControls: (e, enabled) ->
    return if @destroyed
    return if e?.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled and @writable
    disabled = not enabled
    wasFocused = @ace.isFocused()
    @ace.setReadOnly disabled
    @ace[if disabled then 'setStyle' else 'unsetStyle'] 'disabled'
    @toggleBackground()
    $('body').focus() if disabled and wasFocused

  toggleBackground: =>
    # TODO: make the background an actual background and do the CSS trick
    # used in spell-top-bar-view.sass for disabling
    background = @$el.find('img.code-background')[0]
    if background.naturalWidth is 0  # not loaded yet
      return _.delay @toggleBackground, 100
    filters.revertImage background, 'span.code-background' if @controlsEnabled
    filters.darkenImage background, 'span.code-background', 0.8 unless @controlsEnabled

  onSpellBeautify: (e) ->
    return unless @spellThang and (@ace.isFocused() or e.spell is @spell or not e.spell)
    ugly = @getSource()
    pretty = @spellThang.aether.beautify(ugly.replace /\bloop\b/g, 'while (__COCO_LOOP_CONSTRUCT__)').replace /while \(__COCO_LOOP_CONSTRUCT__\)/g, 'loop'
    @ace.setValue pretty

  onFixCode: (e) ->
    @ace.setValue e.code
    @ace.clearSelection()
    @recompile()

  onFixCodePreviewStart: (e) ->
    # TODO: show a diff view instead of just setting the code
    @codeBeforePreview = @getSource()
    @updateACEText e.code
    @ace.clearSelection()

  onFixCodePreviewEnd: (e) ->
    @updateACEText @codeBeforePreview
    @ace.clearSelection()

  fillACESolution: ->
    @aceSolution = ace.edit document.querySelector('.ace-solution')
    aceSession = @aceSolution.getSession()
    aceSession.setMode aceUtils.aceEditModes[@spell.language]
    @aceSolution.setTheme 'ace/theme/textmate'
    if @teaching
      solution = store.getters['game/getSolutionSrc'](@spell.language)
    else
      solution = ''
    @aceSolution.setValue solution
    @aceSolution.clearSelection()
    @aceSolutionLastLineCount = 0
    @updateSolutionLines = _.throttle @updateSolutionLines, 1000

    @aceDiff = new AceDiff({
      element: '#solution-view'
      showDiffs: false,
      showConnectors: true,
      mode: aceUtils.aceEditModes[@spell.language],
      left: {
        ace: @aceSolution,
        editable: false,
        copyLinkEnabled: false
      },
      right: {
        ace: @ace,
        copyLinkEnabled: false
      }
    })

    aceSession.on('changeBackMarker', =>
      if @aceDiff and @aceDiff.getNumDiffs() == 0
        Backbone.Mediator.publish 'level:close-solution', { removeButton: true }
    )

  onUpdateSolution: (e)->
    return unless @aceDiff
    @aceSolution.setValue e.code
    @aceSolution.clearSelection()
    @updateSolutionLines(@aceSolution, '.ace-solution', '#solution-area')

  onStreamingSolution: (e) ->
    if e.finish
      @solutionStreaming = false
    else
      @solutionStreaming = true
    solution = document.querySelector('#solution-area')
    if solution.classList.contains('display')
      @aceDiff.setOptions({showDiffs: e.finish?})

  onToggleSolution: (e)->
    return unless @aceDiff and not @blocklyActive
    if e.code
      @onUpdateSolution(e)
    solution = document.querySelector('#solution-area')
    if solution.classList.contains('display')
      solution.classList.remove('display')
    else
      solution.classList.add('display')
      Backbone.Mediator.publish 'tome:hide-problem-alert', {}
    return if @solutionStreaming
    @aceDiff.setOptions showDiffs: solution.classList.contains('display')

  closeSolution: ->
    solution = document.querySelector('#solution-area')
    if solution.classList.contains('display')
      solution.classList.remove('display')
      @aceDiff.setOptions({showDiffs: false})
      setTimeout(() =>
        solution.style.opacity = 0
      , 1000)

  onToggleBlocks: (e) ->
    return if e.blocks and @blocklyActive
    return if not e.blocks and not @blocklyActive
    if e.blocks and @blockly
      # Show it
      @blocklyActive = true
    else if e.blocks
      # Create it
      @addBlockly()
    else if @blockly
      # Hide it
      @awaitingBlockly = false
      @blocklyActive = false
    @resize()

  onWindowResize: (e) =>
    @spellPaletteHeight = null
    #$('#spell-palette-view').css 'height', 'auto'  # Let it go back to controlling its own height
    _.delay (=> @resize?()), 500 + 100  # Wait $level-resize-transition-time, plus a bit.

  resize: ->
    @ace?.resize true
    @lastScreenLineCount = null
    @updateLines()
    @resizeBlockly()
    @updateSolutionLines(@aceSolution, '.ace-solution', '#solution-area')

  resizeBlockly: (repeat=true) ->
    return unless @blocklyActive
    Blockly.svgResize @blockly
    if repeat
      @scrollBlocklyToTopLeft()
      _.delay (=> @resizeBlockly?(false)), 500 + 100  # Wait $level-resize-transition-time, plus a bit, again!

  scrollBlocklyToTopLeft: ->
    metrics = @blockly.getMetrics()
    @blockly.scroll -metrics.contentLeft + 30, -metrics.contentTop + 50

  onChangeEditorConfig: (e) ->
    aceConfig = me.get('aceConfig') ? {}
    @ace.setBehavioursEnabled aceConfig.behaviors
    @ace.setKeyboardHandler @keyBindings[aceConfig.keyBindings ? 'default']
    @updateAutocomplete(aceConfig.liveCompletion ? false)
    $(window).trigger('resize') unless @destroyed

  onChangeLanguage: (e) ->
    return unless @spell.canWrite()
    @aceSession.setMode aceUtils.aceEditModes[e.language]
    @autocomplete?.set 'language', aceUtils.aceEditModes[e.language].substr('ace/mode/')
    wasDefault = @getSource() is @spell.originalSource
    @spell.setLanguage e.language
    @reloadCode true if wasDefault
    @renderSelectors('.programming-language')

  onInsertSnippet: (e) ->
    snippetCode = null
    if e.doc.snippets?[e.language]?.code
      snippetCode = e.doc.snippets[e.language].code
    else if (e.formatted.type isnt 'snippet') and e.formatted.shortName?
      snippetCode = e.formatted.shortName
    return unless snippetCode?
    snippetManager = ace.require('ace/snippets').snippetManager
    snippetManager.insertSnippet @ace, snippetCode
    return

  dismiss: ->
    @spell.hasChangedSignificantly @getSource(), null, (hasChanged) =>
      @recompile() if hasChanged

  onScriptStateChange: (e) ->
    @scriptRunning = if e.currentScript is null then false else true

  onPlaybackEndedChanged: (e) ->
    $(@ace?.container).toggleClass 'playback-ended', e.ended

  onGatherChatMessageContext: (e) ->
    context = e.chat.context
    context.codeLanguage = @spell.language or 'python'
    if level = @options.level
      context.levelOriginal = level.get('original')
      context.levelName = level.get('displayName') or level.get('name')
      if e.chat.example
        context.i18n ?= {}
        for language, translations of level.get('i18n')
          if levelNameTranslation = translations.name
            context.i18n[language] ?= {}
            context.i18n[language].levelName = levelNameTranslation

    aether = @displayedAether  # TODO: maybe use @spellThang.aether?
    isCast = @displayedAether is @spellThang.aether or not _.isEmpty(aether.metrics) or _.some aether.getAllProblems(), {type: 'runtime'}
    newProblems = @convertAetherProblems(aether, aether.getAllProblems(), false) # do not cast the problem here
    if problem = newProblems[0]
      ucp = @createUserCodeProblem aether, problem.aetherProblem
      context.error = _.pick
        codeSnippet: ucp.get 'codeSnippet'
        hint: ucp.get 'errHint'
        id: ucp.get 'errId'
        errorCode: ucp.get 'errCode'
        level: ucp.get 'errLevel'
        message: ucp.get 'errMessage'
        messageNoLineInfo: ucp.get 'errMessageNoLineInfo'
        range: ucp.get 'errRange'
        type: ucp.get 'errType'
        i18nParams: problem.i18nParams
      , (v) -> v isnt undefined

    spellContext = @spell.createChatMessageContext e.chat
    _.assign context, spellContext

  checkRequiredCode: =>
    return if @destroyed
    source = @getSource().replace @singleLineCommentRegex(), ''
    requiredCodeFragments = @options.level.get 'requiredCode'
    for requiredCodeFragment in requiredCodeFragments
      # Could make this obey regular expressions like suspectCode if needed
      if source.indexOf(requiredCodeFragment) is -1
        @warnedCodeFragments ?= {}
        unless @warnedCodeFragments[requiredCodeFragment]
          Backbone.Mediator.publish 'tome:required-code-fragment-deleted', codeFragment: requiredCodeFragment
        @warnedCodeFragments[requiredCodeFragment] = true

  checkSuspectCode: =>
    return if @destroyed
    source = @getSource().replace @singleLineCommentRegex(), ''
    suspectCodeFragments = @options.level.get 'suspectCode'
    detectedSuspectCodeFragmentNames = []
    for suspectCodeFragment in suspectCodeFragments
      pattern = new RegExp suspectCodeFragment.pattern, 'm'
      if pattern.test source
        @warnedCodeFragments ?= {}
        unless @warnedCodeFragments[suspectCodeFragment.name]
          Backbone.Mediator.publish 'tome:suspect-code-fragment-added', codeFragment: suspectCodeFragment.name, codeLanguage: @spell.language
        @warnedCodeFragments[suspectCodeFragment.name] = true
        detectedSuspectCodeFragmentNames.push suspectCodeFragment.name
    for lastDetectedSuspectCodeFragmentName in @lastDetectedSuspectCodeFragmentNames ? []
      unless lastDetectedSuspectCodeFragmentName in detectedSuspectCodeFragmentNames
        Backbone.Mediator.publish 'tome:suspect-code-fragment-deleted', codeFragment: lastDetectedSuspectCodeFragmentName, codeLanguage: @spell.language
    @lastDetectedSuspectCodeFragmentNames = detectedSuspectCodeFragmentNames

  onAskingHelp: (e) ->
    if utils.useWebsocket
      msg = e.msg
      msg.info.url += "?course=#{@courseID}&codeLanguage=#{@session.get('codeLanguage')}&session=#{@session.id}&teaching=true"
      fetchJson("/db/level.session/#{@session.id}/permissions/ws/#{msg.to}", { method: 'PUT' }).then(() =>
        if @yjsProvider and @yjsProvide.wsconnected
          globalVar.application.wsBus.ws.sendJSON(msg)
        else
          @yjsProvider = aceUtils.setupCRDT("#{@session.id}", me.broadName(), @getSource(), @ace, () => globalVar.application.wsBus.ws.sendJSON(msg))
          @yjsProvider.connections = 1
          @yjsProvider.awareness.on('change', () =>
            @yjsProvider.connections = @yjsProvider.awareness.getStates().size
            console.log('provider get awareness update:', @yjsProvider.connections)
          )
      )

  onCinematicPlaybackStarted: (e) ->
    return if @cinematic
    @cinematic = true
    @blockly?.getToolbox()?.setVisible false
    @blockly?.getFlyout()?.setVisible false

  onCinematicPlaybackEnded: (e) ->
    return unless @cinematic
    @cinematic = false
    @blockly?.getToolbox()?.setVisible true
    @blockly?.getFlyout()?.setVisible true
    null

  destroy: ->
    $(@ace?.container).find('.ace_gutter').off 'click mouseenter', '.ace_error, .ace_warning, .ace_info'
    $(@ace?.container).find('.ace_gutter').off()
    @blockly?.dispose()
    @ace?.commands.removeCommand command for command in @aceCommands
    @ace?.destroy()
    @aceDoc?.off 'change', @onCodeChangeMetaHandler
    @aceSession?.selection.off 'changeCursor', @onCursorActivity
    @destroyAceEditor(@ace)
    @destroyAceEditor(@aceSolution)
    @debugView?.destroy()
    @translationView?.destroy()
    @toolbarView?.destroy()
    @autocomplete?.addSnippets [], @editorLang if @editorLang?
    $(window).off 'resize', @onWindowResize
    if @spade?
      @spade.createUIEvent "destroying-view"
    @saveSpade()
    window.clearTimeout @saveSpadeTimeout
    @saveSpadeTimeout = null
    @autocomplete?.destroy()
    super()
