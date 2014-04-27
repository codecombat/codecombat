View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_palette'
{me} = require 'lib/auth'
filters = require 'lib/image_filter'
SpellPaletteEntryView = require './spell_palette_entry_view'
LevelComponent = require 'models/LevelComponent'

N_ROWS = 4

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
    @createPalette()

  getRenderData: ->
    c = super()
    c.entryGroups = @entryGroups
    c.entryGroupSlugs = @entryGroupSlugs
    c.tabbed = _.size(@entryGroups) > 1
    c.defaultGroupSlug = @defaultGroupSlug
    c

  afterRender: ->
    super()
    for group, entries of @entryGroups
      groupSlug = @entryGroupSlugs[group]
      for columnNumber, entryColumn of entries
        col = $('<div class="property-entry-column"></div>').appendTo @$el.find(".properties-#{groupSlug}")
        for entry in entryColumn
          col.append entry.el
          entry.render()  # Render after appending so that we can access parent container for popover
      $('.nano').nanoScroller()

  createPalette: ->
    lcs = @supermodel.getModels LevelComponent
    allDocs = {}
    for lc in lcs
      for doc in (lc.get('propertyDocumentation') ? [])
        doc = _.clone doc
        allDocs['__' + doc.name] ?= []
        allDocs['__' + doc.name].push doc
        if doc.type is 'snippet' then doc.owner = 'snippets'

    if @options.programmable
      propStorage =
        'this': 'programmableProperties'
        more: 'moreProgrammableProperties'
        Math: 'programmableMathProperties'
        Array: 'programmableArrayProperties'
        Object: 'programmableObjectProperties'
        String: 'programmableStringProperties'
        Vector: 'programmableVectorProperties'
        snippets: 'programmableSnippets'
    else
      propStorage =
        'this': 'apiProperties'
    count = 0
    propGroups = {}
    for owner, storage of propStorage
      props = _.reject @thang[storage] ? [], (prop) -> prop[0] is '_'  # no private properties
      added = propGroups[owner] = _.sortBy(props).slice()
      count += added.length

    shortenize = count > 6
    tabbify = count >= 10
    @entries = []
    for owner, props of propGroups
      for prop in props
        doc = _.find (allDocs['__' + prop] ? []), (doc) ->
          return true if doc.owner is owner
          return (owner is 'this' or owner is 'more') and (not doc.owner? or doc.owner is 'this')
        console.log 'could not find doc for', prop, 'from', allDocs['__' + prop], 'for', owner, 'of', propGroups unless doc
        doc ?= prop
        @entries.push @addEntry(doc, shortenize, tabbify, owner is 'snippets')
    groupForEntry = (entry) ->
      return 'more' if entry.doc.owner is 'this' and entry.doc.name in (propGroups.more ? [])
      entry.doc.owner
    @entries = _.sortBy @entries, (entry) ->
      order = ['this', 'more', 'Math', 'Vector', 'snippets']
      index = order.indexOf groupForEntry entry
      index = String.fromCharCode if index is -1 then order.length else index
      index += entry.doc.name
    if tabbify and _.find @entries, ((entry) -> entry.doc.owner isnt 'this')
      @entryGroups = _.groupBy @entries, groupForEntry
    else
      defaultGroup = $.i18n.t("play_level.tome_available_spells", defaultValue: "Available Spells")
      @entryGroups = {}
      @entryGroups[defaultGroup] = @entries
      @defaultGroupSlug = _.string.slugify defaultGroup
    @entryGroupSlugs = {}
    for group, entries of @entryGroups
      @entryGroupSlugs[group] = _.string.slugify group
      @entryGroups[group] = _.groupBy entries, (entry, i) -> Math.floor i / N_ROWS
    null

  addEntry: (doc, shortenize, tabbify, isSnippet=false) ->
    new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: shortenize, tabbify: tabbify, isSnippet: isSnippet

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
    entry.destroy() for entry in @entries
    @toggleBackground = null
    super()
