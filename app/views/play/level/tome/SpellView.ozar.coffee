require('app/styles/play/level/tome/spell.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/spell'
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
CodeLog = require 'models/CodeLog'
Autocomplete = require './editor/autocomplete'
TokenIterator = ace.require('ace/token_iterator').TokenIterator
LZString = require 'lz-string'
utils = require 'core/utils'

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
    'level:session-will-save': 'onSessionWillSave'
    'modal:closed': 'focus'
    'tome:focus-editor': 'focus'
    'tome:spell-statement-index-updated': 'onStatementIndexUpdated'
    'tome:change-language': 'onChangeLanguage'
    'tome:change-config': 'onChangeEditorConfig'
    'tome:update-snippets': 'addAutocompleteSnippets'
    'tome:insert-snippet': 'onInsertSnippet'
    'tome:spell-beautify': 'onSpellBeautify'
    'tome:maximize-toggled': 'onMaximizeToggled'
    'tome:problems-updated': 'onProblemsUpdated'
    'script:state-changed': 'onScriptStateChange'
    'playback:ended-changed': 'onPlaybackEndedChanged'
    'level:contact-button-pressed': 'onContactButtonPressed'
    'level:show-victory': 'onShowVictory'
    'web-dev:error': 'onWebDevError'

  events:
    'mouseout': 'onMouseOut'

  constructor: (options) ->
    @supermodel = options.supermodel
    super options
    @worker = options.worker
    @session = options.session
    @spell = options.spell
    @problems = []
    @savedProblems = {} # Cache saved user code problems to prevent duplicates
    @writable = false unless me.team in @spell.permissions.readwrite  # TODO: make this do anything
    @highlightCurrentLine = _.throttle @highlightCurrentLine, 100
    $(window).on 'resize', @onWindowResize
    @observing = @session.get('creator') isnt me.id

  afterRender: ->
    super()
    @createACE()
    @createACEShortcuts()
    @hookACECustomBehavior()
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
    @initAutocomplete aceConfig.liveCompletion ? true

    return if @session.get('creator') isnt me.id or @session.fake
    # Create a Spade to 'dig' into Ace.
    @spade = new Spade()
    @spade.track(@ace)
    # If a user is taking longer than 10 minutes, let's log it.
    saveSpadeDelay = 10 * 60 * 1000
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
      name: 'toggle-playing'
      bindKey: {win: 'Ctrl-P', mac: 'Command-P|Ctrl-P'}
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
      name: 'open-fullscreen-editor'
      bindKey: {win: 'Ctrl-Shift-M', mac: 'Command-Shift-M|Ctrl-Shift-M'}
      exec: -> Backbone.Mediator.publish 'tome:toggle-maximize', {}
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
        disableSpaces = false if @spell.language in ['lua', 'java', 'coffeescript', 'html']  # Don't disable for more advanced/experimental languages
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

    @aceSession.addDynamicMarker
      update: (html, markerLayer, session, config) =>
        Range = ace.require('ace/range').Range

        foldWidgets = @aceSession.foldWidgets
        return if not foldWidgets?

        lines = @aceDoc.getAllLines()
        startOfRow = (r) ->
          str = lines[r]
          ar = str.match(/^\s*/)
          ar.pop().length

        colors = [{border: '74,144,226', fill: '108,162,226'}, {border: '132,180,235', fill: '230,237,245'}]

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

          html.push """
            <div style=
              "position: absolute; top: #{to}px; left: #{l}px; width: #{fw+bw}px; height: #{config.lineHeight}px;
               border: #{bw}px solid rgba(#{color.border},1); border-left: none;"
            ></div>
            <div style=
              "position: absolute; top: #{t}px; left: #{l}px; width: #{w}px; height: #{h}px; background-color: rgba(#{color.fill},0.5);
               border-right: #{bw}px solid rgba(#{color.border},1); border-bottom: #{bw}px solid rgba(#{color.border},1);"
            ></div>
          """

  fillACE: ->
    @ace.setValue @spell.source
    @aceSession.setUndoManager(new UndoManager())
    @ace.clearSelection()

  lockDefaultCode: (force=false) ->
    # TODO: Lock default indent for an empty line?
    lockDefaultCode = @options.level.get('lockDefaultCode') or false
    if not lockDefaultCode or (_.isNumber(lockDefaultCode) and lockDefaultCode < me.level())
      return
    return unless @spell.source is @spell.originalSource or force
    return if @isIE()  # Temporary workaround for #2512
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
        javascript: ';'
      popupFontSizePx: popupFontSizePx
      popupLineHeightPx: 1.5 * popupFontSizePx
      popupWidthPx: 380

  updateAutocomplete: (@autocompleteOn) ->
    @autocomplete?.set 'snippets', @autocompleteOn

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

  createFirepad: ->
    # Currently not called; could be brought back for future multiplayer modes.
    # Load from firebase or the original source if there's nothing there.
    return if @firepadLoading
    @eventsSuppressed = true
    @loaded = false
    @previousSource = @ace.getValue()
    @ace.setValue('')
    @aceSession.setUndoManager(new UndoManager())
    fireURL = 'https://codecombat.firebaseio.com/' + @spell.pathComponents.join('/')
    @fireRef = new Firebase fireURL
    firepadOptions = userId: me.id
    @firepad = Firepad.fromACE @fireRef, @ace, firepadOptions
    @firepadLoading = true
    @firepad.on 'ready', =>
      return if @destroyed
      @firepadLoading = false
      firepadSource = @ace.getValue()
      if firepadSource
        @spell.source = firepadSource
      else
        @ace.setValue @previousSource
        @aceSession.setUndoManager(new UndoManager())
        @ace.clearSelection()
      @onAllLoaded()

  onAllLoaded: =>
    @fetchToken(@spell.source, @spell.language).then (token) =>
      @spell.transpile token
      @spell.loaded = true
      Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
      @eventsSuppressed = false  # Now that the initial change is in, we can start running any changed code
      @createToolbarView()
      @updateHTML create: true if @options.level.isType('web-dev')

  createDebugView: ->
    return if @options.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev')  # We'll turn this on later, maybe, but not yet.
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
    return if @destroyed or @aceDoc.undergoingFirepadOperation  # from my Firepad ACE adapter
    Backbone.Mediator.publish 'tome:editing-ended', {}

  notifyEditingBegan: =>
    return if @destroyed or @aceDoc.undergoingFirepadOperation  # from my Firepad ACE adapter
    Backbone.Mediator.publish 'tome:editing-began', {}

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
      lineHeight = @ace.renderer.lineHeight or 20
      tomeHeight = $('#tome-view').innerHeight()
      spellTopBarHeight = $('#spell-top-bar-view').outerHeight()
      spellToolbarHeight = $('.spell-toolbar-view').outerHeight()
      @spellPaletteHeight ?= 75
      spellPaletteAllowedHeight = Math.min @spellPaletteHeight, tomeHeight / 3
      maxHeight = tomeHeight - spellTopBarHeight - spellToolbarHeight - spellPaletteAllowedHeight
      minHeight = Math.max 8, (Math.min($("#canvas-wrapper").outerHeight(),$("#level-view").innerHeight() - 175) / lineHeight) - 2
      linesAtMaxHeight = Math.floor(maxHeight / lineHeight)
      lines = Math.max minHeight, Math.min(screenLineCount + 2, linesAtMaxHeight)
      # 2 lines buffer is nice
      @ace.setOptions minLines: lines, maxLines: lines
      # Move spell palette up, slightly overlapping us.
      newTop = 185 + lineHeight * lines
      #spellPaletteView.css('top', newTop)
      # Expand it to bottom of tome if too short.
      #newHeight = Math.max @spellPaletteHeight, tomeHeight - newTop + 10
      #spellPaletteView.css('height', newHeight) if @spellPaletteHeight isnt newHeight
    if @firstEntryToScrollLine? and @ace?.renderer?.$cursorLayer?.config
      @ace.scrollToLine @firstEntryToScrollLine, true, true
      @firstEntryToScrollLine = undefined


  hideProblemAlert: ->
    return if @destroyed
    Backbone.Mediator.publish 'tome:hide-problem-alert', {}

  saveSpade: =>
    return if @destroyed or not @spade
    spadeEvents = @spade.compile()
    # Uncomment the below line for a debug panel to display inside the level
    #@spade.debugPlay(spadeEvents)
    condensedEvents = @spade.condense(spadeEvents)

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
    if @saveSpadeTimeout?
      window.clearTimeout @saveSpadeTimeout
      @saveSpadeTimeout = null

  onManualCast: (e) ->
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
    @lockDefaultCode true
    @recompile cast
    Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
    @hasSetInitialCursor = false
    @highlightCurrentLine()
    @updateLines()

  recompile: (cast=true, realTime=false, cinematic=false) ->
    @fetchTokenForSource().then (source) =>
      hasChanged = @spell.source isnt source
      if hasChanged
        @spell.transpile source
        @updateAether true, false
      if cast  #and (hasChanged or realTime)  # just always cast now
        @cast(false, realTime, false, cinematic)
      if hasChanged
        @notifySpellChanged()

  updateACEText: (source) ->
    @eventsSuppressed = true
    if @firepad
      @firepad.setText source
    else
      @ace.setValue source
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
    if language not in ['java']
      return Promise.resolve(source)

    headers =  { 'Accept': 'application/json', 'Content-Type': 'application/json' }
    m = document.cookie.match(/JWT=([a-zA-Z0-9.]+)/)
    service = window?.localStorage?.kodeKeeperService or "/service/parse-code"
    fetch service, {method: 'POST', mode:'cors', headers:headers, body:JSON.stringify({code: source, language: language})}
    .then (x) => x.json()
    .then (x) => x.token

  fetchTokenForSource: () =>
    source = @ace.getValue()
    @fetchToken(source, @spell.language)

  updateAether: (force=false, fromCodeChange=true) =>
    # Depending on whether we have any code changes, significant code changes, or have switched
    # to a new spellThang, we may want to refresh our Aether display.
    return unless aether = @spellThang?.aether
    @fetchTokenForSource().then (source) =>
      @spell.hasChangedSignificantly source, aether.raw, (hasChanged) =>
        codeHasChangedSignificantly = force or hasChanged
        needsUpdate = codeHasChangedSignificantly or @spellThang isnt @lastUpdatedAetherSpellThang
        return if not needsUpdate and aether is @displayedAether
        castAether = @spellThang.castAether
        codeIsAsCast = castAether and source is castAether.raw
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
                aether.raw = source
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
    @userCodeProblem = new UserCodeProblem()
    @userCodeProblem.set 'code', aether.raw
    if aetherProblem.range
      rawLines = aether.raw.split '\n'
      errorLines = rawLines.slice aetherProblem.range[0].row, aetherProblem.range[1].row + 1
      @userCodeProblem.set 'codeSnippet', errorLines.join '\n'
    @userCodeProblem.set 'errHint', aetherProblem.hint if aetherProblem.hint
    @userCodeProblem.set 'errId', aetherProblem.id if aetherProblem.id
    @userCodeProblem.set 'errLevel', aetherProblem.level if aetherProblem.level
    if aetherProblem.message
      @userCodeProblem.set 'errMessage', aetherProblem.message
      # Save error message without 'Line N: ' prefix
      messageNoLineInfo = aetherProblem.message
      if lineInfoMatch = messageNoLineInfo.match /^Line [0-9]+\: /
        messageNoLineInfo = messageNoLineInfo.slice(lineInfoMatch[0].length)
      @userCodeProblem.set 'errMessageNoLineInfo', messageNoLineInfo
    @userCodeProblem.set 'errRange', aetherProblem.range if aetherProblem.range
    @userCodeProblem.set 'errType', aetherProblem.type if aetherProblem.type
    @userCodeProblem.set 'language', aether.language.id if aether.language?.id
    @userCodeProblem.set 'levelID', @options.levelID if @options.levelID
    @userCodeProblem.save()
    null

  # Autocast (preload the world in the background):
  # Goes immediately if the code is a) changed and b) complete/valid and c) the cursor is at beginning or end of a line
  # We originally thought it would:
  # - Go after specified delay if a) and b) but not c)
  # - Go only when manually cast or deselecting a Thang when there are errors
  # But the error message display was delayed, so now trying:
  # - Go after specified delay if a) and not b) or c)
  guessWhetherFinished: (aether) ->
    valid = not aether.getAllProblems().length
    return unless valid
    cursorPosition = @ace.getCursorPosition()
    currentLine = _.string.rtrim(@aceDoc.$lines[cursorPosition.row].replace(@singleLineCommentRegex(), ''))  # trim // unless inside "
    endOfLine = cursorPosition.column >= currentLine.length  # just typed a semicolon or brace, for example
    beginningOfLine = not currentLine.substr(0, cursorPosition.column).trim().length  # uncommenting code, for example
    incompleteThis = /^(s|se|sel|self|t|th|thi|this|g|ga|gam|game|h|he|her|hero)$/.test currentLine.trim()
    #console.log "finished=#{valid and (endOfLine or beginningOfLine) and not incompleteThis}", valid, endOfLine, beginningOfLine, incompleteThis, cursorPosition, currentLine.length, aether, new Date() - 0, currentLine
    if not incompleteThis and @options.level.isType('game-dev')
      # TODO: Improve gamedev autocast speed
      @spell.transpile @getSource()
      @cast(false, false, true)
    else if (endOfLine or beginningOfLine) and not incompleteThis
      @preload()

  singleLineCommentRegex: ->
    if @_singleLineCommentRegex
      @_singleLineCommentRegex.lastIndex = 0
      return @_singleLineCommentRegex
    if @spell.language is 'html'
      commentStart = "#{commentStarts.html}|#{commentStarts.css}|#{commentStarts.javascript}"
    else
      commentStart = commentStarts[@spell.language] or '//'
    @_singleLineCommentRegex = new RegExp "[ \t]*(#{commentStart})[^\"'\n]*"
    @_singleLineCommentRegex

  singleLineCommentOnlyRegex: ->
    if @_singleLineCommentOnlyRegex
      @_singleLineCommentOnlyRegex.lastIndex = 0
      return @_singleLineCommentOnlyRegex
    @_singleLineCommentOnlyRegex = new RegExp( '^' + @singleLineCommentRegex().source)
    @_singleLineCommentOnlyRegex

  commentOutMyCode: ->
    prefix = if @spell.language is 'javascript' then 'return;  ' else 'return  '
    comment = prefix + commentStarts[@spell.language]

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

  onSpellChanged: (e) ->
    # TODO: Merge with updateHTML
    @spellHasChanged = true

  onAceMouseOut: (e) ->
    Backbone.Mediator.publish("web-dev:stop-hovering-line")

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
        @spellThang.castAether?.addProblem e.problem
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
    return unless @controlsEnabled and @writable and $('.modal:visible').length is 0
    return if @ace.isFocused()
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
    lines = @aceDoc.$lines
    originalLines = @spell.originalSource.split '\n'
    session = @aceSession
    commentStart = commentStarts[@spell.language] or '//'
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
      lineHasExplicitMarker = line.indexOf('∆') isnt -1

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
    return unless @spellThang and (@ace.isFocused() or e.spell is @spell)
    ugly = @getSource()
    pretty = @spellThang.aether.beautify(ugly.replace /\bloop\b/g, 'while (__COCO_LOOP_CONSTRUCT__)').replace /while \(__COCO_LOOP_CONSTRUCT__\)/g, 'loop'
    @ace.setValue pretty

  onMaximizeToggled: (e) ->
    _.delay (=> @resize()), 500 + 100  # Wait $level-resize-transition-time, plus a bit.

  onWindowResize: (e) =>
    @spellPaletteHeight = null
    #$('#spell-palette-view').css 'height', 'auto'  # Let it go back to controlling its own height
    _.delay (=> @resize?()), 500 + 100  # Wait $level-resize-transition-time, plus a bit.

  resize: ->
    @ace?.resize true
    @lastScreenLineCount = null
    @updateLines()

  onChangeEditorConfig: (e) ->
    aceConfig = me.get('aceConfig') ? {}
    @ace.setBehavioursEnabled aceConfig.behaviors
    @ace.setKeyboardHandler @keyBindings[aceConfig.keyBindings ? 'default']
    @updateAutocomplete(aceConfig.liveCompletion ? false)

  onChangeLanguage: (e) ->
    return unless @spell.canWrite()
    @aceSession.setMode aceUtils.aceEditModes[e.language]
    @autocomplete?.set 'language', aceUtils.aceEditModes[e.language].substr('ace/mode/')
    wasDefault = @getSource() is @spell.originalSource
    @spell.setLanguage e.language
    @reloadCode true if wasDefault

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

  destroy: ->
    $(@ace?.container).find('.ace_gutter').off 'click', '.ace_error, .ace_warning, .ace_info', @onAnnotationClick
    $(@ace?.container).find('.ace_gutter').off 'click', @onGutterClick
    @firepad?.dispose()
    @ace?.commands.removeCommand command for command in @aceCommands
    @ace?.destroy()
    @aceDoc?.off 'change', @onCodeChangeMetaHandler
    @aceSession?.selection.off 'changeCursor', @onCursorActivity
    @destroyAceEditor(@ace)
    @debugView?.destroy()
    @translationView?.destroy()
    @toolbarView?.destroy()
    @autocomplete?.addSnippets [], @editorLang if @editorLang?
    $(window).off 'resize', @onWindowResize
    window.clearTimeout @saveSpadeTimeout
    @saveSpadeTimeout = null
    super()

# Note: These need to be double-escaped for insertion into regexes
commentStarts =
  javascript: '//'
  python: '#'
  coffeescript: '#'
  lua: '--'
  java: '//'
  html: '<!--'
  css: '/\\*'
