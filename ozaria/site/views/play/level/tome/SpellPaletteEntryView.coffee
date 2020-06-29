CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/tome/spell_palette_entry'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
DocFormatter = require './DocFormatter'
ace = require('lib/aceContainer')
utils = require 'core/utils'

module.exports = class SpellPaletteEntryView extends CocoView
  tagName: 'div'  # Could also try <code> instead of <div>, but would need to adjust colors
  className: 'spell-palette-entry-view'
  template: template
  popoverPinned: false
  overridePopoverTemplate: '<div class="popover spell-palette-popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'

  subscriptions:
    'surface:frame-changed': 'onFrameChanged'
    'tome:palette-hovered': 'onPaletteHovered'
    'tome:palette-clicked': 'onPaletteClicked'
    'tome:palette-pin-toggled': 'onPalettePinToggled'
    'tome:spell-debug-property-hovered': 'onSpellDebugPropertyHovered'

  events:
    'mouseenter': 'onMouseEnter'
    'mouseleave': 'onMouseLeave'
    'click': 'onClick'

  constructor: (options) ->
    super options
    @thang = options.thang
    @docFormatter = new DocFormatter options
    @doc = @docFormatter.doc
    @doc.initialHTML = @docFormatter.formatPopover()
    @aceEditors = []

  afterRender: ->
    super()
    @$el.addClass _.string.slugify @doc.type

  resetPopoverContent: ->
    #@$el.data('bs.popover').options.content = @docFormatter.formatPopover()
    #@$el.popover('setContent')

  onMouseEnter: (e) ->
    return if @popoverPinned or @otherPopoverPinned
    #@resetPopoverContent()
    #@$el.popover 'show'

  onMouseLeave: (e) ->
    #@$el.popover 'hide' unless @popoverPinned or @otherPopoverPinned

  togglePinned: ->
    if @popoverPinned
      @popoverPinned = false
      @$el.add('.spell-palette-popover.popover').removeClass 'pinned'
      $('.spell-palette-popover.popover .close').remove()
      @$el.popover 'hide'
      @playSound 'spell-palette-entry-unpin'
    else
      @popoverPinned = true
      @resetPopoverContent()
      @$el.add('.spell-palette-popover.popover').addClass 'pinned'
      @$el.popover 'show'
      x = $('<button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button>')
      $('.spell-palette-popover.popover').append x
      x.on 'click', @onClick
      @playSound 'spell-palette-entry-pin'
    Backbone.Mediator.publish 'tome:palette-pin-toggled', entry: @, pinned: @popoverPinned

  onPaletteClicked: (e) =>
    @$el.toggleClass('selected', e.prop is @doc.name)

  onClick: (e) =>
    if key.shift
      Backbone.Mediator.publish 'tome:insert-snippet', doc: @options.doc, language: @options.language, formatted: @doc
      return
    #@togglePinned()
    Backbone.Mediator.publish 'tome:palette-clicked', thang: @thang, prop: @doc.name, entry: @

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang?.id
    @options.thang = @thang = @docFormatter.options.thang = e.selectedThang  # Update our thang to the current version

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
    oldEditor.destroy() for oldEditor in @aceEditors
    super()
