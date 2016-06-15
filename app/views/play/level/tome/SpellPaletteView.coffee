CocoView = require 'views/core/CocoView'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
SpellPaletteEntryView = require './SpellPaletteEntryView'
LevelComponent = require 'models/LevelComponent'
ThangType = require 'models/ThangType'
GameMenuModal = require 'views/play/menu/GameMenuModal'
LevelSetupManager = require 'lib/LevelSetupManager'

N_ROWS = 4

module.exports = class SpellPaletteView extends CocoView
  id: 'spell-palette-view'
  template: require 'templates/play/level/tome/spell-palette-view'
  controlsEnabled: true

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'surface:frame-changed': 'onFrameChanged'
    'tome:change-language': 'onTomeChangedLanguage'

  events:
    'click #spell-palette-help-button': 'onClickHelp'

  initialize: (options) ->
    {@level, @session, @supermodel, @thang, @useHero} = options
    docs = @options.level.get('documentation') ? {}
    @showsHelp = docs.specificArticles?.length or docs.generalArticles?.length
    @createPalette()
    $(window).on 'resize', @onResize

  getRenderData: ->
    c = super()
    c.entryGroups = @entryGroups
    c.entryGroupSlugs = @entryGroupSlugs
    c.entryGroupNames = @entryGroupNames
    c.tabbed = _.size(@entryGroups) > 1
    c.defaultGroupSlug = @defaultGroupSlug
    c.showsHelp = @showsHelp
    c.tabs = @tabs  # For hero-based, non-this-owned tabs like Vector, Math, etc.
    c.thisName = {coffeescript: '@', lua: 'self', python: 'self', java: 'hero'}[@options.language] or 'this'
    c._ = _
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
        @entryGroupElements[group] = itemGroup = $('<div class="property-entry-item-group"></div>').appendTo @$el.find('.properties-this')
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
      for tab, entries of @tabs or {}
        tabSlug = _.string.slugify tab
        itemsInGroup = 0
        for entry, entryIndex in entries
          if itemsInGroup is 0 or (itemsInGroup is 2 and entryIndex isnt entries.length - 1)
            itemGroup = $('<div class="property-entry-item-group"></div>').appendTo @$el.find(".properties-#{tabSlug}")
            itemsInGroup = 0
          ++itemsInGroup
          itemGroup.append entry.el
          entry.render()  # Render after appending so that we can access parent container for popover
          if itemsInGroup is 0
            entry.$el.addClass 'first-entry'
      @$el.addClass 'hero'
      @$el.toggleClass 'shortenize', Boolean @shortenize
      @updateMaxHeight() unless application.isIPadApp

  afterInsert: ->
    super()
    _.delay => @$el?.css('bottom', 0) unless $('#spell-view').is('.shown')

  updateCodeLanguage: (language) ->
    @options.language = language

  updateMaxHeight: ->
    return unless @isHero
    # We figure out how many columns we can fit, width-wise, and then guess how many rows will be needed.
    # We can then assign a height based on the number of rows, and the flex layout will do the rest.
    columnWidth = if @shortenize then 175 else 212
    nColumns = Math.floor @$el.find('.properties-this').innerWidth() / columnWidth   # will always have 2 columns, since at 1024px screen we have 424px .properties
    columns = ({items: [], nEntries: 0} for i in [0 ... nColumns])
    orderedColumns = []
    nRows = 0
    entryGroupsByLength = _.sortBy _.keys(@entryGroups), (group) => @entryGroups[group].length
    entryGroupsByLength.reverse()
    for group in entryGroupsByLength
      entries = @entryGroups[group]
      continue unless shortestColumn = _.sortBy(columns, (column) -> column.nEntries)[0]
      shortestColumn.nEntries += Math.max 2, entries.length  # Item portrait is two rows tall
      shortestColumn.items.push @entryGroupElements[group]
      orderedColumns.push shortestColumn unless shortestColumn in orderedColumns
      nRows = Math.max nRows, shortestColumn.nEntries
    for column in orderedColumns
      for item in column.items
        item.detach().appendTo @$el.find('.properties-this')
    desiredHeight = 19 * (nRows + 1)
    @$el.find('.properties').css('height', desiredHeight)

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
    if not (@options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev']) or not @options.programmable
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

    @shortenize = count > 6
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
          @entries.push @addEntry(doc, @shortenize, owner is 'snippets')
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
      i18nKey = if @options.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev'] then 'play_level.tome_your_skills' else 'play_level.tome_available_spells'
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
    if thisName = {coffeescript: '@', lua: 'self', python: 'self'}[@options.language]
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
                continue if prop is 'moveXY' and @options.level.get('slug') is 'slalom'  # Hide for Slalom
                propsByItem[item.get('name')] ?= []
                propsByItem[item.get('name')].push owner: owner, prop: prop, item: item
                itemsByProp[prop] = item
                ++propCount
      else
        console.log @thang.id, "couldn't find item ThangType for", slot, thangTypeName

    # Get any Math-, Vector-, etc.-owned properties into their own tabs
    for owner, storage of propStorage when not (owner in ['this', 'more', 'snippets'])
      continue unless @thang[storage]?.length
      @tabs ?= {}
      @tabs[owner] = []
      programmaticonName = @thang.inventoryThangTypeNames['programming-book']
      programmaticon = itemThangTypes[programmaticonName]
      sortedProps = @thang[storage].slice().sort()
      for prop in sortedProps
        if doc = _.find (allDocs['__' + prop] ? []), {owner: owner}  # Not all languages have all props
          entry = @addEntry doc, false, false, programmaticon
          @tabs[owner].push entry

    # Assign any unassigned properties to the hero itself.
    for owner, storage of propStorage
      continue unless owner in ['this', 'more', 'snippets']
      for prop in _.reject(@thang[storage] ? [], (prop) -> itemsByProp[prop] or prop[0] is '_')  # no private properties
        continue if prop is 'say' and @options.level.get 'hidesSay'  # Hide for Dungeon Campaign
        continue if prop is 'moveXY' and @options.level.get('slug') is 'slalom'  # Hide for Slalom
        propsByItem['Hero'] ?= []
        propsByItem['Hero'].push owner: owner, prop: prop, item: itemThangTypes[@thang.spriteName]
        ++propCount

    Backbone.Mediator.publish 'tome:update-snippets', propGroups: propsByItem, allDocs: allDocs, language: @options.language

    @shortenize = propCount > 6
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
          @entries.push @addEntry(doc, @shortenize, owner is 'snippets', item, propIndex > 0)
    @entryGroups = _.groupBy @entries, (entry) -> itemsByProp[entry.doc.name]?.get('name') ? 'Hero'
    iOSEntryGroups = {}
    for group, entries of @entryGroups
      iOSEntryGroups[group] =
        item: {name: group, imageURL: itemThangTypes[group]?.getPortraitURL()}
        props: (entry.doc for entry in entries)
    Backbone.Mediator.publish 'tome:palette-updated', thangID: @thang.id, entryGroups: JSON.stringify(iOSEntryGroups)

  addEntry: (doc, shortenize, isSnippet=false, item=null, showImage=false) ->
    writable = (if _.isString(doc) then doc else doc.name) in (@thang.apiUserProperties ? [])
    new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: shortenize, isSnippet: isSnippet, language: @options.language, writable: writable, level: @options.level, item: item, showImage: showImage, useHero: @useHero

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true
  toggleControls: (e, enabled) ->
    return if e.controls and not ('palette' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.find('*').attr('disabled', not enabled)
    @$el.toggleClass 'controls-disabled', not enabled

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
    gameMenuModal = new GameMenuModal showTab: 'guide', level: @level, session: @session, supermodel: @supermodel
    @openModalView gameMenuModal
    @listenToOnce gameMenuModal, 'change-hero', ->
      @setupManager?.destroy()
      @setupManager = new LevelSetupManager({supermodel: @supermodel, level: @level, levelID: @level.get('slug'), parent: @, session: @session, courseID: @options.courseID, courseInstanceID: @options.courseInstanceID})
      @setupManager.open()

  destroy: ->
    entry.destroy() for entry in @entries
    @toggleBackground = null
    $(window).off 'resize', @onResize
    @setupManager?.destroy()
    super()
