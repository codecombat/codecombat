require('app/styles/play/level/tome/spell-palette-view.sass')
CocoView = require 'views/core/CocoView'
{me} = require 'core/auth'
filters = require 'lib/image_filter'
SpellPaletteEntryView = require './SpellPaletteEntryView'
LevelComponent = require 'models/LevelComponent'
ThangType = require 'models/ThangType'
LevelSetupManager = require 'lib/LevelSetupManager'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'

N_ROWS = 4

module.exports = class SpellPaletteView extends CocoView
  id: 'spell-palette-view'
  template: require 'app/templates/play/level/tome/spell-palette-view'
  controlsEnabled: true
  position: 'bot'

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'surface:frame-changed': 'onFrameChanged'
    'tome:change-language': 'onTomeChangedLanguage'
    'tome:palette-clicked': 'onPaletteClick'
    'surface:stage-mouse-down': 'hide'
    'level:gather-chat-message-context': 'onGatherChatMessageContext'

  events:
    'click .closeBtn': 'onClickClose'

  initialize: (options) ->
    {@level, @session, @thang} = options
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
    @$el.toggleClass 'shortenize', Boolean @shortenize
    @$el.toggleClass 'web-dev', @options.level.isType('web-dev')

  afterInsert: ->
    super()
    _.delay => @$el?.css('bottom', 0) unless $('#spell-view').is('.shown')

  updateCodeLanguage: (language) ->
    @options.language = language

  calculateNColumns: ->
    availableWidth = @$el.find('.properties-this').innerWidth() or $('#code-area').innerWidth() - 40
    columnWidth = switch
      when @options.level.isType('web-dev') then 100
      when @shortenize then 175
      else 212
    nColumns = Math.floor availableWidth / columnWidth   # Aim to always have at least 2 columns
    @hideImages = nColumns < 2 or @options.level.isType('game-dev', 'ladder') or @entries.length > 32  # Don't show 38px images if really short on space or we don't need images
    if @hideImages
      columnWidth -= 38
      nColumns = Math.floor availableWidth / columnWidth
    Math.max 2, nColumns

  updateMaxHeight: ->
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
      minEntriesPerGroup = if @hideImages then 1 else 2  # Item portrait is two rows tall
      shortestColumn.nEntries += Math.max minEntriesPerGroup, entries.length
      shortestColumn.items.push @entryGroupElements[group]
      orderedColumns.push shortestColumn unless shortestColumn in orderedColumns
      nRows = Math.max nRows, shortestColumn.nEntries
    for column in orderedColumns
      for item in column.items
        item.detach().appendTo @$el.find('.properties-this')
    desiredHeight = 19 * (nRows + 1)
    @$el.find('.properties').css('height', desiredHeight).toggleClass 'hide-images', @hideImages

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
        doc = _.cloneDeep(doc)  # Don't accidentally modify the original copy
        allDocs['__' + doc.name] ?= []
        allDocs['__' + doc.name].push doc
        if doc.type is 'snippet' then doc.owner = 'snippets'

    if @options.programmable
      propStorage =
        'this': 'programmableProperties'
        more: 'moreProgrammableProperties'
        # We used to include a ton of this stuff, but we usually don't have space, and it's JS-specific, and it's questionably useful
        #Math: 'programmableMathProperties'
        #Array: 'programmableArrayProperties'
        #Object: 'programmableObjectProperties'
        #String: 'programmableStringProperties'
        #Global: 'programmableGlobalProperties'
        #Function: 'programmableFunctionProperties'
        #RegExp: 'programmableRegExpProperties'
        #Date: 'programmableDateProperties'
        #Number: 'programmableNumberProperties'
        #JSON: 'programmableJSONProperties'
        #LoDash: 'programmableLoDashProperties'
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
          # Assign them to the hero
          propsByItem[owner] ?= []
          propsByItem[owner].push owner: owner, prop: prop, item: programmaticon

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
        warriorHeroProps = ['warcry', 'throw', 'throwAt', 'throwPos', 'throwRange', 'shieldBubble', 'slam', 'reflect', 'forcePush', 'charismagnetize', 'stomp', 'hurl', 'absoluteShield', 'heartShield']
        continue if me.isStudent() and me.showHeroAndInventoryModalsToStudents() and (prop in warriorHeroProps)
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
            thangType = if doc.type is 'spawnable' then @getThangTypeForDoc(doc) else null
            @entries.push @addEntry(doc, @shortenize, owner is 'snippets', doc.type, propIndex > 0, thangType)
          else
            @entries.push @addEntry(doc, @shortenize, owner is 'snippets', item, propIndex > 0)
    if @options.level.isType('web-dev', 'game-dev')
      @entryGroups = _.groupBy @entries, (entry) -> entry.doc.type
    else
      @entryGroups = _.groupBy @entries, (entry) ->
        itemsByProp[entry.doc.name]?.get?('name') ? 'Hero'
    # Reorganize to balance number of entries in each group (especially useful for arenas when all properties are on hero)
    nColumns = @calculateNColumns()
    itemsPerGroup = Math.max 4, Math.ceil(propCount / nColumns)
    for group in _.keys @entryGroups
      excessGroupCounter = 1
      while @entryGroups[group].length > itemsPerGroup
        excessEntries = @entryGroups[group].splice(itemsPerGroup, itemsPerGroup)
        @entryGroups[group + " #{++excessGroupCounter}"] = excessEntries
    entryGroups = {}
    for group, entries of @entryGroups
      entryGroups[group] =
        item: {name: group, imageURL: itemThangTypes[group]?.getPortraitURL()}
        props: (entry.doc for entry in entries)
    Backbone.Mediator.publish 'tome:palette-updated', thangID: @thang.id, entryGroups: entryGroups

  addEntry: (doc, shortenize, isSnippet=false, item=null, showImage=false, thangType=null) ->
    writable = (if _.isString(doc) then doc else doc.name) in (@thang.apiUserProperties ? [])
    new SpellPaletteEntryView doc: doc, thang: @thang, thangType: thangType, shortenize: shortenize, isSnippet: isSnippet, language: @options.language, writable: writable, level: @options.level, item: item, showImage: showImage, spellPalettePosition: @position

  getThangTypeForDoc: (doc) ->
    thangName = doc.name
    if @thang.spawnAliases[thangName]
      thangName = @thang.spawnAliases[thangName][0]
    info = @thang.buildables[thangName]
    return _.find @supermodel.getModels(ThangType), (t) -> t.get('original') is info?.thangType

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

  onGatherChatMessageContext: (e) ->
    context = e.chat.context
    context.apiProperties = []
    for group, entries of @entryGroups
      for entry in entries
        if e.chat.example
          # Using entry.options.doc instead of entry.doc skips a lot of the data processing
          doc = _.omit(entry.options.doc, 'shortDescription', 'autoCompletePriority', 'snippets', 'userShouldCaptureReturn')
        else
          # Bakes in code language selection and translations
          doc = _.omit(entry.doc, 'ownerName', 'shortName', 'shorterName', 'title', 'initialHTML', 'shortDescription', 'autoCompletePriority', 'snippets', 'i18n', 'userShouldCaptureReturn')
          # TODO: remove more nested i18n
        doc.owner = 'hero' if doc.owner in ['this', 'more']
        delete doc.example unless doc.example
        delete doc.returns?.example if doc.returns and not doc.returns.example
        delete doc.returns?.description if doc.returns and not doc.returns.description
        #console.log doc
        context.apiProperties.push doc
    null

  destroy: ->
    entry.destroy() for entry in @entries
    @toggleBackground = null
    $(window).off 'resize', @onResize
    @setupManager?.destroy()
    super()
