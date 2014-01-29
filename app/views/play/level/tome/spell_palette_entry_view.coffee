View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_palette_entry'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
Docs = require 'lib/world/docs'

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
    @shortenize = options.shortenize

  afterRender: ->
    super()
    text = if @shortenize then @doc.shorterName else @doc.shortName
    @$el.text(text).addClass(@doc.type)
    @$el.attr('title', @doc.title()).popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'hover'
      content: @doc.html()
      container: @$el.parent().parent().parent()
    )
    @$el.on 'show', =>
      # New, good event
      Backbone.Mediator.publish 'tome:palette-hovered', thang: @thang, prop: @doc.prop
      # Bad, old one for old scripts (TODO)
      Backbone.Mediator.publish 'editor:palette-hovered', thang: @thang, prop: @doc.prop

  onMouseOver: (e) ->
    # Make sure the doc has the updated Thang so it can regenerate its prop value
    @doc.thang = @thang
    @$el.data('bs.popover').options.content = @doc.html()
    @$el.popover('setContent')

  onClick: (e) ->
    Backbone.Mediator.publish 'tome:palette-clicked', thang: @thang, prop: @doc.prop

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang.id
    @options.thang = @thang = e.selectedThang  # Update our thang to the current version
    @options.doc = @doc = Docs.getDocsFor(@thang, [@doc.prop])[0]
    @$el.find("code.current-value").text(@doc.formatValue())  # Don't call any functions. (?? What does this mean?)
