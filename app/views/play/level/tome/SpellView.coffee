CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/spell'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
Range = ace.require('ace/range').Range
UndoManager = ace.require('ace/undomanager').UndoManager
Problem = require './Problem'
SpellDebugView = require './SpellDebugView'
SpellToolbarView = require './SpellToolbarView'
LevelComponent = require 'models/LevelComponent'
UserCodeProblem = require 'models/UserCodeProblem'

module.exports = class SpellView extends CocoView
  id: 'spell-view'
  className: 'shown'
  template: template
  controlsEnabled: true
  eventsSuppressed: true
  writable: true

  @editModes:
    'javascript': 'ace/mode/javascript'
    'coffeescript': 'ace/mode/coffee'
    'python': 'ace/mode/python'
    'clojure': 'ace/mode/clojure'
    'lua': 'ace/mode/lua'
    'io': 'ace/mode/text'

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
    'tome:reload-code': 'onCodeReload'
    'tome:spell-changed': 'onSpellChanged'
    'level:session-will-save': 'onSessionWillSave'
    'modal:closed': 'focus'
    'tome:focus-editor': 'focus'
    'tome:spell-statement-index-updated': 'onStatementIndexUpdated'
    'tome:change-language': 'onChangeLanguage'
    'tome:change-config': 'onChangeEditorConfig'
    'tome:update-snippets': 'addZatannaSnippets'
    'tome:insert-snippet': 'onInsertSnippet'
    'tome:spell-beautify': 'onSpellBeautify'
    'tome:maximize-toggled': 'onMaximizeToggled'
    'script:state-changed': 'onScriptStateChange'
    'playback:ended-changed': 'onPlaybackEndedChanged'

  events:
    'mouseout': 'onMouseOut'

  constructor: (options) ->
    super options
    @worker = options.worker
    @session = options.session
    @listenTo(@session, 'change:multiplayer', @onMultiplayerChanged)
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
    if @session.get('multiplayer')
      @createFirepad()
    else
      # needs to happen after the code generating this view is complete
      _.defer @onAllLoaded

  createACE: ->
    # Test themes and settings here: http://ace.ajax.org/build/kitchen-sink.html
    aceConfig = me.get('aceConfig') ? {}
    @destroyAceEditor(@ace)
    @ace = ace.edit @$el.find('.ace')[0]
    @aceSession = @ace.getSession()
    @aceDoc = @aceSession.getDocument()
    @aceSession.setUseWorker false
    @aceSession.setMode SpellView.editModes[@spell.language]
    @aceSession.setWrapLimitRange null
    @aceSession.setUseWrapMode true
    @aceSession.setNewLineMode 'unix'
    @aceSession.setUseSoftTabs true
    @ace.setTheme 'ace/theme/textmate'
    @ace.setDisplayIndentGuides aceConfig.indentGuides
    @ace.setShowPrintMargin false
    @ace.setShowInvisibles aceConfig.invisibles
    @ace.setBehavioursEnabled aceConfig.behaviors
    @ace.setAnimatedScroll true
    @ace.setShowFoldWidgets false
    @ace.setKeyboardHandler @keyBindings[aceConfig.keyBindings ? 'default']
    @ace.$blockScrolling = Infinity
    @toggleControls null, @writable
    @aceSession.selection.on 'changeCursor', @onCursorActivity
    $(@ace.container).find('.ace_gutter').on 'click mouseenter', '.ace_error, .ace_warning, .ace_info', @onAnnotationClick
    $(@ace.container).find('.ace_gutter').on 'click', @onGutterClick
    @initAutocomplete aceConfig.liveCompletion ? true

  createACEShortcuts: ->
    @aceCommands = aceCommands = []
    ace = @ace
    addCommand = (c) ->
      ace.commands.addCommand c
      aceCommands.push c.name
    addCommand
      name: 'run-code'
      bindKey: {win: 'Shift-Enter|Ctrl-Enter', mac: 'Shift-Enter|Command-Enter|Ctrl-Enter'}
      exec: -> Backbone.Mediator.publish 'tome:manual-cast', {}
    unless @observing
      addCommand
        name: 'run-code-real-time'
        bindKey: {win: 'Ctrl-Shift-Enter', mac: 'Command-Shift-Enter|Ctrl-Shift-Enter'}
        exec: =>
          if @options.level.get('replayable') and (timeUntilResubmit = @session.timeUntilResubmit()) > 0
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
          if delimMatch = line.substring(cursor.column).match /^(["|']?\)+;?)/  # Yay for editors misreading regexes: "
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
        disableSpaces = false if @spell.language in ['clojure', 'lua', 'coffeescript', 'io']  # Don't disable for more advanced/experimental languages
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
    @ace.commands.on 'exec', (e) =>
      # When pressing enter with an active selection, just make a new line under it.
      if e.command.name is 'enter-skip-delimiters'
        e.editor.execCommand 'gotolineend'
        return true

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

    pulseLockedCode = ->
      $('.locked-code').finish().addClass('pulsating').effect('shake', times: 1, distance: 2, direction: 'down').removeClass('pulsating')

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
        @zatanna?.off?()
        pulseLockedCode()
        return false
      else if e.command.name in ['enter-skip-delimiters', 'Enter', 'Return']
        if intersects()
          e.editor.navigateDown 1
          e.editor.navigateLineStart()
          return false
        else if e.command.name in ['Enter', 'Return'] and not e.editor?.completer?.popup?.isOpen
          @zatanna?.on?()
          return e.editor.execCommand 'enter-skip-delimiters'
      @zatanna?.on?()
      e.command.exec e.editor, e.args or {}

  initAutocomplete: (@autocomplete) ->
    # TODO: Turn on more autocompletion based on level sophistication
    # TODO: E.g. using the language default snippets yields a bunch of crazy non-beginner suggestions
    # TODO: Options logic shouldn't exist both here and in updateAutocomplete()
    popupFontSizePx = @options.level.get('autocompleteFontSizePx') ? 16
    @zatanna = new Zatanna @ace,
      basic: false
      liveCompletion: false
      snippetsLangDefaults: false
      completers:
        keywords: false
        snippets: @autocomplete
        text: @autocomplete
      autoLineEndings:
        javascript: ';'
      popupFontSizePx: popupFontSizePx
      popupLineHeightPx: 1.5 * popupFontSizePx
      popupWidthPx: 380

  updateAutocomplete: (@autocomplete) ->
    @zatanna?.set 'snippets', @autocomplete

  addZatannaSnippets: (e) ->
    # Snippet entry format:
    # content: code inserted into document
    # meta: displayed right-justfied in popup
    # name: displayed left-justified in popup, and what's being matched
    # tabTrigger: fallback for name field
    return unless @zatanna and @autocomplete
    snippetEntries = []
    haveFindNearestEnemy = false
    haveFindNearest = false
    for group, props of e.propGroups
      for prop in props
        if _.isString prop  # organizePalette
          owner = group
        else                # organizePaletteHero
          owner = prop.owner
          prop = prop.prop
        doc = _.find (e.allDocs['__' + prop] ? []), (doc) ->
          return true if doc.owner is owner
          return (owner is 'this' or owner is 'more') and (not doc.owner? or doc.owner is 'this')
        if doc?.snippets?[e.language]
          content = doc.snippets[e.language].code
          if /loop/.test(content) and @options.level.get 'moveRightLoopSnippet'
            # Replace default loop snippet with an embedded moveRight()
            content = switch e.language
              when 'python' then 'loop:\n    self.moveRight()\n    ${1:}'
              when 'javascript' then 'loop {\n    this.moveRight();\n    ${1:}\n}'
              else content
          entry =
            content: content
            meta: $.i18n.t('keyboard_shortcuts.press_enter', defaultValue: 'press enter')
            name: doc.name
            tabTrigger: doc.snippets[e.language].tab
            importance: doc.autoCompletePriority ? 1.0
          haveFindNearestEnemy ||= doc.name is 'findNearestEnemy'
          haveFindNearest ||= doc.name is 'findNearest'
          if doc.name is 'attack'
            # Postpone this until we know if findNearestEnemy is available
            attackEntry = entry
          else
            snippetEntries.push entry

          if doc.userShouldCaptureReturn
            varName = doc.userShouldCaptureReturn.variableName ? 'result'
            entry.captureReturn = switch e.language
              when 'io' then varName + ' := '
              when 'javascript' then 'var ' + varName + ' = '
              when 'clojure' then '(let [' + varName + ' '
              else varName + ' = '

    # TODO: Generalize this snippet replacement
    # TODO: Where should this logic live, and what format should it be in?
    if attackEntry?
      unless haveFindNearestEnemy or haveFindNearest or @options.level.get('slug') is 'known-enemy'
        # No findNearestEnemy, so update attack snippet to string-based target
        # (On Known Enemy, we are introducing enemy2 = "Gert", so we want them to do attack(enemy2).)
        attackEntry.content = attackEntry.content.replace '${1:enemy}', '"${1:Enemy Name}"'
      snippetEntries.push attackEntry

    if haveFindNearest and not haveFindNearestEnemy
      @translateFindNearest()

    # window.zatannaInstance = @zatanna  # For debugging. Make sure to not leave active when committing.
    # window.snippetEntries = snippetEntries
    lang = SpellView.editModes[e.language].substr 'ace/mode/'.length
    @zatanna.addSnippets snippetEntries, lang
    @editorLang = lang

  translateFindNearest: ->
    # If they have advanced glasses but are playing a level which assumes earlier glasses, we'll adjust the sample code to use the more advanced APIs instead.
    oldSource = @getSource()
    if @spell.language is 'clojure'
      newSource = oldSource.replace /\(.findNearestEnemy this\)/g, "(.findNearest this (.findEnemies this))"
      newSource = newSource.replace /\(.findNearestItem this\)/g, "(.findNearest this (.findItems this))"
    else if @spell.language is 'io'
      newSource = oldSource.replace /findNearestEnemy/g, "findNearest(findEnemies)"
      newSource = newSource.replace /findNearestItem/g, "findNearest(findItems)"
    else
      newSource = oldSource.replace /(self:|self.|this.|@)findNearestEnemy\(\)/g, "$1findNearest($1findEnemies())"
      newSource = newSource.replace /(self:|self.|this.|@)findNearestItem\(\)/g, "$1findNearest($1findItems())"
    return if oldSource is newSource
    @spell.originalSource = newSource
    @updateACEText newSource
    _.delay (=> @recompile?()), 1000

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
    @aceSession.setUndoManager(new UndoManager())
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
      @aceSession.setUndoManager(new UndoManager())
      @ace.clearSelection()
    @onAllLoaded()

  onAllLoaded: =>
    @spell.transpile @spell.source
    @spell.loaded = true
    Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
    @eventsSuppressed = false  # Now that the initial change is in, we can start running any changed code
    @createToolbarView()

  createDebugView: ->
    return if @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder']  # We'll turn this on later, maybe, but not yet.
    @debugView = new SpellDebugView ace: @ace, thang: @thang, spell:@spell
    @$el.append @debugView.render().$el.hide()

  createToolbarView: ->
    @toolbarView = new SpellToolbarView ace: @ace
    @$el.append @toolbarView.render().$el

  onMouseOut: (e) ->
    @debugView?.onMouseOut e

  getSource: ->
    @ace.getValue()  # could also do @firepad.getText()

  setThang: (thang) ->
    @focus()
    @lastScreenLineCount = null
    @updateLines()
    return if thang.id is @thang?.id
    @thang = thang
    @spellThang = @spell.thangs[@thang.id]
    @createDebugView() unless @debugView
    @debugView?.thang = @thang
    @toolbarView?.toggleFlow false
    @updateAether false, false
    # @addZatannaSnippets()
    @highlightCurrentLine()

  cast: (preload=false, realTime=false) ->
    Backbone.Mediator.publish 'tome:cast-spell', spell: @spell, thang: @thang, preload: preload, realTime: realTime

  notifySpellChanged: =>
    Backbone.Mediator.publish 'tome:spell-changed', spell: @spell

  notifyEditingEnded: =>
    return if @aceDoc.undergoingFirepadOperation  # from my Firepad ACE adapter
    Backbone.Mediator.publish 'tome:editing-ended', {}

  notifyEditingBegan: =>
    return if @aceDoc.undergoingFirepadOperation  # from my Firepad ACE adapter
    Backbone.Mediator.publish 'tome:editing-began', {}

  updateLines: =>
    # Make sure there are always blank lines for the player to type on, and that the editor resizes to the height of the lines.
    lineCount = @aceDoc.getLength()
    lastLine = @aceDoc.$lines[lineCount - 1]
    if lastLine isnt ''
      cursorPosition = @ace.getCursorPosition()
      wasAtEnd = cursorPosition.row is lineCount - 1 and cursorPosition.column is lastLine.length
      @aceDoc.insertNewLine row: lineCount, column: 0  #lastLine.length
      @ace.navigateLeft(1) if wasAtEnd
      ++lineCount
    screenLineCount = @aceSession.getScreenLength()
    if screenLineCount isnt @lastScreenLineCount
      @lastScreenLineCount = screenLineCount
      lineHeight = @ace.renderer.lineHeight or 20
      tomeHeight = $('#tome-view').innerHeight()
      spellPaletteView = $('#spell-palette-view')
      spellListTabEntryHeight = $('#spell-list-tab-entry-view').outerHeight()
      spellToolbarHeight = $('.spell-toolbar-view').outerHeight()
      @spellPaletteHeight ?= spellPaletteView.outerHeight()  # Remember this until resize, since we change it afterward
      spellPaletteAllowedHeight = Math.min @spellPaletteHeight, tomeHeight / 3
      maxHeight = tomeHeight - spellListTabEntryHeight - spellToolbarHeight - spellPaletteAllowedHeight
      linesAtMaxHeight = Math.floor(maxHeight / lineHeight)
      lines = Math.max 8, Math.min(screenLineCount + 2, linesAtMaxHeight)
      # 2 lines buffer is nice
      @ace.setOptions minLines: lines, maxLines: lines
      # Move spell palette up, slightly overlapping us.
      newTop = 175 + lineHeight * lines
      spellPaletteView.css('top', newTop)
      # Expand it to bottom of tome if too short.
      newHeight = Math.max @spellPaletteHeight, tomeHeight - newTop + 10
      spellPaletteView.css('height', newHeight) if @spellPaletteHeight isnt newHeight

  hideProblemAlert: ->
    Backbone.Mediator.publish 'tome:hide-problem-alert', {}

  onManualCast: (e) ->
    cast = @$el.parent().length
    @recompile cast, e.realTime
    @focus() if cast

  onCodeReload: (e) ->
    return unless e.spell is @spell or not e.spell
    @reloadCode true
    @ace.clearSelection()
    _.delay (=> @ace?.clearSelection()), 500  # Make double sure this gets done (saw some timing issues?)

  reloadCode: (cast=true) ->
    @updateACEText @spell.originalSource
    @lockDefaultCode true
    @recompile cast
    Backbone.Mediator.publish 'tome:spell-loaded', spell: @spell
    @updateLines()

  recompile: (cast=true, realTime=false) ->
    hasChanged = @spell.source isnt @getSource()
    if hasChanged
      @spell.transpile @getSource()
      @updateAether true, false
    if cast  #and (hasChanged or realTime)  # just always cast now
      @cast(false, realTime)
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
      _.debounce @updateAether, 500
      _.debounce @notifyEditingEnded, 1000
      _.throttle @notifyEditingBegan, 250
      _.throttle @notifySpellChanged, 300
      _.throttle @updateLines, 500
      _.throttle @hideProblemAlert, 500
    ]
    onSignificantChange.push _.debounce @checkRequiredCode, 750 if @options.level.get 'requiredCode'
    onSignificantChange.push _.debounce @checkSuspectCode, 750 if @options.level.get 'suspectCode'
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

  updateAether: (force=false, fromCodeChange=true) =>
    # Depending on whether we have any code changes, significant code changes, or have switched
    # to a new spellThang, we may want to refresh our Aether display.
    return unless aether = @spellThang?.aether
    source = @getSource()
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

  clearAetherDisplay: ->
    problem.destroy() for problem in @problems
    @problems = []
    @aceSession.setAnnotations []
    @highlightCurrentLine {}  # This'll remove all highlights

  displayAether: (aether, isCast=false) ->
    @displayedAether = aether
    isCast = isCast or not _.isEmpty(aether.metrics) or _.some aether.getAllProblems(), {type: 'runtime'}
    problem.destroy() for problem in @problems  # Just in case another problem was added since clearAetherDisplay() ran.
    @problems = []
    annotations = []
    seenProblemKeys = {}
    for aetherProblem, problemIndex in aether.getAllProblems()
      continue if key = aetherProblem.userInfo?.key and key of seenProblemKeys
      seenProblemKeys[key] = true if key
      @problems.push problem = new Problem aether, aetherProblem, @ace, isCast, @spell.levelID
      if isCast and problemIndex is 0
        if problem.aetherProblem.range?
          lineOffsetPx = 0
          for i in [0...problem.aetherProblem.range[0].row]
            lineOffsetPx += @aceSession.getRowLength(i) * @ace.renderer.lineHeight
          lineOffsetPx -= @ace.session.getScrollTop()
        Backbone.Mediator.publish 'tome:show-problem-alert', problem: problem, lineOffsetPx: Math.max lineOffsetPx, 0
      @saveUserCodeProblem(aether, aetherProblem) if isCast
      annotations.push problem.annotation if problem.annotation
    @aceSession.setAnnotations annotations
    @highlightCurrentLine aether.flow unless _.isEmpty aether.flow
    #console.log '  and we could do the metrics', aether.metrics unless _.isEmpty aether.metrics
    #console.log '  and we could do the style', aether.style unless _.isEmpty aether.style
    #console.log '  and we could do the visualization', aether.visualization unless _.isEmpty aether.visualization
    # Could use the user-code-problem style... or we could leave that to other places.
    @ace[if @problems.length then 'setStyle' else 'unsetStyle'] 'user-code-problem'
    @ace[if isCast then 'setStyle' else 'unsetStyle'] 'spell-cast'
    Backbone.Mediator.publish 'tome:problems-updated', spell: @spell, problems: @problems, isCast: isCast
    @ace.resize()

  saveUserCodeProblem: (aether, aetherProblem) ->
    # Skip duplicate problems
    hashValue = aether.raw + aetherProblem.message
    return if hashValue of @savedProblems
    @savedProblems[hashValue] = true

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
    @userCodeProblem.set 'levelID', @spell.levelID if @spell.levelID
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
    cursorPosition = @ace.getCursorPosition()
    currentLine = _.string.rtrim(@aceDoc.$lines[cursorPosition.row].replace(@singleLineCommentRegex(), ''))  # trim // unless inside "
    endOfLine = cursorPosition.column >= currentLine.length  # just typed a semicolon or brace, for example
    beginningOfLine = not currentLine.substr(0, cursorPosition.column).trim().length  # uncommenting code, for example
    incompleteThis = /^(s|se|sel|self|t|th|thi|this)$/.test currentLine.trim()
    #console.log "finished=#{valid and (endOfLine or beginningOfLine) and not incompleteThis}", valid, endOfLine, beginningOfLine, incompleteThis, cursorPosition, currentLine.length, aether, new Date() - 0, currentLine
    if valid and (endOfLine or beginningOfLine) and not incompleteThis
      @preload()

  singleLineCommentRegex: ->
    if @_singleLineCommentRegex
      @_singleLineCommentRegex.lastIndex = 0
      return @_singleLineCommentRegex
    commentStart = commentStarts[@spell.language] or '//'
    @_singleLineCommentRegex = new RegExp "[ \t]*#{commentStart}[^\"'\n]*", 'g'
    @_singleLineCommentRegex

  lineWithCodeRegex: ->
    if @_lineWithCodeRegex
      @_lineWithCodeRegex.lastIndex = 0
      return @_lineWithCodeRegex
    commentStart = commentStarts[@spell.language] or '//'
    @_lineWithCodeRegex = new RegExp "^[ \t]*(?!( |]t|#{commentStart}))+", 'g'
    @_lineWithCodeRegex

  commentOutMyCode: ->
    prefix = if @spell.language is 'javascript' then 'return;  ' else 'return  '
    comment = prefix + commentStarts[@spell.language]

  preload: ->
    # Send this code over to the God for preloading, but don't change the cast state.
    #console.log 'preload?', @spell.source.indexOf('while'), @spell.source.length, @spellThang?.castAether?.metrics?.statementsExecuted
    return if @spell.source.indexOf('while') isnt -1  # If they're working with while-loops, it's more likely to be an incomplete infinite loop, so don't preload.
    return if @spell.source.length > 500  # Only preload on really short methods
    return if @spellThang?.castAether?.metrics?.statementsExecuted > 2000  # Don't preload if they are running significant amounts of user code
    oldSource = @spell.source
    oldSpellThangAethers = {}
    for thangID, spellThang of @spell.thangs
      oldSpellThangAethers[thangID] = spellThang.aether.serialize()  # Get raw, pure, and problems
    @spell.transpile @getSource()
    @cast true
    @spell.source = oldSource
    for thangID, spellThang of @spell.thangs
      for key, value of oldSpellThangAethers[thangID]
        spellThang.aether[key] = value

  onSpellChanged: (e) ->
    @spellHasChanged = true

  onSessionWillSave: (e) ->
    return unless @spellHasChanged
    setTimeout(=>
      unless @destroyed or @spellHasChanged
        @$el.find('.save-status').finish().show().fadeOut(2000)
    , 1000)
    @spellHasChanged = false

  onUserCodeProblem: (e) ->
    return @onInfiniteLoop e if e.problem.id is 'runtime_InfiniteLoop'
    return unless e.problem.userInfo.methodName is @spell.name
    return unless spellThang = _.find @spell.thangs, (spellThang, thangID) -> thangID is e.problem.userInfo.thangID
    @spell.hasChangedSignificantly @getSource(), null, (hasChanged) =>
      return if hasChanged
      spellThang.aether.addProblem e.problem
      @lastUpdatedAetherSpellThang = null  # force a refresh without a re-transpile
      @updateAether false, false

  onNonUserCodeProblem: (e) ->
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
    @spell.removeThangID thangID for thangID of @spell.thangs when not e.world.getThangByID thangID
    for thangID, spellThang of @spell.thangs
      thang = e.world.getThangByID(thangID)
      aether = e.world.userCodeMap[thangID]?[@spell.name]  # Might not be there if this is a new Programmable Thang.
      spellThang.castAether = aether
      spellThang.aether = @spell.createAether thang
    #console.log thangID, @spell.spellKey, 'ran', aether.metrics.callsExecuted, 'times over', aether.metrics.statementsExecuted, 'statements, with max recursion depth', aether.metrics.maxDepth, 'and full flow/metrics', aether.metrics, aether.flow
    @spell.transpile()  # TODO: is there any way we can avoid doing this if it hasn't changed? Causes a slight hang.
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
    else if @spell.language is 'clojure'
      @ace.insert "{:x #{e.x} :y #{e.y}}"
    else if @spell.language is 'lua'
      @ace.insert "{x=#{e.x}, y=#{e.y}}"
    else if @spell.language is 'io'
      return
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

      lineHasComment = @singleLineCommentRegex().test line
      lineHasCode = line.trim()[0] and not _.string.startsWith line.trim(), commentStart
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
    # used in spell_list_entry.sass for disabling
    background = @$el.find('img.code-background')[0]
    if background.naturalWidth is 0  # not loaded yet
      return _.delay @toggleBackground, 100
    filters.revertImage background, 'span.code-background' if @controlsEnabled
    filters.darkenImage background, 'span.code-background', 0.8 unless @controlsEnabled

  onSpellBeautify: (e) ->
    return unless @spellThang and (@ace.isFocused() or e.spell is @spell)
    ugly = @getSource()
    pretty = @spellThang.aether.beautify ugly
    @ace.setValue pretty

  onMaximizeToggled: (e) ->
    _.delay (=> @resize()), 500 + 100  # Wait $level-resize-transition-time, plus a bit.

  onWindowResize: (e) =>
    @spellPaletteHeight = null
    $('#spell-palette-view').css 'height', 'auto'  # Let it go back to controlling its own height
    _.delay (=> @resize?()), 500 + 100  # Wait $level-resize-transition-time, plus a bit.

  resize: ->
    @ace?.resize true
    @lastScreenLineCount = null
    @updateLines()

  onChangeEditorConfig: (e) ->
    aceConfig = me.get('aceConfig') ? {}
    @ace.setDisplayIndentGuides aceConfig.indentGuides # default false
    @ace.setShowInvisibles aceConfig.invisibles # default false
    @ace.setKeyboardHandler @keyBindings[aceConfig.keyBindings ? 'default']
    @updateAutocomplete(aceConfig.liveCompletion ? false)

  onChangeLanguage: (e) ->
    return unless @spell.canWrite()
    @aceSession.setMode SpellView.editModes[e.language]
    @zatanna?.set 'language', SpellView.editModes[e.language].substr('ace/mode/')
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
    @toolbarView?.destroy()
    @zatanna.addSnippets [], @editorLang if @editorLang?
    $(window).off 'resize', @onWindowResize
    super()

commentStarts =
  javascript: '//'
  python: '#'
  coffeescript: '#'
  clojure: ';'
  lua: '--'
  io: '//'
