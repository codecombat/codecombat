popoverTemplate = require 'templates/play/level/tome/spell_palette_entry_popover'
{downTheChain} = require 'lib/world/world_utils'
window.Vector = require 'lib/world/vector'  # So we can document it
utils = require 'core/utils'

safeJSONStringify = (input, maxDepth) ->
  recursion = (input, path, depth) ->
    output = {}
    pPath = undefined
    refIdx = undefined
    path = path or ''
    depth = depth or 0
    depth++
    return '{depth over ' + maxDepth + '}' if maxDepth and depth > maxDepth
    for p of input
      pPath = ((if path then (path + '.') else '')) + p
      if typeof input[p] is 'function'
        output[p] = '{function}'
      else if typeof input[p] is 'object'
        refIdx = refs.indexOf(input[p])
        if -1 isnt refIdx
          output[p] = '{reference to ' + refsPaths[refIdx] + '}'
        else
          refs.push input[p]
          refsPaths.push pPath
          output[p] = recursion(input[p], pPath, depth)
      else
        output[p] = input[p]
    output
  refs = []
  refsPaths = []
  maxDepth = maxDepth or 5
  if typeof input is 'object'
    output = recursion(input)
  else
    output = input
  JSON.stringify output, null, 1

module.exports = class DocFormatter
  constructor: (@options) ->
    @doc = _.cloneDeep @options.doc
    @fillOutDoc()

  fillOutDoc: ->
    # TODO: figure out better ways to format html/css/scripting docs for web-dev levels
    if _.isString @doc
      @doc = name: @doc, type: typeof @options.thang[@doc]
    if @options.isSnippet
      @doc.type = 'snippet'
      @doc.owner = 'snippets'
      @doc.shortName = @doc.shorterName = @doc.title = @doc.name
    else if @doc.owner in ['HTML', 'CSS', 'WebJavaScript', 'jQuery']
      @doc.shortName = @doc.shorterName = @doc.title = @doc.name
    else
      @doc.owner ?= 'this'
      ownerName = @doc.ownerName = if @doc.owner isnt 'this' then @doc.owner else switch @options.language
        when 'python', 'lua' then (if @options.useHero then 'hero' else 'self')
        when 'java' then 'hero'
        when 'coffeescript' then '@'
        else (if @options.useHero then 'hero' else 'this')
      ownerName = 'game' if @options.level.isType('game-dev')
      if @doc.type is 'function'
        [docName, args] = @getDocNameAndArguments()
        argNames = args.join ', '
        argString = if argNames then '__ARGS__' else ''
        @doc.shortName = switch @options.language
          when 'coffeescript' then "#{ownerName}#{if ownerName is '@' then '' else '.'}#{docName}#{if argString then ' ' + argString else '()'}"
          when 'python' then "#{ownerName}.#{docName}(#{argString})"
          when 'lua' then "#{ownerName}:#{docName}(#{argString})"
          else "#{ownerName}.#{docName}(#{argString});"
      else
        @doc.shortName = switch @options.language
          when 'coffeescript' then "#{ownerName}#{if ownerName is '@' then '' else '.'}#{@doc.name}"
          when 'python' then "#{ownerName}.#{@doc.name}"
          when 'lua' then "#{ownerName}.#{@doc.name}"
          else "#{ownerName}.#{@doc.name};"
      @doc.shorterName = @doc.shortName
      if @doc.type is 'function' and argString
        @doc.shortName = @doc.shorterName.replace argString, argNames
        @doc.shorterName = @doc.shorterName.replace argString, (if not /cast[A-Z]/.test(@doc.name) and argNames.length > 6 then '...' else argNames)
      if @options.language is 'javascript'
        @doc.shorterName = @doc.shortName.replace ';', ''
        if @doc.owner is 'this' or @options.tabbify or ownerName is 'game'
          @doc.shorterName = @doc.shorterName.replace /^(this|hero)\./, ''
      else if (@options.language in ['python', 'lua']) and (@doc.owner is 'this' or @options.tabbify or ownerName is 'game')
        @doc.shorterName = @doc.shortName.replace /^(self|hero|game)[:.]/, ''
      @doc.title = if @options.shortenize then @doc.shorterName else @doc.shortName
      translatedName = utils.i18n(@doc, 'name')
      if translatedName isnt @doc.name
        @doc.translatedShortName = @doc.shortName.replace(@doc.name, translatedName)


    # Grab the language-specific documentation for some sub-properties, if we have it.
    toTranslate = [{obj: @doc, prop: 'description'}, {obj: @doc, prop: 'example'}]
    for arg in (@doc.args ? [])
      toTranslate.push {obj: arg, prop: 'example'}, {obj: arg, prop: 'description'}
    if @doc.returns
      toTranslate.push {obj: @doc.returns, prop: 'example'}, {obj: @doc.returns, prop: 'description'}
    for {obj, prop} in toTranslate
      # Translate into chosen code language.
      if val = obj[prop]?[@options.language]
        obj[prop] = val
      else unless _.isString obj[prop]
        obj[prop] = null

      # Translate into chosen spoken language.
      if val = originalVal = obj[prop]
        context = @doc.context
        obj[prop] = val = utils.i18n obj, prop
        # For multiplexed-by-both-code-and-spoken-language objects, now also get code language again.
        if _.isObject(val)
          if valByCodeLanguage = obj[prop]?[@options.language]
            obj[prop] = val = valByCodeLanguage
          else
            obj[prop] = originalVal  # Never mind, we don't have that code language for that spoken language.
        if @doc.i18n
          spokenLanguage = me.get 'preferredLanguage'
          while spokenLanguage
            spokenLanguage = spokenLanguage.substr 0, spokenLanguage.lastIndexOf('-') if fallingBack?
            if spokenLanguageContext = @doc.i18n[spokenLanguage]?.context
              context = _.merge context, spokenLanguageContext
              break
            fallingBack = true
        if context
          try
            obj[prop] = _.template val, context
          catch e
            console.error "Couldn't create docs template of", val, "\nwith context", context, "\nError:", e
        obj[prop] = @replaceSpriteName obj[prop]  # Do this before using the template, otherwise marked might get us first.

    # Temporary hack to replace self|this with hero until we can update the docs
    if @options.useHero
      thisToken =
        'python': /self/g,
        'javascript': /this/g,
        'lua': /self/g

      if thisToken[@options.language]
        if @doc.example
          @doc.example = @doc.example.replace thisToken[@options.language], 'hero'
        if @doc.snippets?[@options.language]?.code
          @doc.snippets[@options.language].code.replace thisToken[@options.language], 'hero'
        if @doc.args
          arg.example = arg.example.replace thisToken[@options.language], 'hero' for arg in @doc.args when arg.example

    if @doc.shortName is 'loop' and @options.level.isType('course', 'course-ladder')
      @replaceSimpleLoops()

  replaceSimpleLoops: ->
    # Temporary hackery to make it look like we meant while True: in our loop: docs until we can update everything
    @doc.shortName = @doc.shorterName = @doc.title = @doc.name = switch @options.language
      when 'coffeescript' then "loop"
      when 'python' then "while True:"
      when 'lua' then "while true do"
      else "while (true)"
    for field in ['example', 'description']
      [simpleLoop, whileLoop] = switch @options.language
        when 'coffeescript' then [/loop/g, "loop"]
        when 'python' then [/loop:/g, "while True:"]
        when 'lua' then [/loop/g, "while true do"]
        else [/loop/g, "while (true)"]
      @doc[field] = @doc[field].replace simpleLoop, whileLoop

  formatPopover: ->
    [docName, args] = @getDocNameAndArguments()
    argumentExamples = (arg.example or arg.default or arg.name for arg in @doc.args ? [])
    argumentExamples.unshift args[0] if args.length > argumentExamples.length
    content = popoverTemplate {
      doc: @doc
      docName: docName
      language: @options.language
      value: @formatValue()
      marked: marked
      argumentExamples: argumentExamples
      writable: @options.writable
      selectedMethod: @options.selectedMethod
      cooldowns: @inferCooldowns()
      item: @options.item
      _: _
    }
    owner = if @doc.owner is 'this' then @options.thang else window[@doc.owner]
    content = @replaceSpriteName content
    content = content.replace /\#\{(.*?)\}/g, (s, properties) => @formatValue downTheChain(owner, properties.split('.'))
    content = content.replace /{([a-z]+)}([^]*?){\/\1}/g, (s, language, text) =>
      if language is @options.language then return text
      return ''

  replaceSpriteName: (s) ->
    # Prefer type, and excluded the quotes we'd get with @formatValue
    name = @options.thang.type ? @options.thang.spriteName
    name = 'hero' if /Hero Placeholder/.test @options.thang.id
    s.replace /#{spriteName}/g, name

  getDocNameAndArguments: ->
    return [@doc.name, []] unless @doc.type is 'function'
    docName = @doc.name
    args = (arg.name for arg in @doc.args ? [])
    if /cast[A-Z]/.test docName
      docName = 'cast'
      args.unshift '"' + _.string.dasherize(@doc.name).replace('cast-', '') + '"'
    [docName, args]

  formatValue: (v) ->
    return null if @options.level.isType('web-dev')
    return null if @doc.type is 'snippet'
    return @options.thang.now() if @doc.name is 'now'
    return '[Function]' if not v and @doc.type is 'function'
    unless v?
      if @doc.owner is 'this'
        v = @options.thang[@doc.name]
      else
        v = window[@doc.owner][@doc.name]  # grab Math or Vector
    if @doc.type is 'number' and not _.isNaN v
      if v is Math.round v
        return v
      if _.isNumber v
        return v.toFixed 2
      unless v
        return 'null'
      return '' + v
    if _.isString v
      return "\"#{v}\""
    if v?.id
      return v.id
    if v?.name
      return v.name
    if _.isArray v
      return '[' + (@formatValue v2 for v2 in v).join(', ') + ']'
    if _.isPlainObject v
      return safeJSONStringify v, 2
    v

  inferCooldowns: ->
    return null unless @doc.type is 'function' and @doc.owner is 'this'
    owner = @options.thang
    cooldowns = null
    spellName = @doc.name.match /^cast(.+)$/
    if spellName
      actionName = _.string.slugify _.string.underscored spellName[1]
      action = owner.spells?[actionName]
      type = 'spell'
    else
      actionName = _.string.slugify _.string.underscored @doc.name
      action = owner.actions?[actionName]
      type = 'action'
    return null unless action
    cooldowns = cooldown: action.cooldown, specificCooldown: action.specificCooldown, name: actionName, type: type
    for prop in ['range', 'radius', 'duration', 'damage']
      v = owner[_.string.camelize actionName + _.string.capitalize(prop)]
      continue if prop is 'range' and v <= 5  # Don't confuse players by showing melee ranges, they will inappropriately use distanceTo(enemy) < 3.
      cooldowns[prop] = v
      if _.isNumber(v) and v isnt Math.round v
        cooldowns[prop] = v.toFixed 2
    cooldowns
