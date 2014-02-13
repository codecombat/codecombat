View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_palette'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
SpellPaletteEntryView = require './spell_palette_entry_view'
LevelComponent = require 'models/LevelComponent'

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
    lcs = @supermodel.getModels LevelComponent
    allDocs = {}
    allDocs[doc.name] = doc for doc in (lc.get('propertyDocumentation') ? []) for lc in lcs

    props = @thang.programmableProperties ? []
    snippets = @thang.programmableSnippets ? []
    console.log "yo got snippets", snippets
    shortenize = props.length + snippets.length > 6
    @entries = []
    @entries.push @addEntry(allDocs[prop] ? prop, shortenize) for prop in props
    @entries.push @addEntry(allDocs[prop] ? prop, shortenize, true) for prop in snippets

  addEntry: (doc, shortenize, isSnippet=false) ->
    entry = new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: shortenize, isSnippet: isSnippet
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
    @toggleBackground = null
