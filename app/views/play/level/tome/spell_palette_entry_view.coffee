View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_palette_entry'
popoverTemplate = require 'templates/play/level/tome/spell_palette_entry_popover'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
{downTheChain} = require 'lib/world/world_utils'
window.Vector = require 'lib/world/vector'  # So we can document it

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

# http://stackoverflow.com/a/987376/540620
$.fn.selectText = ->
  el = @[0]
  if document.body.createTextRange
    range = document.body.createTextRange()
    range.moveToElementText(el)
    range.select()
  else if window.getSelection
    selection = window.getSelection()
    range = document.createRange()
    range.selectNodeContents(el)
    selection.removeAllRanges()
    selection.addRange(range)

module.exports = class SpellPaletteEntryView extends View
  tagName: 'div'  # Could also try <code> instead of <div>, but would need to adjust colors
  className: 'spell-palette-entry-view'
  template: template
  popoverPinned: false

  subscriptions:
    'surface:frame-changed': "onFrameChanged"
    'tome:palette-hovered': "onPaletteHovered"
    'tome:palette-pin-toggled': "onPalettePinToggled"
    'tome:spell-debug-property-hovered': 'onSpellDebugPropertyHovered'

  events:
    'mouseenter': 'onMouseEnter'
    'mouseleave': 'onMouseLeave'
    'click': 'onClick'

  constructor: (options) ->
    super options
    @thang = options.thang
    @doc = options.doc
    if _.isString @doc
      @doc = name: @doc, type: typeof @thang[@doc]
    if options.isSnippet
      @doc.type = @doc.owner = 'snippet'
      @doc.shortName = @doc.shorterName = @doc.title = @doc.name
    else
      @doc.owner ?= 'this'
      suffix = ''
      if @doc.type is 'function'
        argNames = (arg.name for arg in @doc.args ? []).join(', ')
        argNames = '...' if argNames.length > 6
        suffix = "(#{argNames})"
      @doc.shortName = "#{@doc.owner}.#{@doc.name}#{suffix};"
      if @doc.owner is 'this' or options.tabbify
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
      animation: false
      html: true
      placement: 'top'
      trigger: 'manual'  # Hover, until they click, which will then pin it until unclick.
      content: @formatPopover()
      container: '#tome-view'
    )
    @$el.on 'show.bs.popover', =>
      Backbone.Mediator.publish 'tome:palette-hovered', thang: @thang, prop: @doc.name, entry: @

  formatPopover: ->
    content = popoverTemplate doc: @doc, value: @formatValue(), marked: marked, argumentExamples: (arg.example or arg.default or arg.name for arg in @doc.args ? [])
    owner = if @doc.owner is 'this' then @thang else window[@doc.owner]
    content = content.replace /#{spriteName}/g, @thang.type ? @thang.spriteName  # Prefer type, and excluded the quotes we'd get with @formatValue
    content.replace /\#\{(.*?)\}/g, (s, properties) => @formatValue downTheChain(owner, properties.split('.'))

  formatValue: (v) ->
    return null if @doc.type is 'snippet'
    return @thang.now() if @doc.name is 'now'
    return '[Function]' if not v and @doc.type is 'function'
    unless v?
      if @doc.owner is 'this'
        v = @thang[@doc.name]
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

  onMouseEnter: (e) ->
    # Make sure the doc has the updated Thang so it can regenerate its prop value
    @$el.data('bs.popover').options.content = @formatPopover()
    @$el.popover('setContent')
    @$el.popover 'show' unless @popoverPinned or @otherPopoverPinned

  onMouseLeave: (e) ->
    @$el.popover 'hide' unless @popoverPinned or @otherPopoverPinned

  togglePinned: ->
    if @popoverPinned
      @popoverPinned = false
      @$el.add('#tome-view .popover').removeClass 'pinned'
      $('#tome-view .popover .close').remove()
      @$el.popover 'hide'
    else
      @popoverPinned = true
      @$el.popover 'show'
      @$el.add('#tome-view .popover').addClass 'pinned'
      x = $('<button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button>')
      $('#tome-view .popover').append x
      x.on 'click', @onClick
    Backbone.Mediator.publish 'tome:palette-pin-toggled', entry: @, pinned: @popoverPinned

  onClick: (e) =>
    @togglePinned()
    Backbone.Mediator.publish 'tome:palette-clicked', thang: @thang, prop: @doc.name, entry: @

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang.id
    @options.thang = @thang = e.selectedThang  # Update our thang to the current version

  onPaletteHovered: (e) ->
    return if e.entry is @
    @togglePinned() if @popoverPinned

  onPalettePinToggled: (e) ->
    return if e.entry is @
    @otherPopoverPinned = e.pinned

  onSpellDebugPropertyHovered: (e) ->
    matched = e.property is @doc.name and e.owner is @doc.owner
    if matched and not @debugHovered
      @debugHovered = true
      @togglePinned() unless @popoverPinned
    else if @debugHovered and not matched
      @debugHovered = false
      @togglePinned() if @popoverPinned
    null

  destroy: ->
    $('.popover.pinned').remove() if @popoverPinned  # @$el.popover('destroy') doesn't work
    @togglePinned() if @popoverPinned
    @$el.popover 'destroy'
    @$el.off()
    super()
