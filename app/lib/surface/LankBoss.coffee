CocoClass = require 'core/CocoClass'
{me} = require 'core/auth'
LayerAdapter = require './LayerAdapter'
FlagLank = require 'lib/surface/FlagLank'
Lank = require 'lib/surface/Lank'
Mark = require './Mark'
Grid = require 'lib/world/Grid'
utils = require 'core/utils'

module.exports = class LankBoss extends CocoClass
  subscriptions:
    'level:set-debug': 'onSetDebug'
    'sprite:highlight-sprites': 'onHighlightSprites'
    'surface:stage-mouse-down': 'onStageMouseDown'
    'level:select-sprite': 'onSelectSprite'
    'level:suppress-selection-sounds': 'onSuppressSelectionSounds'
    'level:lock-select': 'onSetLockSelect'
    'level:restarted': 'onLevelRestarted'
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'camera:dragged': 'onCameraDragged'
    'sprite:loaded': -> @update(true)
    'level:flag-color-selected': 'onFlagColorSelected'
    'level:flag-updated': 'onFlagUpdated'
    'surface:flag-appeared': 'onFlagAppeared'
    'surface:remove-selected-flag': 'onRemoveSelectedFlag'

  constructor: (@options={}) ->
    super()
    @handleEvents = @options.handleEvents
    @gameUIState = @options.gameUIState
    @dragged = 0
    @camera = @options.camera
    @webGLStage = @options.webGLStage
    @surfaceTextLayer = @options.surfaceTextLayer
    @world = @options.world
    @options.thangTypes ?= []
    @lanks = {}
    @lankArray = []  # Mirror @lanks, but faster for when we just need to iterate
    @createLayers()
    @pendingFlags = []
    if not @handleEvents
      @listenTo @gameUIState, 'change:selected', @onChangeSelected

  destroy: ->
    @removeLank lank for thangID, lank of @lanks
    @targetMark?.destroy()
    @selectionMark?.destroy()
    lankLayer.destroy() for lankLayer in _.values @layerAdapters
    super()

  toString: -> "<LankBoss: #{@lankArray.length} lanks>"

  thangTypeFor: (type) ->
    _.find @options.thangTypes, (m) -> m.get('original') is type or m.get('name') is type

  createLayers: ->
    @layerAdapters = {}
    for [name, priority] in [
      ['Land', -40]
      ['Ground', -30]
      ['Obstacle', -20]
      ['Path', -10]
      ['Default', 0]
      ['Floating', 10]
    ]
      @layerAdapters[name] = new LayerAdapter name: name, webGL: true, layerPriority: priority, transform: LayerAdapter.TRANSFORM_SURFACE, camera: @camera
    @webGLStage.addChild (lankLayer.container for lankLayer in _.values(@layerAdapters))...

  layerForChild: (child, lank) ->
    unless child.layerPriority?
      if thang = lank?.thang
        child.layerPriority = thang.layerPriority
        child.layerPriority ?= 0 if thang.isSelectable
        child.layerPriority ?= -40 if thang.isLand
    child.layerPriority ?= 0
    return @layerAdapters['Default'] unless child.layerPriority
    layer = _.findLast @layerAdapters, (layer, name) ->
      layer.layerPriority <= child.layerPriority
    layer ?= @layerAdapters['Land'] if child.layerPriority < -40
    layer ? @layerAdapters['Default']

  addLank: (lank, id=null, layer=null) ->
    id ?= lank.thang.id
    console.error 'Lank collision! Already have:', id if @lanks[id]
    @lanks[id] = lank
    @lankArray.push lank
    layer ?= @layerAdapters['Obstacle'] if lank.thang?.spriteName.search(/(dungeon|indoor|ice|classroom|vr).wall/i) isnt -1
    layer ?= @layerForChild lank.sprite, lank
    layer.addLank lank
    layer.updateLayerOrder()
    lank

  createMarks: ->
    @targetMark = new Mark name: 'target', camera: @camera, layer: @layerAdapters['Ground'], thangType: 'target'
    @selectionMark = new Mark name: 'selection', camera: @camera, layer: @layerAdapters['Ground'], thangType: 'selection'

  createLankOptions: (options) ->
    _.extend options, {
      @camera
      resolutionFactor: SPRITE_RESOLUTION_FACTOR
      groundLayer: @layerAdapters['Ground']
      textLayer: @surfaceTextLayer
      floatingLayer: @layerAdapters['Floating']
      showInvisible: @options.showInvisible
      @gameUIState
      @handleEvents
    }

  onSetDebug: (e) ->
    return if e.debug is @debug
    @debug = e.debug
    lank.setDebug @debug for lank in @lankArray

  onHighlightSprites: (e) ->
    highlightedIDs = e.thangIDs or []
    for thangID, lank of @lanks
      lank.setHighlight? thangID in highlightedIDs, e.delay

  addThangToLanks: (thang, layer=null) ->
    return console.warn 'Tried to add Thang to the surface it already has:', thang.id if @lanks[thang.id]
    thangType = _.find @options.thangTypes, (m) ->
      return false unless m.get('actions') or m.get('raster')
      return m.get('name') is thang.spriteName
    thangType ?= _.find @options.thangTypes, (m) -> return m.get('name') is thang.spriteName
    return console.error "Couldn't find ThangType for", thang unless thangType

    options = @createLankOptions thang: thang
    options.resolutionFactor = if thangType.get('kind') is 'Floor' then 2 else SPRITE_RESOLUTION_FACTOR
    if @options.playerNames and /Hero Placeholder/.test thang.id
      options.playerName = @options.playerNames[thang.team]
    lank = new Lank thangType, options
    @listenTo lank, 'sprite:mouse-up', @onLankMouseUp
    @addLank lank, null, layer
    lank.setDebug @debug
    lank

  removeLank: (lank) ->
    lank.layer.removeLank(lank)
    thang = lank.thang
    delete @lanks[lank.thang.id]
    @lankArray.splice @lankArray.indexOf(lank), 1
    @stopListening lank
    lank.destroy()
    lank.thang = thang  # Keep around so that we know which thang the destroyed thang was for

  updateSounds: ->
    lank.playSounds() for lank in @lankArray  # hmm; doesn't work for lanks which we didn't add yet in adjustLankExistence

  update: (frameChanged) ->
    @adjustLankExistence() if frameChanged
    lank.update frameChanged for lank in @lankArray
    @updateSelection()
    @layerAdapters['Default'].updateLayerOrder()
    @cacheObstacles()

  adjustLankExistence: ->
    # Add anything new, remove anything old, update everything current
    updatedObstacles = []
    itemsJustEquipped = []
    for thang in @world.thangs when thang.exists and thang.pos
      itemsJustEquipped = itemsJustEquipped.concat @equipNewItems thang if thang.equip
      if lank = @lanks[thang.id]
        lank.setThang thang  # make sure Lank has latest Thang
      else
        lank = @addThangToLanks(thang)
        Backbone.Mediator.publish 'surface:new-thang-added', thang: thang, sprite: lank
        updatedObstacles.push lank if lank.sprite.parent is @layerAdapters['Obstacle']
        lank.playSounds()
    item.modifyStats() for item in itemsJustEquipped
    for thangID, lank of @lanks
      missing = not (lank.notOfThisWorld or @world.thangMap[thangID]?.exists)
      isObstacle = lank.sprite.parent is @layerAdapters['Obstacle']
      updatedObstacles.push lank if isObstacle and (missing or lank.hasMoved)
      lank.hasMoved = false
      @removeLank lank if missing
    @cacheObstacles updatedObstacles if updatedObstacles.length and @cachedObstacles

    # mainly for handling selecting thangs from session when the thang is not always in existence
    if @willSelectThang and @lanks[@willSelectThang[0]]
      @selectThang @willSelectThang...

    @updateScreenReader()

  updateScreenReader: ->
    # Testing ASCII map for screen readers
    return unless me.get('name') is 'zersiax'  #in ['zersiax', 'Nick']
    ascii = $('#ascii-surface')
    thangs = (lank.thang for lank in @lankArray)
    grid = new Grid thangs, @world.width, @world.height, 0, 0, 0, true
    utils.replaceText ascii, grid.toString true
    ascii.css 'transform', 'initial'
    fullWidth = ascii.innerWidth()
    fullHeight = ascii.innerHeight()
    availableWidth = ascii.parent().innerWidth()
    availableHeight = ascii.parent().innerHeight()
    scale = availableWidth / fullWidth
    scale = Math.min scale, availableHeight / fullHeight
    ascii.css 'transform', "scale(#{scale})"

  equipNewItems: (thang) ->
    itemsJustEquipped = []
    if thang.equip and not thang.equipped
      thang.equip()  # Pretty hacky, but needed since initialize may not be called if we're not running Systems.
      itemsJustEquipped.push thang
    if thang.inventoryIDs
      # Even hackier: these items were only created/equipped during simulation, so we reequip here.
      for slot, itemID of thang.inventoryIDs
        item = @world.getThangByID itemID
        unless item.equipped
          console.log thang.id, 'equipping', item, 'in', thang.slot, 'Surface-side, but it cannot equip?' unless item.equip
          item.equip?()
          itemsJustEquipped.push item if item.equip
    return itemsJustEquipped

  cacheObstacles: (updatedObstacles=null) ->
    return if @cachedObstacles and not updatedObstacles
    lankArray = @lankArray
    wallLanks = (lank for lank in lankArray when lank.thangType?.get('name').search(/(dungeon|indoor|ice|classroom|vr).wall/i) isnt -1)
    return if _.any (s.stillLoading for s in wallLanks)
    walls = (lank.thang for lank in wallLanks)
    @world.calculateBounds()
    wallGrid = new Grid walls, @world.width, @world.height
    if updatedObstacles
      possiblyUpdatedWallLanks = (lank for lank in wallLanks when _.find updatedObstacles, (w2) -> lank is w2 or (Math.abs(lank.thang.pos.x - w2.thang.pos.x) + Math.abs(lank.thang.pos.y - w2.thang.pos.y)) <= 16)
    else
      possiblyUpdatedWallLanks = wallLanks
