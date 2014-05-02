CocoClass = require 'lib/CocoClass'
{me} = require 'lib/auth'
Layer = require './Layer'
IndieSprite = require 'lib/surface/IndieSprite'
WizardSprite = require 'lib/surface/WizardSprite'
CocoSprite = require 'lib/surface/CocoSprite'
Mark = require './Mark'
Grid = require 'lib/world/Grid'

module.exports = class SpriteBoss extends CocoClass
  subscriptions:
    'bus:player-joined': 'onPlayerJoined'
    'bus:player-left': 'onPlayerLeft'
    'level-set-debug': 'onSetDebug'
    'level-highlight-sprites': 'onHighlightSprites'
    'sprite:mouse-up': 'onSpriteMouseUp'
    'surface:stage-mouse-down': 'onStageMouseDown'
    'level-select-sprite': 'onSelectSprite'
    'level-suppress-selection-sounds': 'onSuppressSelectionSounds'
    'level-lock-select': 'onSetLockSelect'
    'level:restarted': 'onLevelRestarted'
    'god:new-world-created': 'onNewWorld'
    'tome:cast-spells': 'onCastSpells'
    'camera:dragged': 'onCameraDragged'
    'sprite:loaded': -> @update(true)

  constructor: (@options) ->
    super()
    @dragged = 0
    @options ?= {}
    @camera = @options.camera
    @surfaceLayer = @options.surfaceLayer
    @surfaceTextLayer = @options.surfaceTextLayer
    @world = options.world
    @options.thangTypes ?= []
    @sprites = {}
    @spriteArray = []  # Mirror @sprites, but faster for when we just need to iterate
    @selfWizardSprite = null
    @createLayers()
    @spriteSheetCache = {}

  destroy: ->
    @removeSprite sprite for thangID, sprite of @sprites
    @targetMark?.destroy()
    @selectionMark?.destroy()
    super()

  toString: -> "<SpriteBoss: #{@spriteArray.length} sprites>"

  thangTypeFor: (type) ->
    _.find @options.thangTypes, (m) -> m.get('original') is type or m.get('name') is type

  createLayers: ->
    @spriteLayers = {}
    for [name, priority] in [
      ["Land", -40]
      ["Ground", -30]
      ["Obstacle", -20]
      ["Path", -10]
      ["Default", 0]
      ["Floating", 10]
    ]
      @spriteLayers[name] = new Layer name: name, layerPriority: priority, transform: Layer.TRANSFORM_CHILD, camera: @camera
    @surfaceLayer.addChild _.values(@spriteLayers)...

  layerForChild: (child, sprite) ->
    unless child.layerPriority?
      # TODO: make better system
      child.layerPriority = 0 if sprite?.thang?.isSelectable
      child.layerPriority = -40 if sprite?.thang?.isLand
    return @spriteLayers["Default"] unless child.layerPriority
    layer = _.findLast @spriteLayers, (layer, name) ->
      layer.layerPriority <= child.layerPriority
    #console.log "layer for", child, "is", (layer ? @spriteLayers["Default"])
    layer ? @spriteLayers["Default"]

  addSprite: (sprite, id=null, layer=null) ->
    id ?= sprite.thang.id
    console.error "Sprite collision! Already have:", id if @sprites[id]
    @sprites[id] = sprite
    @spriteArray.push sprite
    layer ?= @spriteLayers["Obstacle"] if sprite.thang?.spriteName.search(/(dungeon|indoor).wall/i) isnt -1
    layer ?= @layerForChild sprite.displayObject, sprite
    layer.addChild sprite.displayObject
    layer.updateLayerOrder()
    sprite

  createMarks: ->
    @targetMark = new Mark name: 'target', camera: @camera, layer: @spriteLayers["Ground"], thangType: 'target'
    @selectionMark = new Mark name: 'selection', camera: @camera, layer: @spriteLayers["Ground"], thangType: 'selection'

  createSpriteOptions: (options) ->
    _.extend options, camera: @camera, resolutionFactor: 4, groundLayer: @spriteLayers["Ground"], textLayer: @surfaceTextLayer, floatingLayer: @spriteLayers["Floating"], spriteSheetCache: @spriteSheetCache, showInvisible: @options.showInvisible

  createIndieSprites: (indieSprites, withWizards) ->
    unless @indieSprites
      @indieSprites = []
      @indieSprites = (@createIndieSprite indieSprite for indieSprite in indieSprites) if indieSprites
    if withWizards and not @selfWizardSprite
      @selfWizardSprite = @createWizardSprite thangID: "My Wizard", isSelf: true, sprites: @sprites

  createIndieSprite: (indieSprite) ->
    unless thangType = @thangTypeFor indieSprite.thangType
      console.warn "Need to convert #{indieSprite.id}'s ThangType #{indieSprite.thangType} to a ThangType reference. Until then, #{indieSprite.id} won't show up."
      return
    sprite = new IndieSprite thangType, @createSpriteOptions {thangID: indieSprite.id, pos: indieSprite.pos, sprites: @sprites, colorConfig: indieSprite.colorConfig}
    @addSprite sprite, sprite.thang.id

  createOpponentWizard: (opponent) ->
    # TODO: colorize name and cloud by team, colorize wizard by user's color config, level-specific wizard spawn points
    sprite = @createWizardSprite thangID: opponent.id, name: opponent.name
    if not opponent.levelSlug or opponent.levelSlug is "brawlwood"
      sprite.targetPos = if opponent.team is 'ogres' then {x: 52, y: 52} else {x: 28, y: 28}
    else if opponent.levelSlug is "dungeon-arena"
      sprite.targetPos = if opponent.team is 'ogres' then {x:72, y: 39} else {x: 9, y:39}
    else
      sprite.targetPos = if opponent.team is 'ogres' then {x:52, y: 28} else {x: 20, y:28}

  createWizardSprite: (options) ->
    sprite = new WizardSprite @thangTypeFor("Wizard"), @createSpriteOptions(options)
    @addSprite sprite, sprite.thang.id, @spriteLayers["Floating"]

  onPlayerJoined: (e) ->
    # Create another WizardSprite, unless this player is just me
    pid = e.player.id
    return if pid is me.id
    wiz = @createWizardSprite thangID: pid, sprites: @sprites
    wiz.animateIn()
    state = e.player.wizard or {}
    wiz.setInitialState(state.targetPos, @sprites[state.targetSprite])

  onPlayerLeft: (e) ->
    pid = e.player.id
    @sprites[pid]?.animateOut => @removeSprite @sprites[pid]

  onSetDebug: (e) ->
    return if e.debug is @debug
    @debug = e.debug
    sprite.setDebug @debug for sprite in @spriteArray

  onHighlightSprites: (e) ->
    highlightedIDs = e.thangIDs or []
    for thangID, sprite of @sprites
      sprite.setHighlight? thangID in highlightedIDs, e.delay

  addThangToSprites: (thang, layer=null) ->
    return console.warn 'Tried to add Thang to the surface it already has:', thang.id if @sprites[thang.id]
    thangType = _.find @options.thangTypes, (m) -> m.get('name') is thang.spriteName
    options = @createSpriteOptions thang: thang
    options.resolutionFactor = if thangType.get('kind') is 'Floor' then 2 else 4
    sprite = new CocoSprite thangType, options
    @addSprite sprite, null, layer
    sprite.setDebug @debug
    sprite

  removeSprite: (sprite) ->
    sprite.displayObject.parent.removeChild sprite.displayObject
    thang = sprite.thang
    delete @sprites[sprite.thang.id]
    @spriteArray.splice @spriteArray.indexOf(sprite), 1
    sprite.destroy()
    sprite.thang = thang  # Keep around so that we know which thang the destroyed thang was for

  updateSounds: ->
    sprite.playSounds() for sprite in @spriteArray  # hmm; doesn't work for sprites which we didn't add yet in adjustSpriteExistence

  update: (frameChanged) ->
    @adjustSpriteExistence() if frameChanged
    sprite.update frameChanged for sprite in @spriteArray
    @updateSelection()
    @spriteLayers["Default"].updateLayerOrder()
    @cache()

  adjustSpriteExistence: ->
    # Add anything new, remove anything old, update everything current
    updateCache = false
    for thang in @world.thangs when thang.exists
      if sprite = @sprites[thang.id]
        sprite.setThang thang  # make sure Sprite has latest Thang
      else
        sprite = @addThangToSprites(thang)
        Backbone.Mediator.publish 'surface:new-thang-added', thang:thang, sprite:sprite
        updateCache = updateCache or sprite.displayObject.parent is @spriteLayers["Obstacle"]
        sprite.playSounds()
    for thangID, sprite of @sprites
      missing = not (sprite.notOfThisWorld or @world.thangMap[thangID]?.exists)
      isObstacle = sprite.displayObject.parent is @spriteLayers["Obstacle"]
      updateCache = updateCache or (isObstacle and (missing or sprite.hasMoved))
      sprite.hasMoved = false
      @removeSprite sprite if missing
    @cache true if updateCache and @cached

    # mainly for handling selecting thangs from session when the thang is not always in existence
    if @willSelectThang and @sprites[@willSelectThang[0]]
      @selectThang @willSelectThang...

  cache: (update=false) ->
    return if @cached and not update
    wallSprites = (sprite for sprite in @spriteArray when sprite.thangType?.get('name').search(/(dungeon|indoor).wall/i) isnt -1)
    walls = (sprite.thang for sprite in wallSprites)
    @world.calculateBounds()
    wallGrid = new Grid walls, @world.size()...
    for wallSprite in wallSprites
      wallSprite.updateActionDirection wallGrid
      wallSprite.updateScale()
      wallSprite.updatePosition()
    #console.log @wallGrid.toString()
    @spriteLayers["Obstacle"].uncache() if @spriteLayers["Obstacle"].cacheID  # might have changed sizes
    @spriteLayers["Obstacle"].cache()
    # test performance of doing land layer, too, to see if it's faster
    #@spriteLayers["Land"].uncache() if @spriteLayers["Land"].cacheID  # might have changed sizes
    #@spriteLayers["Land"].cache()
    @cached = true

  spriteFor: (thangID) -> @sprites[thangID]

  onNewWorld: (e) ->
    @world = @options.world = e.world
    @play()

  onCastSpells: -> @stop()

  play: ->
    sprite.imageObject.play() for sprite in @spriteArray
    @selectionMark?.play()
    @targetMark?.play()

  stop: ->
    sprite.imageObject.stop() for sprite in @spriteArray
    @selectionMark?.stop()
    @targetMark?.stop()

  # Selection

  onSuppressSelectionSounds: (e) -> @suppressSelectionSounds = e.suppress
  onSetLockSelect: (e) -> @selectLocked = e.lock
  onLevelRestarted: (e) ->
    @selectLocked = false
    @selectSprite e, null

  onSelectSprite: (e) ->
    @selectThang e.thangID, e.spellName

  onCameraDragged: ->
    @dragged += 1

  onSpriteMouseUp: (e) ->
    return if key.shift #and @options.choosing
    return @dragged = 0 if @dragged > 3
    @dragged = 0
    sprite = if e.sprite?.thang?.isSelectable then e.sprite else null
    @selectSprite e, sprite

  onStageMouseDown: (e) ->
    return if key.shift #and @options.choosing
    @selectSprite e if e.onBackground

  selectThang: (thangID, spellName=null, treemaThangSelected = null) ->
    return @willSelectThang = [thangID, spellName] unless @sprites[thangID]
    @selectSprite null, @sprites[thangID], spellName, treemaThangSelected

  selectSprite: (e, sprite=null, spellName=null, treemaThangSelected = null) ->
    return if e and (@disabled or @selectLocked)  # Ignore clicks for selection/panning/wizard movement while disabled or select is locked
    worldPos = sprite?.thang?.pos
    worldPos ?= @camera.canvasToWorld {x: e.originalEvent.rawX, y: e.originalEvent.rawY} if e
    if worldPos and (@options.navigateToSelection or not sprite or treemaThangSelected)
      @camera.zoomTo(sprite?.displayObject or @camera.worldToSurface(worldPos), @camera.zoom, 1000)
    sprite = null if @options.choosing  # Don't select sprites while choosing
    if sprite isnt @selectedSprite
      @selectedSprite?.selected = false
      sprite?.selected = true
      @selectedSprite = sprite
    alive = sprite?.thang.health > 0

    Backbone.Mediator.publish 'surface:sprite-selected',
      thang: if sprite then sprite.thang else null
      sprite: sprite
      spellName: spellName ? e?.spellName
      originalEvent: e
      worldPos: worldPos

    @willSelectThang = null if sprite  # Now that we've done a real selection, don't reselect some other Thang later.

    if alive and not @suppressSelectionSounds
      instance = sprite.playSound 'selected'
      if instance?.playState is 'playSucceeded'
        Backbone.Mediator.publish 'thang-began-talking', thang: sprite?.thang
        instance.addEventListener 'complete', ->
          Backbone.Mediator.publish 'thang-finished-talking', thang: sprite?.thang


  # Marks

  updateSelection: ->
    if @selectedSprite?.thang and (not @selectedSprite.thang.exists or not @world.getThangByID @selectedSprite.thang.id)
      thangID = @selectedSprite.thang.id
      @selectedSprite = null  # Don't actually trigger deselection, but remove the selected sprite.
      @selectionMark?.toggle false
      @willSelectThang = [thangID, null]
    @updateTarget()
    return unless @selectionMark
    @selectedSprite = null if @selectedSprite and (@selectedSprite.destroyed or not @selectedSprite.thang)
    @selectionMark.toggle @selectedSprite?
    @selectionMark.setSprite @selectedSprite
    @selectionMark.update()

  updateTarget: ->
    return unless @targetMark
    thang = @selectedSprite?.thang
    target = thang?.target
    targetPos = thang?.targetPos
    targetPos = null if targetPos?.isZero?()  # Null targetPos get serialized as (0, 0, 0)
    @targetMark.setSprite if target then @sprites[target.id] else null
    @targetMark.toggle @targetMark.sprite or targetPos
    @targetMark.update if targetPos then @camera.worldToSurface targetPos else null
