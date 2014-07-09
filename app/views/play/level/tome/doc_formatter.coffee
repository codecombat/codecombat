popoverTemplate = require 'templates/play/level/tome/spell_palette_entry_popover'
{downTheChain} = require 'lib/world/world_utils'
window.Vector = require 'lib/world/vector'  # So we can document it

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
    @doc = _.cloneDeep options.doc
    @fillOutDoc()

  fillOutDoc: ->
    if _.isString @doc
      @doc = name: @doc, type: typeof @options.thang[@doc]
    if @options.isSnippet
      @doc.type = 'snippet'
      @doc.owner = 'snippets'
      @doc.shortName = @doc.shorterName = @doc.title = @doc.name
    else
      @doc.owner ?= 'this'
      ownerName = @doc.ownerName = if @doc.owner isnt 'this' then @doc.owner else switch @options.language
        when 'python', 'lua' then 'self'
        when 'coffeescript' then '@'
        else 'this'
      if @doc.type is 'function'
        sep = {clojure: ' '}[@options.language] ? ', '
        argNames = (arg.name for arg in @doc.args ? []).join sep
        argString = if argNames then '__ARGS__' else ''
        @doc.shortName = switch @options.language
          when 'coffeescript' then "#{ownerName}#{if ownerName is '@' then '' else '.'}#{@doc.name}#{if argString then ' ' + argString else '()'}"
          when 'python' then "#{ownerName}.#{@doc.name}(#{argString})"
          when 'lua' then "#{ownerName}:#{@doc.name}(#{argString})"
          when 'clojure' then "(.#{@doc.name} #{ownerName}#{if argNames then ' ' + argString else ''})"
          when 'io' then "#{if ownerName is 'this' then '' else ownerName + ' '}#{@doc.name}#{if argNames then '(' + argNames + ')' else ''}"
          else "#{ownerName}.#{@doc.name}(#{argString});"
      else
        @doc.shortName = switch @options.language
          when 'coffeescript' then "#{ownerName}#{if ownerName is '@' then '' else '.'}#{@doc.name}"
          when 'python' then "#{ownerName}.#{@doc.name}"
          when 'lua' then "#{ownerName}.#{@doc.name}"
          when 'clojure' then "(.#{@doc.name} #{ownerName})"
          when 'io' then "#{if ownerName is 'this' then '' else ownerName + ' '}#{@doc.name}"
          else "#{ownerName}.#{@doc.name};"
      @doc.shorterName = @doc.shortName
      if @doc.type is 'function' and argString
        @doc.shortName = @doc.shorterName.replace argString, argNames
        @doc.shorterName = @doc.shorterName.replace argString, (if argNames.length > 6 then '...' else argNames)
      if @options.language is 'javascript'
        @doc.shorterName = @doc.shortName.replace ';', ''
        if @doc.owner is 'this' or @options.tabbify
          @doc.shorterName = @doc.shorterName.replace /^this\./, ''
      @doc.title = if @options.shortenize then @doc.shorterName else @doc.shortName

    # Grab the language-specific documentation for some sub-properties, if we have it.
    toTranslate = [{obj: @doc, prop: 'example'}, {obj: @doc, prop: 'returns'}]
    for arg in (@doc.args ? [])
      toTranslate.push {obj: arg, prop: 'example'}, {obj: arg, prop: 'description'}
    for {obj, prop} in toTranslate
      if val = obj[prop]?[@options.language]
        obj[prop] = val
      else unless _.isString obj[prop]
        obj[prop] = null

  formatPopover: ->
    content = popoverTemplate doc: @doc, language: @options.language, value: @formatValue(), marked: marked, argumentExamples: (arg.example or arg.default or arg.name for arg in @doc.args ? [])
    owner = if @doc.owner is 'this' then @options.thang else window[@doc.owner]
    content = content.replace /#{spriteName}/g, @options.thang.type ? @options.thang.spriteName  # Prefer type, and excluded the quotes we'd get with @formatValue
    content.replace /\#\{(.*?)\}/g, (s, properties) => @formatValue downTheChain(owner, properties.split('.'))

  formatValue: (v) ->
    return null if @doc.type is 'snippet'
    return @options.thang.now() if @doc.name is 'now'
    return '[Function]' if not v and @doc.type is 'function'
    unless v?
      if @doc.owner is 'this'
        v = @options.thang[@doc.name]
      else
        v = window[@doc.owner][@doc.name]  # grab Math or Vector
    if @doc.type is 'number' and not isNaN v
      if v == Math.round v
        return v
      return v.toFixed 2
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