#    console.log 'updating up to', possiblyUpdatedWallLanks.length, 'of', wallLanks.length, 'wall lanks from updatedObstacles', updatedObstacles
    for wallLank in possiblyUpdatedWallLanks
      wallLank.queueAction 'idle' if not wallLank.currentRootAction
      wallLank.lockAction(false)
      wallLank.updateActionDirection wallGrid
      wallLank.lockAction(true)
      wallLank.updateScale()
      wallLank.updatePosition()
#    console.log wallGrid.toString()
    @cachedObstacles = true

  lankFor: (thangID) -> @lanks[thangID]

  onNewWorld: (e) ->
    @world = @options.world = e.world
    # Clear obstacle cache for this level, since we are spawning walls dynamically
    @cachedObstacles = false if e.finished and /kithgard-mastery/.test window.location.href

  play: ->
    lank.play() for lank in @lankArray
    @selectionMark?.play()
    @targetMark?.play()

  stop: ->
    lank.stop() for lank in @lankArray
    @selectionMark?.stop()
    @targetMark?.stop()

  # Selection

  onSuppressSelectionSounds: (e) -> @suppressSelectionSounds = e.suppress
  onSetLockSelect: (e) -> @selectLocked = e.lock
  onLevelRestarted: (e) ->
    @selectLocked = false
    @selectLank e, null

  onSelectSprite: (e) ->
    @selectThang e.thangID, e.spellName

  onCameraDragged: ->
    @dragged += 1

  onLankMouseUp: (e) ->
    return unless @handleEvents
    return if key.shift #and @options.choosing
    return @dragged = 0 if @dragged > 3
    @dragged = 0
    lank = if e.sprite?.thang?.isSelectable then e.sprite else null
    return if @flagCursorLank and lank?.thangType.get('name') is 'Flag'
    @selectLank e, lank

  onStageMouseDown: (e) ->
    return unless @handleEvents
    return if key.shift #and @options.choosing
    @selectLank e if e.onBackground

  onChangeSelected: (gameUIState, selected) ->
    oldLanks = (s.sprite for s in gameUIState.previousAttributes().selected or [])
    newLanks = (s.sprite for s in selected or [])
    addedLanks = _.difference(newLanks, oldLanks)
    removedLanks = _.difference(oldLanks, newLanks)

    for lank in addedLanks
      layer = if lank.sprite.parent isnt @layerAdapters.Default.container then @layerAdapters.Default else @layerAdapters.Ground
      mark = new Mark name: 'selection', camera: @camera, layer: layer, thangType: 'selection'
      mark.toggle true
      mark.setLank(lank)
      mark.update()
      lank.marks.selection = mark # TODO: Figure out how to non-hackily assign lank this mark
      
    for lank in removedLanks
      lank.removeMark?('selection')

  selectThang: (thangID, spellName=null, treemaThangSelected = null) ->
    return @willSelectThang = [thangID, spellName] unless @lanks[thangID]
    @selectLank null, @lanks[thangID], spellName, treemaThangSelected

  selectLank: (e, lank=null, spellName=null, treemaThangSelected = null) ->
    return if e and (@disabled or @selectLocked)  # Ignore clicks for selection/panning/wizard movement while disabled or select is locked
    worldPos = lank?.thang?.pos
    worldPos ?= @camera.screenToWorld {x: e.originalEvent.rawX, y: e.originalEvent.rawY} if e?.originalEvent
    if @handleEvents
      if (not @reallyStopMoving) and worldPos and (@options.navigateToSelection or not lank or treemaThangSelected) and e?.originalEvent?.nativeEvent?.which isnt 3
        @camera.zoomTo(lank?.sprite or @camera.worldToSurface(worldPos), @camera.zoom, 1000, true)
    lank = null if @options.choosing  # Don't select lanks while choosing
    if lank isnt @selectedLank
      @selectedLank?.selected = false
      lank?.selected = true
      @selectedLank = lank
    alive = lank and not (lank.thang.health < 0)

    Backbone.Mediator.publish 'surface:sprite-selected',
      thang: if lank then lank.thang else null
      sprite: lank
      spellName: spellName ? e?.spellName
      originalEvent: e
      worldPos: worldPos

    @willSelectThang = null if lank  # Now that we've done a real selection, don't reselect some other Thang later.

    if alive and not @suppressSelectionSounds
      instance = lank.playSound 'selected'
      if instance?.playState is 'playSucceeded'
        Backbone.Mediator.publish 'sprite:thang-began-talking', thang: lank?.thang
        instance.addEventListener 'complete', ->
          Backbone.Mediator.publish 'sprite:thang-finished-talking', thang: lank?.thang

  onFlagColorSelected: (e) ->
    @removeLank @flagCursorLank if @flagCursorLank
    @flagCursorLank = null
    for flagLank in @lankArray when flagLank.thangType.get('name') is 'Flag'
      flagLank.sprite.cursor = if e.color then 'crosshair' else 'pointer'
    return unless e.color
    @flagCursorLank = new FlagLank @thangTypeFor('Flag'), @createLankOptions(thangID: 'Flag Cursor', color: e.color, team: me.team, isCursor: true, pos: e.pos)
    @addLank @flagCursorLank, @flagCursorLank.thang.id, @layerAdapters['Floating']

  onFlagUpdated: (e) ->
    return unless e.active
    pendingFlag = new FlagLank @thangTypeFor('Flag'), @createLankOptions(thangID: 'Pending Flag ' + Math.random(), color: e.color, team: e.team, isCursor: false, pos: e.pos)
    @addLank pendingFlag, pendingFlag.thang.id, @layerAdapters['Floating']
    @pendingFlags.push pendingFlag

  onFlagAppeared: (e) ->
    # Remove the pending flag that matches this one's color/team/position, and any color/team matches placed earlier.
    t1 = e.sprite.thang
    pending = (@pendingFlags ? []).slice()
    foundExactMatch = false
    for i in [pending.length - 1 .. 0] by -1
      pendingFlag = pending[i]
      t2 = pendingFlag.thang
      matchedType = t1.color is t2.color and t1.team is t2.team
      matched = matchedType and (foundExactMatch or Math.abs(t1.pos.x - t2.pos.x) < 0.00001 and Math.abs(t1.pos.y - t2.pos.y) < 0.00001)
      if matched
        foundExactMatch = true
        @pendingFlags.splice(i, 1)
        @removeLank pendingFlag
    e.sprite.sprite?.cursor = if @flagCursorLank then 'crosshair' else 'pointer'
    null

  onRemoveSelectedFlag: (e) ->
    # Remove the selected lank if it's a flag, or any flag of the given color if a color is given.
    flagLank = _.find [@selectedLank].concat(@lankArray), (lank) ->
      lank and lank.thangType.get('name') is 'Flag' and lank.thang.team is me.team and (lank.thang.color is e.color or not e.color) and not lank.notOfThisWorld
    return unless flagLank
    Backbone.Mediator.publish 'surface:remove-flag', color: flagLank.thang.color

  # Marks

  updateSelection: ->
    if @selectedLank?.thang and (not @selectedLank.thang.exists or not @world.getThangByID @selectedLank.thang.id)
      thangID = @selectedLank.thang.id
      @selectedLank = null  # Don't actually trigger deselection, but remove the selected lank.
      @selectionMark?.toggle false
      @willSelectThang = [thangID, null]
    @updateTarget()
    return unless @selectionMark
    @selectedLank = null if @selectedLank and (@selectedLank.destroyed or not @selectedLank.thang)
    # The selection mark should be on the ground layer, unless we're not a normal lank (like a wall), in which case we'll place it higher so we can see it.
    if @selectedLank and @selectedLank.sprite.parent isnt @layerAdapters.Default.container
      @selectionMark.setLayer @layerAdapters.Default
    else if @selectedLank
      @selectionMark.setLayer @layerAdapters.Ground
    @selectionMark.toggle @selectedLank?
    @selectionMark.setLank @selectedLank
    @selectionMark.update()

  updateTarget: ->
    return unless @targetMark
    thang = @selectedLank?.thang
    target = thang?.target
    targetPos = thang?.targetPos
    targetPos = null if targetPos?.isZero?()  # Null targetPos get serialized as (0, 0, 0)
    @targetMark.setLank if target then @lanks[target.id] else null
    @targetMark.toggle @targetMark.lank or targetPos
    @targetMark.update if targetPos then @camera.worldToSurface targetPos else null
