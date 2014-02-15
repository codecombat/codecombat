View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_palette_entry'
popoverTemplate = require 'templates/play/level/tome/spell_palette_entry_popover'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
{downTheChain} = require 'lib/world/world_utils'

# If we use marked somewhere else, we'll have to make sure to preserve options
marked.setOptions {gfm: true, sanitize: false, smartLists: true, breaks: true}

safeJSONStringify = (input, maxDepth) ->
  recursion = (input, path, depth) ->
    output = {}
    pPath = undefined
    refIdx = undefined
    path = path or ""
    depth = depth or 0
    depth++
    return "{depth over " + maxDepth + "}"  if maxDepth and depth > maxDepth
    for p of input
      pPath = ((if path then (path + ".") else "")) + p
      if typeof input[p] is "function"
        output[p] = "{function}"
      else if typeof input[p] is "object"
        refIdx = refs.indexOf(input[p])
        if -1 isnt refIdx
          output[p] = "{reference to " + refsPaths[refIdx] + "}"
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
  if typeof input is "object"
    output = recursion(input)
  else
    output = input
  JSON.stringify output, null, 1

module.exports = class SpellPaletteEntryView extends View
  tagName: 'div'  # Could also try <code> instead of <div>, but would need to adjust colors
  className: 'spell-palette-entry-view'
  template: template

  subscriptions:
    'surface:frame-changed': "onFrameChanged"

  events:
    'mouseover': 'onMouseOver'
    'click': 'onClick'

  constructor: (options) ->
    super options
    @thang = options.thang
    @doc = options.doc
    if _.isString @doc
      @doc = name: @doc, type: typeof @thang[@doc]
    @doc.owner ?= 'this'
    if options.isSnippet
      @doc.type = 'snippet'
      @doc.shortName = @doc.shorterName = @doc.title = @doc.name
    else
      suffix = if @doc.type is 'function' then '()' else ''
      @doc.shortName = "#{@doc.owner}.#{@doc.name}#{suffix};"
      if @doc.owner is 'this'
        @doc.shorterName = "#{@doc.name}#{suffix}"
      else
        @doc.shorterName = @doc.shortName.replace ';', ''
      @doc.title = if options.shortenize then @doc.shorterName else @doc.shortName

  getRenderData: ->
    c = super()
    c.doc = @doc
    c

  afterRender: ->
    super()
    @$el.addClass(@doc.type)
    @$el.popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'hover'
      content: @formatPopover()
      container: @$el.parent().parent().parent()
    )
    @$el.on 'show.bs.popover', =>
      Backbone.Mediator.publish 'tome:palette-hovered', thang: @thang, prop: @doc.name

  formatPopover: ->
    content = popoverTemplate doc: @doc, value: @formatValue(), marked: marked, argumentExamples: (arg.example or arg.default or arg.name for arg in @doc.args ? [])
    owner = if @doc.owner is 'this' then @thang else window[@doc.owner]
    content = content.replace /#{spriteName}/g, @thang.spriteName  # No quotes like we'd get with @formatValue
    content.replace /\#\{(.*?)\}/g, (s, properties) => @formatValue downTheChain(owner, properties.split('.'))

  formatValue: (v) ->
    return @thang.now() if @doc.name is 'now'
    return '[Function]' if not v and @doc.type is 'function'
    unless v?
      if @doc.owner is 'this'
        v = @thang[@doc.name]
      else
        v = window[@doc.owner][@doc.name]
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

  onMouseOver: (e) ->
    # Make sure the doc has the updated Thang so it can regenerate its prop value
    @$el.data('bs.popover').options.content = @formatPopover()
    @$el.popover('setContent')

  onClick: (e) ->
    Backbone.Mediator.publish 'tome:palette-clicked', thang: @thang, prop: @doc.name

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang.id
    @options.thang = @thang = e.selectedThang  # Update our thang to the current version

  destroy: ->
    @$el.off()
    super()
