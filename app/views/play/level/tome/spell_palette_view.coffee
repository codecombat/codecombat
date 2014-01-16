View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_palette'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
Docs = require 'lib/world/docs'
SpellPaletteEntryView = require './spell_palette_entry_view'

module.exports = class SpellPaletteView extends View
  id: 'spell-palette-view'
  template: template
  controlsEnabled: true

  subscriptions:
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'surface:frame-changed': "onFrameChanged"

  constructor: (options) ->
    super options
    @thang = options.thang

  afterRender: ->
    super()
    @createPalette()

  createPalette: ->
    docs = Docs.getDocsFor @thang, @thang.programmableProperties
    docs = docs.concat Docs.getDocsFor(@thang, @thang.programmableSnippets, true)
    shortenize = docs.length > 6
    @entries = (@addEntry doc, shortenize for doc in docs)

  addEntry: (doc, shortenize) ->
    entry = new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: shortenize
    @$el.find('.properties').append entry.el
    entry.render()  # Render after appending so that we can access parent container for popover
    entry

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true
  toggleControls: (e, enabled) ->
    return if e.controls and not ('palette' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.find('*').attr('disabled', not enabled)
    @toggleBackground()

  toggleBackground: =>
    # TODO: make the palette background an actual background and do the CSS trick
    # used in spell_list_entry.sass for disabling
    background = @$el.find('.code-palette-background')[0]
    if background.naturalWidth is 0  # not loaded yet
      return _.delay @toggleBackground, 100
    filters.revertImage background if @controlsEnabled
    filters.darkenImage background, 0.8 unless @controlsEnabled

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang.id
    @options.thang = @thang = e.selectedThang  # Update our thang to the current version

  destroy: ->
    super()
    entry.destroy() for entry in @entries
