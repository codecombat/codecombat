CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/spell-palette-thang-entry'
popoverTemplate = require 'templates/play/level/tome/spell_palette_entry_popover'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
DocFormatter = require './DocFormatter'
utils = require 'core/utils'

module.exports = class SpellPaletteThangEntryView extends CocoView
  tagName: 'div'  # Could also try <code> instead of <div>, but would need to adjust colors
  className: 'spell-palette-thang-entry-view'
  template: template
 
  subscriptions:
    'surface:frame-changed': 'onFrameChanged'
    'tome:palette-hovered': 'onPaletteHovered'
    'tome:palette-clicked': 'onPaletteClicked'
    'tome:spell-debug-property-hovered': 'onSpellDebugPropertyHovered'

  events:
    'mouseenter': 'onMouseEnter'
    'mouseleave': 'onMouseLeave'
    'click': 'onClick'

  constructor: (options) ->
    super options
    @thang = options.thang
    @doc =
      name: options.buildableName
      initialHTML: popoverTemplate _: _, marked: marked, doc:
        shortName: @thang.get('name')
        type: "thang"
        description: "![#{@thang.get('name')}](#{@thang.getPortraitURL()}) #{options.doc.description}"
        example: options.doc.example[options.language]

    @doc.example ?= "\# usage code \ngame.spawnXY(\"#{@thang.get('name')}\", 21, 20)"
    #@aceEditors = []

  afterRender: ->
    super()
    #@$el.addClass _.string.slugify @doc.type

  resetPopoverContent: ->
    #@$el.data('bs.popover').options.content = @docFormatter.formatPopover()
    #@$el.popover('setContent')

  onMouseEnter: (e) ->
    return if @popoverPinned or @otherPopoverPinned
    #@resetPopoverContent()
    #@$el.popover 'show'

  onMouseLeave: (e) ->
    #@$el.popover 'hide' unless @popoverPinned or @otherPopoverPinned


  onPaletteClicked: (e) =>
    @$el.toggleClass('selected', e.prop is @doc.name)

  onClick: (e) =>
    if key.shift
      Backbone.Mediator.publish 'tome:insert-snippet', doc: @options.doc, language: @options.language, formatted: @doc
      return
    Backbone.Mediator.publish 'tome:palette-clicked', thang: @thang, prop: @doc.name, entry: @

  onFrameChanged: (e) ->
    #return unless e.selectedThang?.id is @thang.id
    #@options.thang = @thang = @docFormatter.options.thang = e.selectedThang  # Update our thang to the current version

  onPaletteHovered: (e) ->
    return if e.entry is @

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
    @$el.off()
    oldEditor.destroy() for oldEditor in @aceEditors
    super()
