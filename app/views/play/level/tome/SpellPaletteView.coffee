require('app/styles/play/level/tome/spell-palette-view.sass')
CocoView = require 'views/core/CocoView'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
SpellPaletteEntryView = require './SpellPaletteEntryView'
SpellPaletteThangEntryView = require './SpellPaletteThangEntryView'
LevelComponent = require 'models/LevelComponent'
ThangType = require 'models/ThangType'
GameMenuModal = require 'views/play/menu/GameMenuModal'
LevelSetupManager = require 'lib/LevelSetupManager'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'

N_ROWS = 4

module.exports = class SpellPaletteView extends CocoView
  id: 'spell-palette-view'
  template: require 'app/templates/play/level/tome/spell-palette-view-mid'
  controlsEnabled: true
  position: 'mid'

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'surface:frame-changed': 'onFrameChanged'
    'tome:change-language': 'onTomeChangedLanguage'
    'tome:palette-clicked': 'onPaletteClick'
    'surface:stage-mouse-down': 'hide'

  events:
    'click .closeBtn': 'onClickClose'
    'click .section-header': 'onSectionHeaderClick'

  initialize: (options) ->
    {@level, @session, @thang, @useHero} = options
    @aceEditors = []
    docs = @options.level.get('documentation') ? {}
    @createPalette()
    $(window).on 'resize', @onResize

  getRenderData: ->
    c = super()
    c.entryGroups = @entryGroups
    c.tabbed = _.size(@entryGroups) > 1
    c.tabs = @tabs  # For hero-based, non-this-owned tabs like Vector, Math, etc.
    c.thisName = {coffeescript: '@', lua: 'self', python: 'self', java: 'hero', cpp: 'hero'}[@options.language] or 'this'
    c._ = _
    c

  afterRender: ->
    super()
    @entryGroupElements = {}
    for group, entries of @entryGroups
      @entryGroupElements[group] = itemGroup = $('<div class="property-entry-item-group"></div>').appendTo @$el.find('.properties-this')
      if entries[0].options.item?.getPortraitURL
        itemImage = $('<img class="item-image" draggable=false></img>').attr('src', entries[0].options.item.getPortraitURL())
        if @position is 'bot'
          itemImage.css('top', Math.max(0, 19 * (entries.length - 2) / 2) + 2)
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
    @$el.toggleClass 'web-dev', @options.level.isType('web-dev')

    tts = @supermodel.getModels ThangType

    for dn of @deferredDocs
      doc = @deferredDocs[dn]
      if doc.type is "spawnable"
        thangName = doc.name
        if @thang.spawnAliases[thangName]
          thangName = @thang.spawnAliases[thangName][0]

        info = @thang.buildables[thangName]
        tt = _.find tts, (t) -> t.get('original') is info?.thangType
        continue unless tt?
        t = new SpellPaletteThangEntryView doc: doc, thang: tt, buildable: info, buildableName: doc.name, shortenize: true, language: @options.language, level: @options.level, useHero: @useHero
        @$el.find("#palette-tab-stuff-area").append t.el
        t.render()

      if doc.type is "event"
        t = new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: true, language: @options.language, level: @options.level, useHero: @useHero
        @$el.find("#palette-tab-events").append t.el
        t.render()

      if doc.type is "handler"
        t = new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: true, language: @options.language, level: @options.level, useHero: @useHero
        @$el.find("#palette-tab-handlers").append t.el
        t.render()

      if doc.type is "property"
        t = new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: true, language: @options.language, level: @options.level, writable: true
        @$el.find("#palette-tab-properties").append t.el
        t.render()

      if doc.type is "snippet" and @level.get('type') is 'game-dev'
        t = new SpellPaletteEntryView doc: doc, thang: @thang, isSnippet: true, shortenize: true, language: @options.language, level: @options.level
        @$el.find("#palette-tab-snippets").append t.el
        t.render()

    @$(".section-header:has(+.collapse:empty)").hide()

  afterInsert: ->
    super()
    _.delay => @$el?.css('bottom', 0) unless $('#spell-view').is('.shown')

  updateCodeLanguage: (language) ->
    @options.language = language

  calculateNColumns: ->
    return 1 unless @isHero and @position is 'bot'
    columnWidth = 212
    columnWidth = 175 if @shortenize
    columnWidth = 100 if @options.level.isType('web-dev')
    availableWidth = @$el.find('.properties-this').innerWidth() or $('#code-area').innerWidth() - 40
    nColumns = Math.floor availableWidth / columnWidth   # Will always have at least 2 columns, since at 1024px screen we have 425px .properties
    Math.max 2, nColumns

  updateMaxHeight: ->
    return unless @isHero and @position is 'bot'
    # We figure out how many columns we can fit, width-wise, and then guess how many rows will be needed.
    # We can then assign a height based on the number of rows, and the flex layout will do the rest.
    nColumns = @calculateNColumns()
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
    @updateMaxHeight?()

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
        HTML: 'programmableHTMLProperties'
        WebJavaScript: 'programmableWebJavaScriptProperties'
        jQuery: 'programmableJQueryProperties'
        CSS: 'programmableCSSProperties'
        snippets: 'programmableSnippets'
    else
      propStorage =
        'this': ['apiProperties', 'apiMethods']
    @organizePalette propStorage, allDocs, excludedDocs

  organizePalette: (propStorage, allDocs, excludedDocs) ->
    # Assign any kind of programmable properties to the items that grant them.
    @isHero = true
    itemThangTypes = {}
    itemThangTypes[tt.get('name')] = tt for tt in @supermodel.getModels ThangType  # Also heroes
    propsByItem = {}
    propCount = 0
    itemsByProp = {}
    @deferredDocs = {}
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
                continue if @thang.excludedProperties and prop in @thang.excludedProperties
                # Temporary: switching up method documentation for M7 levels
                continue if @options.level.get('releasePhase') is 'beta' and (prop in ['moveUp', 'moveRight', 'moveDown', 'moveLeft'])
                continue if @options.level.get('releasePhase') isnt 'beta' and (prop in ['moveTo', 'use'])
                propsByItem[item.get('name')] ?= []
                propsByItem[item.get('name')].push owner: owner, prop: prop, item: item
                itemsByProp[prop] = item
                ++propCount
      else
        console.log @thang.id, "couldn't find item ThangType for", slot, thangTypeName

    # Get any Math-, Vector-, etc.-owned properties into their own tabs
    for owner, storage of propStorage when not (owner in ['this', 'more', 'snippets', 'HTML', 'CSS', 'WebJavaScript', 'jQuery'])
      continue unless @thang[storage]?.length
      @tabs ?= {}
      @tabs[owner] = []
      programmaticonName = @thang.inventoryThangTypeNames['programming-book']
      programmaticon = itemThangTypes[programmaticonName]
      sortedProps = @thang[storage].slice().sort()
      for prop in sortedProps
        continue if @thang.excludedProperties and prop in @thang.excludedProperties
        if doc = _.find (allDocs['__' + prop] ? []), {owner: owner}  # Not all languages have all props
          if @position is 'bot'
            # Assign them to the hero
            propsByItem[owner] ?= []
            propsByItem[owner].push owner: owner, prop: prop, item: programmaticon
          else
            # Assign them to their tabs
            entry = @addEntry doc, false, false, programmaticon
            @tabs[owner].push entry

    # Assign any unassigned properties to the hero itself.
    for owner, storage of propStorage
      continue unless owner in ['this', 'more', 'snippets', 'HTML', 'CSS', 'WebJavaScript', 'jQuery']
      for prop in _.reject(@thang[storage] ? [], (prop) -> itemsByProp[prop] or prop[0] is '_')  # no private properties
        continue if prop is 'say' and @options.level.get 'hidesSay'  # Hide for Dungeon Campaign
        continue if prop is 'moveXY' and @options.level.get('slug') is 'slalom'  # Hide for Slalom
        continue if @thang.excludedProperties and prop in @thang.excludedProperties
        # Temporary: switching up method documentation for M7 levels
        continue if @options.level.get('releasePhase') is 'beta' and (prop in ['moveUp', 'moveRight', 'moveDown', 'moveLeft'])
        continue if @options.level.get('releasePhase') isnt 'beta' and (prop in ['moveTo', 'use'])
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
          return (owner is 'this' or owner is 'more') and (not doc.owner? or doc.owner is 'this' or doc.owner is 'ui')
        if not doc and not excludedDocs['__' + prop]
          console.log 'could not find doc for', prop, 'from', allDocs['__' + prop], 'for', owner, 'of', propsByItem, 'with item', item
          doc ?= prop
        if doc
          if doc.type in ['spawnable', 'event', 'handler', 'property'] or (doc.type is 'snippet' and @level.get('type') is 'game-dev')
            @deferredDocs[doc.name] = doc
          else
            @entries.push @addEntry(doc, @shortenize, owner is 'snippets', item, propIndex > 0)
    if @options.level.isType('web-dev')
      @entryGroups = _.groupBy @entries, (entry) -> entry.doc.type
    else
      @entryGroups = _.groupBy @entries, (entry) -> itemsByProp[entry.doc.name]?.get('name') ? 'Hero'
    if @position is 'bot'
      # Reorganize to balance number of entries in each group (especially useful for arenas when all properties are on hero)
      nColumns = @calculateNColumns()
      itemsPerGroup = Math.max 4, Math.ceil(propCount / nColumns)
      for group in _.keys @entryGroups
        excessGroupCounter = 1
        while @entryGroups[group].length > itemsPerGroup
          excessEntries = @entryGroups[group].splice(itemsPerGroup, itemsPerGroup)
          @entryGroups[group + " #{++excessGroupCounter}"] = excessEntries
    iOSEntryGroups = {}
    for group, entries of @entryGroups
      iOSEntryGroups[group] =
        item: {name: group, imageURL: itemThangTypes[group]?.getPortraitURL()}
        props: (entry.doc for entry in entries)
    Backbone.Mediator.publish 'tome:palette-updated', thangID: @thang.id, entryGroups: JSON.stringify(iOSEntryGroups)

  addEntry: (doc, shortenize, isSnippet=false, item=null, showImage=false) ->
    writable = (if _.isString(doc) then doc else doc.name) in (@thang.apiUserProperties ? [])
    new SpellPaletteEntryView doc: doc, thang: @thang, shortenize: shortenize, isSnippet: isSnippet, language: @options.language, writable: writable, level: @options.level, item: item, showImage: showImage, useHero: @useHero, spellPalettePosition: @position

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

  onSectionHeaderClick: (e) ->
    $et = @$(e.currentTarget)
    target = @$($et.attr('data-panel'))
    isCollapsed = !target.hasClass('in')
    if isCollapsed
      target.collapse 'show'
      $et.find('.glyphicon').removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-down')
    else
      target.collapse 'hide'
      $et.find('.glyphicon').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-right')

    setTimeout () =>
      @$('.nano').nanoScroller alwaysVisible: true
    , 200
    e.preventDefault()

  onClickClose: (e) ->
    @hide()

  hide: () =>
    @$el.find('.left .selected').removeClass 'selected'
    @$el.removeClass('open')

  onPaletteClick: (e) ->
    @$el.addClass('open')
    content = @$el.find(".rightContentTarget")
    content.html(e.entry.doc.initialHTML)
    content.i18n()
    @applyRTLIfNeeded()
    codeLanguage = e.entry.options.language
    oldEditor.destroy() for oldEditor in @aceEditors
    @aceEditors = []
    aceEditors = @aceEditors
    # Initialize Ace for each popover code snippet that still needs it
    content.find('.docs-ace').each ->
      aceEditor = aceUtils.initializeACE @, codeLanguage
      aceEditors.push aceEditor

  destroy: ->
    entry.destroy() for entry in @entries
    @toggleBackground = null
    $(window).off 'resize', @onResize
    @setupManager?.destroy()
    super()
