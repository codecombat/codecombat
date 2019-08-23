aceUtils = require 'core/aceUtils'
ace = require('lib/aceContainer')

defaults =
  autoLineEndings:
    # Mapping ace mode language to line endings to automatically insert
    # E.g. javascript: ";"
    {}
  basic: true
  snippetsLangDefaults: true
  liveCompletion: true
  language: 'javascript'
  languagePrefixes: 'this.,@,self.'
  completers:
    snippets: true



# TODO: Should we be hooking in completers differently?
# TODO: https://github.com/ajaxorg/ace/blob/f133231df8c1f39156cc230ce31e66103ef4b1e2/lib/ace/ext/language_tools.js#L202

# TODO: Should show popup if we have a snippet match in Autocomplete.filterCompletions
# TODO: https://github.com/ajaxorg/ace/blob/695e24c41844c17fb2029f073d06338cd73ec33e/lib/ace/autocomplete.js#L449

# TODO: Create list of manual test cases

module.exports = class Autocomplete
  Tokenizer = ''
  BackgroundTokenizer = ''

  constructor: (aceEditor, options) ->
    {Tokenizer} = ace.require 'ace/tokenizer'
    {BackgroundTokenizer} = ace.require 'ace/background_tokenizer'

    @editor = aceEditor
    config = ace.require 'ace/config'

    options ?= {}

    defaultsCopy = _.extend {}, defaults
    @options = _.merge defaultsCopy, options


    #TODO: Renable option validation if we care
    #validationResult = optionsValidator @options
    #unless validationResult.valid
    #  throw new Error "Invalid Autocomplete options: " + JSON.stringify(validationResult.errors, null, 4)

    ace.config.loadModule 'ace/ext/language_tools', () =>
      @snippetManager = ace.require('ace/snippets').snippetManager

      # Prevent tabbing a selection trigging an incorrect autocomplete
      # E.g. Given this.moveRight() selecting ".moveRight" from left to right and hitting tab yields this.this.moveRight()()
      # TODO: Figure out how to intercept this properly
      # TODO: Or, override expandSnippet command
      # TODO: Or, SnippetManager's expandSnippetForSelection
      @snippetManager.expandWithTab = -> return false

      # Define a background tokenizer that constantly tokenizes the code
      highlightRules = new (@editor.getSession().getMode().HighlightRules)()
      tokenizer = new Tokenizer highlightRules.getRules()
      @bgTokenizer = new BackgroundTokenizer tokenizer, @editor
      aceDocument = @editor.getSession().getDocument()
      @bgTokenizer.setDocument aceDocument
      @bgTokenizer.start(0)

      @setAceOptions()
      @copyCompleters()
      @activateCompleter()
      @editor.commands.on 'afterExec', @doLiveCompletion

  setAceOptions: () ->
    aceOptions =
      'enableLiveAutocompletion': @options.liveCompletion
      'enableBasicAutocompletion': @options.basic
      'enableSnippets': @options.completers.snippets

    @editor.setOptions aceOptions
    @editor.completer?.autoSelect = true

  copyCompleters: () ->
    @completers = {snippets: {}, text: {}, keywords: {}}
    if @editor.completers?
      [@completers.snippets.comp, @completers.text.comp, @completers.keywords.comp] = @editor.completers
    if @options.completers.snippets
      @completers.snippets = pos: 0
      # Replace the default snippet completer with our custom one
      @completers.snippets.comp = require('./snippets') @snippetManager, @options.autoLineEndings

  activateCompleter: (comp) ->
    if Array.isArray comp
      @editor.completers = comp
    else if typeof comp is 'string'
      if @completers[comp]? and @editor.completers[@completers[comp].pos] isnt @completers[comp].comp
        @editor.completers.splice(@completers[comp].pos, 0, @completers[comp].comp)
    else
      @editor.completers = []
      for type, comparator of @completers
        if @options.completers[type] is true
          @activateCompleter type

  addSnippets: (snippets, language) ->
    @options.language = language
    ace.config.loadModule 'ace/ext/language_tools', () =>
      @snippetManager = ace.require('ace/snippets').snippetManager
      snippetModulePath = 'ace/snippets/' + language
      ace.config.loadModule snippetModulePath, (m) =>
        if m?
          @snippetManager.files[language] = m
          @snippetManager.unregister m.snippets if m.snippets?.length > 0
          @snippetManager.unregister @oldSnippets if @oldSnippets?
          m.snippets = if @options.snippetsLangDefaults then @snippetManager.parseSnippetFile m.snippetText else []
          m.snippets.push s for s in snippets
          @snippetManager.register m.snippets
          @oldSnippets = m.snippets

  setLiveCompletion: (val) ->
    if val is true or val is false
      @options.liveCompletion = val
      @setAceOptions()

  set: (setting, value) ->
    switch setting
      when 'snippets' or 'completers.snippets'
        return unless typeof value is 'boolean'
        @options.completers.snippets = value
        @setAceOptions()
        @activateCompleter 'snippets'
      when 'basic'
        return unless typeof value is 'boolean'
        @options.basic = value
        @setAceOptions()
        @activateCompleter()
      when 'liveCompletion'
        return unless typeof value is 'boolean'
        @options.liveCompletion = value
        @setAceOptions()
        @activateCompleter()
      when 'language'
        return unless typeof value is 'string'
        @options.language = value
        @setAceOptions()
        @activateCompleter()
      when 'completers.keywords'
        return unless typeof value is 'boolean'
        @options.completers.keywords = value
        @activateCompleter()
      when 'completers.text'
        return unless typeof value is 'boolean'
        @options.completers.text = value
        @activateCompleter()
    return

  on: -> @paused = false
  off: -> @paused = true

  doLiveCompletion: (e) =>
    # console.log 'Autocomplete doLiveCompletion', e
    return unless @options.basic or @options.liveCompletion or @options.completers.snippets
    return if @paused

    TokenIterator = TokenIterator or ace.require('ace/token_iterator').TokenIterator
    editor = e.editor
    text = e.args or ""
    hasCompleter = editor.completer and editor.completer.activated

    # We don't want to autocomplete with no prefix
    if e.command.name is "backspace" or e.command.name is "insertstring"
      pos = editor.getCursorPosition()
      token = (new TokenIterator editor.getSession(), pos.row, pos.column).getCurrentToken()
      if token? and token.type not in ['comment', 'string']
        prefix = @getCompletionPrefix editor
        # Bake a fresh autocomplete every keystroke
        editor.completer?.detach() if hasCompleter

        # Skip common single letter variable names
        return if /^x$|^y$/i.test(prefix)

        # Only autocomplete if there's a prefix that can be matched
        if (prefix)
          unless (editor.completer)

            # Create new autocompleter
            Autocomplete = ace.require('ace/autocomplete').Autocomplete

            # Overwrite "Shift-Return" to Esc + Return instead
            # https://github.com/ajaxorg/ace/blob/695e24c41844c17fb2029f073d06338cd73ec33e/lib/ace/autocomplete.js#L208
            # TODO: Need a better way to update this command.  This is super shady.
            # TODO: Shift-Return errors when Autocomplete is open, dying on this call:
            # TODO: calls editor.completer.insertMatch(true) in lib/ace/autocomplete.js
            if Autocomplete?.prototype?.commands?
              exitAndReturn = (editor) =>
                # TODO: Execute a proper Return that selects the Autocomplete if open
                editor.completer.detach()
                @editor.insert "\n"
              Autocomplete.prototype.commands["Shift-Return"] = exitAndReturn

            editor.completer = new Autocomplete()

          # Disable autoInsert and show popup
          editor.completer.autoSelect = true
          editor.completer.autoInsert = false
          editor.completer.showPopup(editor)

          # Hide popup if too many suggestions
          # TODO: Completions aren't asked for unless we show popup, so this is super hacky
          # TODO: Backspacing to yield more suggestions does not close popup
          if editor.completer?.completions?.filtered?.length > 20
            editor.completer.detach()

          # Update popup CSS after it's been launched
          # TODO: Popup has original CSS on first load, and then visibly/weirdly changes based on these updates
          # TODO: Find better way to extend popup.
          else if editor.completer.popup?
            $('.ace_autocomplete').find('.ace_content').css('cursor', 'pointer')
            $('.ace_autocomplete').css('font-size', @options.popupFontSizePx + 'px') if @options.popupFontSizePx?
            $('.ace_autocomplete').css('line-height', @options.popupLineHeightPx + 'px') if @options.popupLineHeightPx?
            $('.ace_autocomplete').css('width', @options.popupWidthPx + 'px') if @options.popupWidthPx?
            editor.completer.popup.resize?()

            # TODO: Can't change padding before resize(), but changing it afterwards clears new padding
            # TODO: Figure out how to hook into events rather than using setTimeout()
            # fixStuff = =>
            #   $('.ace_autocomplete').find('.ace_line').css('color', 'purple')
            #   $('.ace_autocomplete').find('.ace_line').css('padding', '20px')
            #   # editor.completer.popup.resize?(true)
            # setTimeout fixStuff, 1000

    # Update tokens for text completer
    if @options.completers.text and e.command.name in ['backspace', 'del', 'insertstring', 'removetolinestart', 'Enter', 'Return', 'Space', 'Tab']
      @bgTokenizer.fireUpdateEvent 0, @editor.getSession().getLength()

  getCompletionPrefix: (editor) ->
    # TODO: this is not used to get prefix that is passed to completer.getCompletions
    # TODO: Autocomplete.gatherCompletions is using this (no regex 3rd param):
    # TODO: var prefix = util.retrievePrecedingIdentifier(line, pos.column);
    util = util or ace.require 'ace/autocomplete/util'
    pos = editor.getCursorPosition()
    line = editor.session.getLine pos.row
    prefix = null
    editor.completers?.forEach (completer) ->
      if completer?.identifierRegexps
        completer.identifierRegexps.forEach (identifierRegex) ->
          if not prefix and identifierRegex
            prefix = util.retrievePrecedingIdentifier line, pos.column, identifierRegex
    prefix = util.retrievePrecedingIdentifier line, pos.column unless prefix?
    prefix

  addCodeCombatSnippets: (level, spellView, e) ->
    snippetEntries = []
    source = spellView.getSource()
    haveFindNearestEnemy = false
    haveFindNearest = false
    autocompleteReplacement = level.get("autocompleteReplacement") ? []
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
          name = doc.name
          replacement = _.find(autocompleteReplacement, (el) -> el.name is name)
          content = replacement?.snippets?[e.language]?.code or doc.snippets[e.language].code
          if /loop/.test(content) and level.get 'moveRightLoopSnippet'
            # Replace default loop snippet with an embedded moveRight()
            content = switch e.language
              when 'python' then 'loop:\n    self.moveRight()\n    ${1:}'
              when 'javascript' then 'loop {\n    this.moveRight();\n    ${1:}\n}'
              else content
          if /loop/.test(content) and level.isType('course', 'course-ladder')
            # Temporary hackery to make it look like we meant while True: in our loop snippets until we can update everything
            content = switch e.language
              when 'python' then content.replace /loop:/, 'while True:'
              when 'javascript' then content.replace /loop/, 'while (true)'
              when 'lua' then content.replace /loop/, 'while true then'
              when 'coffeescript' then content
              else content
            name = switch e.language
              when 'python' then 'while True'
              when 'coffeescript' then 'loop'
              else 'while true'
          # For now, update autocomplete to use hero instead of self/this, if hero is already used in the source.
          # Later, we should make this happen all the time - or better yet update the snippets.
          if /hero/.test(source) or not /(self[\.\:]|this\.|\@)/.test(source)
            thisToken =
              'python': /self/,
              'javascript': /this/,
              'lua': /self/
            if thisToken[e.language] and thisToken[e.language].test(content)
              content = content.replace thisToken[e.language], 'hero'

          entry =
            content: content
            meta: $.i18n.t('keyboard_shortcuts.press_enter', defaultValue: 'press enter')
            name: name
            tabTrigger: doc.snippets[e.language].tab
            importance: doc.autoCompletePriority ? 1.0
          haveFindNearestEnemy ||= name is 'findNearestEnemy'
          haveFindNearest ||= name is 'findNearest'
          if name is 'attack'
            # Postpone this until we know if findNearestEnemy is available
            attackEntry = entry
          else
            snippetEntries.push entry

          if doc.userShouldCaptureReturn
            varName = doc.userShouldCaptureReturn.variableName ? 'result'
            entry.captureReturn = switch e.language
              when 'javascript' then 'var ' + varName + ' = '
              #when 'lua' then 'local ' + varName + ' = '  # TODO: should we do this?
              else varName + ' = '

    # TODO: Generalize this snippet replacement
    # TODO: Where should this logic live, and what format should it be in?
    if attackEntry?
      unless haveFindNearestEnemy or haveFindNearest or level.get('slug') in ['known-enemy', 'course-known-enemy']
        # No findNearestEnemy, so update attack snippet to string-based target
        # (On Known Enemy, we are introducing enemy2 = "Gert", so we want them to do attack(enemy2).)
        attackEntry.content = attackEntry.content.replace '${1:enemy}', '"${1:Enemy Name}"'
      snippetEntries.push attackEntry

    # Update 'hero.' and 'game.' entries to include their prefixes
    for entry in snippetEntries
      if entry.content?.indexOf('hero.') is 0 and entry.name?.indexOf('hero.') < 0
        entry.name = "hero.#{entry.name}"
      else if entry.content?.indexOf('game.') is 0 and entry.name?.indexOf('game.') < 0
        entry.name = "game.#{entry.name}"

    if haveFindNearest and not haveFindNearestEnemy
      spellView.translateFindNearest()

    # window.AutocompleteInstance = @Autocomplete  # For debugging. Make sure to not leave active when committing.
    # window.snippetEntries = snippetEntries
    lang = aceUtils.aceEditModes[e.language].substr 'ace/mode/'.length
    @addSnippets snippetEntries, lang
    spellView.editorLang = lang
