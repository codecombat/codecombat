CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/spell_palette'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
SpellPaletteEntryView = require './SpellPaletteEntryView'
LevelComponent = require 'models/LevelComponent'
ThangType = require 'models/ThangType'
GameMenuModal = require 'views/play/menu/GameMenuModal'

N_ROWS = 4

module.exports = class SpellPaletteView extends CocoView
  id: 'spell-palette-view'
  template: template
  controlsEnabled: true

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'surface:frame-changed': 'onFrameChanged'
    'tome:change-language': 'onTomeChangedLanguage'

  events:
    'click #spell-palette-help-button': 'onClickHelp'

  constructor: (options) ->
    super options
    @level = options.level
    @session = options.session
    @supermodel = options.supermodel
    @thang = options.thang
    @createPalette()
    $(window).on 'resize', @onResize

  getRenderData: ->
    c = super()
    c.entryGroups = @entryGroups
    c.entryGroupSlugs = @entryGroupSlugs
    c.entryGroupNames = @entryGroupNames
    c.tabbed = _.size(@entryGroups) > 1
    c.defaultGroupSlug = @defaultGroupSlug
    c

  afterRender: ->
    super()
    if @entryGroupSlugs
      for group, entries of @entryGroups
        groupSlug = @entryGroupSlugs[group]
        for columnNumber, entryColumn of entries
          col = $('<div class="property-entry-column"></div>').appendTo @$el.find(".properties-#{groupSlug}")
          for entry in entryColumn
            col.append entry.el
            entry.render()  # Render after appending so that we can access parent container for popover
      $('.nano').nanoScroller()
      @updateCodeLanguage @options.language
    else
      @entryGroupElements = {}
      for group, entries of @entryGroups
        @entryGroupElements[group] = itemGroup = $('<div class="property-entry-item-group"></div>').appendTo @$el.find('.properties')
        if entries[0].options.item?.getPortraitURL
          itemImage = $('<img class="item-image" draggable=false></img>').attr('src', entries[0].options.item.getPortraitURL()).css('top', Math.max(0, 19 * (entries.length - 2) / 2) + 2)
          itemGroup.append itemImage
          firstEntry = entries[0]
          do (firstEntry) ->
            itemImage.on "mouseenter", (e) -> firstEntry.onMouseEnter e
            itemImage.on "mouseleave", (e) -> firstEntry.onMouseLeave e
        for entry, entryIndex in entries
          itemGroup.append entry.el
          entry.render()  # Render after appending so that we can access parent container for popover
          if entries.length is 1
            entry.$el.addClass 'single-entry'
          if entryIndex is 0
            entry.$el.addClass 'first-entry'
      @$el.addClass 'hero'
      @updateMaxHeight() unless application.isIPadApp

  afterInsert: ->
    super()
    _.delay => @$el?.css('bottom', 0) unless $('#spell-view').is('.shown')

  updateCodeLanguage: (language) ->
    @options.language = language

  updateMaxHeight: ->
    return unless @isHero
    nColumns = Math.floor @$el.find('.properties').innerWidth() / 212   # ~212px is a good max entry width; will always have 2 columns
    columns = ({items: [], nEntries: 0} for i in [0 ... nColumns])
    nRows = 0
    for group, entries of @entryGroups
      continue unless shortestColumn = _.sortBy(columns, (column) -> column.nEntries)[0]
      shortestColumn.nEntries += Math.max 2, entries.length
      shortestColumn.items.push @entryGroupElements[group]
      nRows = Math.max nRows, shortestColumn.nEntries
    for column in columns
      for item in column.items
        item.detach().appendTo @$el.find('.properties')
    @$el.find('.properties').css('height', 19 * (nRows + 1))

  onResize: (e) =>
    @updateMaxHeight()

  createPalette: ->
    Backbone.Mediator.publish 'tome:palette-cleared', {thangID: @thang.id}
    lcs = @supermodel.getModels LevelComponent
    allDocs = {}
    excludedDocs = {}
    for lc in lcs
      for doc in (lc.get('propertyDocumentation') ? [])
        if doc.codeLanguages and not (@options.language in doc.codeLanguages)
          excludedDocs['__' + doc.name] = doc
          continue
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
        Global: 'programmableGlobalProperties'
        Function: 'programmableFunctionProperties'
        RegExp: 'programmableRegExpProperties'
        Date: 'programmableDateProperties'
        Number: 'programmableNumberProperties'
        JSON: 'programmableJSONProperties'
        LoDash: 'programmableLoDashProperties'
        Vector: 'programmableVectorProperties'
        snippets: 'programmableSnippets'
    else
      propStorage =
        'this': ['apiProperties', 'apiMethods']
    if not (@options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']) or not @options.programmable
      @organizePalette propStorage, allDocs, excludedDocs
    else
      @organizePaletteHero propStorage, allDocs, excludedDocs

  organizePalette: (propStorage, allDocs, excludedDocs) ->
    count = 0
    propGroups = {}
    for owner, storages of propStorage
      storages = [storages] if _.isString storages
      for storage in storages
        props = _.reject @thang[storage] ? [], (prop) -> prop[0] is '_'  # no private properties
        props = _.uniq props
        added = _.sortBy(props).slice()
        propGroups[owner] = (propGroups[owner] ? []).concat added
        count += added.length
    Backbone.Mediator.publish 'tome:update-snippets', propGroups: propGroups, allDocs: allDocs, language: @options.language

    shortenize = count > 6
    tabbify = count >= 10
    @entries = []
    for owner, props of propGroups
      for prop in props
        doc = _.find (allDocs['__' + prop] ? []), (doc) ->
          return true if doc.owner is owner
          return (owner is 'this' or owner is 'more') and (not doc.owner? or doc.owner is 'this')
        if not doc and not excludedDocs['__' + prop]
          console.log 'could not find doc for', prop, 'from', allDocs['__' + prop], 'for', owner, 'of', propGroups
          doc ?= prop
        if doc
          @entries.push @addEntry(doc, shortenize, tabbify, owner is 'snippets')
    groupForEntry = (entry) ->
      return 'more' if entry.doc.owner is 'this' and entry.doc.name in (propGroups.more ? [])
      entry.doc.owner
    @entries = _.sortBy @entries, (entry) ->
      order = ['this', 'more', 'Math', 'Vector', 'String', 'Object', 'Array', 'Function', 'snippets']
      index = order.indexOf groupForEntry entry
      index = String.fromCharCode if index is -1 then order.length else index
      index += entry.doc.name
    if tabbify and _.find @entries, ((entry) -> entry.doc.owner isnt 'this')
      @entryGroups = _.groupBy @entries, groupForEntry
    else
      i18nKey = if @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop'] then 'play_level.tome_your_skills' else 'play_level.tome_available_spells'
      defaultGroup = $.i18n.t i18nKey
      @entryGroups = {}
      @entryGroups[defaultGroup] = @entries
      @defaultGroupSlug = _.string.slugify defaultGroup
    @entryGroupSlugs = {}
    @entryGroupNames = {}
    for group, entries of @entryGroups
      @entryGroups[group] = _.groupBy entries, (entry, i) -> Math.floor i / N_ROWS
      @entryGroupSlugs[group] = _.string.slugify group
      @entryGroupNames[group] = group
    if thisName = {coffeescript: '@', lua: 'self', clojure: 'self'}[@options.language]
      if @entryGroupNames.this
        @entryGroupNames.this = thisName

  organizePaletteHero: (propStorage, allDocs, excludedDocs) ->
    # Assign any kind of programmable properties to the items that grant them.
    @isHero = true
    itemThangTypes = {}
    itemThangTypes[tt.get('name')] = tt for tt in @supermodel.getModels ThangType  # Also heroes
    propsByItem = {}
    propCount = 0
    itemsByProp = {}
    # Make sure that we get the spellbook first, then the primary hand, then anything else.
    slots = _.sortBy _.keys(@thang.inventoryThangTypeNames ? {}), (slot) ->
      if slot is 'left-hand' then 0 else if slot is 'right-hand' then 1 else 2
    for slot in slots
      thangTypeName = @thang.inventoryThangTypeNames[slot]
      if item = itemThangTypes[thangTypeName]
        unless item.get('components')
          console.error 'Item', item, 'did not have any components when we went to assemble docs.'
        for component in item.get('components') ? [] when component.config
          for owner, storages of propStorage
            if props = component.config[storages]
              for prop in _.sortBy(props) when prop[0] isnt '_' and not itemsByProp[prop]  # no private properties
                propsByItem[item.get('name')] ?= []
                propsByItem[item.get('name')].push owner: owner, prop: prop, item: item
                itemsByProp[prop] = item
                ++propCount
      else
        console.log @thang.id, "couldn't find item ThangType for", slot, thangTypeName

    # Assign any unassigned properties to the hero itself.
    for owner, storage of propStorage
      for prop in _.reject(@thang[storage] ? [], (prop) -> itemsByProp[prop] or prop[0] is '_')  # no private properties
        if prop is 'say' and @options.level.get 'hidesSay'  # Hide for Dungeon Campaign
          continue
        propsByItem['Hero'] ?= []
        propsByItem['Hero'].push owner: owner, prop: prop, item: itemThangTypes[@thang.spriteName]
        ++propCount

    Backbone.Mediator.publish 'tome:update-snippets', propGroups: propsByItem, allDocs: allDocs, language: @options.language

    shortenize = propCount > 6
    @entries = []
    for itemName, props of propsByItem
      for prop, propIndex in props
        item = prop.item
        owner = prop.owner
        prop = prop.prop
        doc = _.find (allDocs['__' + prop] ? []), (doc) ->
          return true if doc.owner is owner
          return (owner is 'this' or owner is 'more') and (not doc.owner? or doc.owner is 'this')
        if not doc and not excludedDocs['__' + prop]
          console.log 'could not find doc for', prop, 'from', allDocs['__' + prop], 'for', owner, 'of', propsByItem, 'with item', item
          doc ?= prop
        if doc
          @entries.push @addEntry(doc, shortenize, false, owner is 'snippets', item, propIndex > 0)
    @entryGroups = _.groupBy @entries, (entry) -> itemsByProp[entry.doc.name]?.get('name') ? 'Hero'
    iOSEntryGroups = {}
    for group, entries of @entryGroups
      iOSEntryGroups[group] =
        item: {name: group, imageURL: itemThangTypes[group]?.getPortraitURL()}
        props: (entry.doc for entry in entries)
    Backbone.Mediator.publish 'tome:palette-updated', thangID: @thang.id, entryGroups: JSON.stringify(iOSEntryGroups)

  addEntry: (doc, shortenize, tabbify, isSnippet=false, item=null, showImage=false) ->
    writable = (if _.isString(doc) then doc else doc.name) in (@thang.apiUserProperties ? [])
    new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: shortenize, tabbify: tabbify, isSnippet: isSnippet, language: @options.language, writable: writable, level: @options.level, item: item, showImage: showImage

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true
  toggleControls: (e, enabled) ->
    return if e.controls and not ('palette' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.find('*').attr('disabled', not enabled)
    @$el.toggleClass 'controls-disabled', not enabled
    @toggleBackground()

  toggleBackground: =>
    # TODO: make the palette background an actual background and do the CSS trick
    # used in spell_list_entry.sass for disabling
    background = @$el.find('img.code-palette-background')[0]
    if background.naturalWidth is 0  # not loaded yet
      return _.delay @toggleBackground, 100
    filters.revertImage background, 'span.code-palette-background' if @controlsEnabled
    filters.darkenImage background, 'span.code-palette-background', 0.8 unless @controlsEnabled

  onFrameChanged: (e) ->
    return unless e.selectedThang?.id is @thang.id
    @options.thang = @thang = e.selectedThang  # Update our thang to the current version

  onTomeChangedLanguage: (e) ->
    @updateCodeLanguage e.language
    entry.destroy() for entry in @entries
    @createPalette()
    @render()

  onClickHelp: (e) ->
    application.tracker?.trackEvent 'Spell palette help clicked', levelID: @level.get('slug')
    @openModalView new GameMenuModal showTab: 'guide', level: @level, session: @session, supermodel: @supermodel

  destroy: ->
    entry.destroy() for entry in @entries
    @toggleBackground = null
    $(window).off 'resize', @onResize
    super()
