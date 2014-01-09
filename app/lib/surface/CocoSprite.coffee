CocoClass = require 'lib/CocoClass'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
{createProgressBar} = require './sprite_utils'
Camera = require './Camera'
Mark = require './Mark'
Label = require './Label'
AudioPlayer = require 'lib/AudioPlayer'

# We'll get rid of this once level's teams actually have colors
healthColors =
  ogres: [64, 128, 212]
  humans: [255, 0, 0]
  neutral: [64, 212, 128]

# Sprite: EaselJS-based view/controller for Thang model
module.exports = CocoSprite = class CocoSprite extends CocoClass
  thangType: null # ThangType instance

  displayObject: null
  imageObject: null

  healthBar: null
  marks: null
  labels: null

  options:
    resolutionFactor: 4
    groundLayer: null
    textLayer: null
    floatingLayer: null
    frameRateFactor: 1  # TODO: use or lose?
    thang: null
    camera: null
    spriteSheetCache: null
    showInvisible: false

  flipped: false
  flippedCount: 0
  originalScaleX: null
  originalScaleY: null
  actionQueue: null
  actions: null
  rotation: 0

  # ACTION STATE
  # Actions have relations. If you say 'move', 'move_side' may play because of a direction
  # relationship, and if you say 'cast', 'cast_begin' may happen first, or 'cast_end' after.
  currentRootAction: null  # action that, in general, is playing or will play
  currentAction: null  # related action that is right now playing

  subscriptions:
    'level-sprite-dialogue': 'onDialogue'
    'level-sprite-clear-dialogue': 'onClearDialogue'
    'level-set-letterbox': 'onSetLetterbox'
    'surface:ticked': 'onSurfaceTicked'

  constructor: (@thangType, options) ->
    super()    
    @options = _.extend(_.cloneDeep(@options), options)
    @setThang @options.thang
    console.error @toString(), "has no ThangType!" unless @thangType
    @actionQueue = []
    @marks = {}
    @labels = {}
    @actions = @thangType.getActions()
    @buildFromSpriteSheet @buildSpriteSheet()
    @ticker = 0

  destroy: ->
    super()
    mark.destroy() for name, mark of @marks
    label.destroy() for name, label of @labels

  toString: -> "<CocoSprite: #{@thang?.id}>"

  spriteSheetKey: ->
    "#{@thangType.get('name')} - #{@options.resolutionFactor}"

  buildSpriteSheet: -> @thangType.getSpriteSheet @options

  buildFromSpriteSheet: (spriteSheet) ->
    if spriteSheet
      sprite = new createjs.Sprite(spriteSheet)
    else
      sprite = new createjs.Shape()
    sprite.scaleX = sprite.scaleY = 1 / @options.resolutionFactor
    # temp, until these are re-exported with perspective
    if @options.camera and @thangType.get('name') in ['Dungeon Floor', 'Grass', 'Goal Trigger', 'Obstacle']  
      sprite.scaleY *= @options.camera.y2x
    @displayObject = new createjs.Container()
    @imageObject = sprite
    @displayObject.addChild(sprite)
    @addHealthBar()
    @configureMouse()
    # TODO: generalize this later?
    @originalScaleX = sprite.scaleX
    @originalScaleY = sprite.scaleY
    @displayObject.sprite = @
    @displayObject.layerPriority = @thangType.get 'layerPriority'
    @displayObject.name = @thang?.spriteName or @thangType.get 'name'
    @imageObject.on 'animationend', @onActionEnd

  ##################################################
  # QUEUEING AND PLAYING ACTIONS

  queueAction: (action) ->
    # The normal way to have an action play
    action = @actions[action] if _.isString(action)
    action ?= @actions.idle
    @actionQueue = []
    @actionQueue.push @currentRootAction.relatedActions.end if @currentRootAction?.relatedActions?.end
    @actionQueue.push action.relatedActions.begin if action.relatedActions?.begin
    @actionQueue.push action
    @currentRootAction = action
    @playNextAction()

  onActionEnd: (e) => @playNextAction()
  onSurfaceTicked: -> @ticker += 1

  playNextAction: ->
    @playAction(@actionQueue.splice(0,1)[0]) if @actionQueue.length

  playAction: (action) ->
    @currentAction = action
    return @updateActionDirection() unless action.animation or action.container
    m = if action.container then "gotoAndStop" else "gotoAndPlay"
    @imageObject[m] action.name
    @imageObject.framerate = action.framerate or 20
    reg = @getOffset 'registration'
    @imageObject.regX = -reg.x
    @imageObject.regY = -reg.y
    if @currentRootAction.name is 'move' and action.frames
      start = Math.floor(Math.random() * action.frames.length)
      @imageObject.currentAnimationFrame = start

  update: ->
    # Gets the sprite to reflect what the current state of the thangs and surface are
    @updatePosition()
    @updateScale()
    @updateAlpha()
    @updateRotation()
    @updateAction()
    @updateStats()
    @updateMarks()
    @updateLabels()

  cache: ->
    bounds = @imageObject.getBounds()
    @displayObject.cache 0, 0, bounds.width, bounds.height
    #console.log "just cached", @thang.id, "which was at", @imageObject.x, @imageObject.y, bounds.width, bounds.height, "with scale", Math.max(@imageObject.scaleX, @imageObject.scaleY)

  updatePosition: ->
    return unless @thang?.pos and @options.camera?
    if @thang.bobHeight                        
      @thang.pos.z = @thang.pos.z + (Math.sin @ticker /  @thang.bobTime) * 0.1 * @thang.bobHeight
    [p0, p1] = [@lastPos, @thang.pos]
    return if p0 and p0.x is p1.x and p0.y is p1.y and p0.z is p1.z and not @options.camera.tweeningZoomTo
    wop = x: p1.x, y: p1.y, z: if @thang.isLand then 0 else p1.z - @thang.depth / 2
    sup = @options.camera.worldToSurface wop
    [@displayObject.x, @displayObject.y] = [sup.x, sup.y]
    @lastPos = _.clone(p1)
    @hasMoved = true

  updateScale: ->
    if @thangType.get('matchWorldDimensions') and @thang
      if @thang.width isnt @lastThangWidth or @thang.height isnt @lastThangHeight
        [@lastThangWidth, @lastThangHeight] = [@thang.width, @thang.height]
        bounds = @imageObject.getBounds()
        @imageObject.scaleX = @thang.width * Camera.PPM / bounds.width * @thangType.get('scale') ? 1
        @imageObject.scaleY = @thang.height * Camera.PPM * @options.camera.y2x / bounds.height * @thangType.get('scale') ? 1
      return
    scaleX = if @getActionProp 'flipX' then -1 else 1
    scaleY = if @getActionProp 'flipY' then -1 else 1
    scaleFactor = @thang.scaleFactor ? 1
    @imageObject.scaleX = @originalScaleX * scaleX * scaleFactor
    @imageObject.scaleY = @originalScaleY * scaleY * scaleFactor

  updateAlpha: ->
    return unless @thang?.alpha?
    @imageObject.alpha = @thang.alpha
    if @options.showInvisible
      @imageObject.alpha = Math.max 0.5, @imageObject.alpha

  updateRotation: (imageObject) ->
    rotationType = @thangType.get('rotationType')
    return if rotationType is 'fixed'
    rotation = @getRotation()
    imageObject ?= @imageObject
    return imageObject.rotation = rotation if not rotationType
    @updateIsometricRotation(rotation, imageObject)

  getRotation: ->
    return @rotation if not @thang?.rotation
    rotation = @thang?.rotation
    rotation = (360 - (rotation * 180 / Math.PI) % 360) % 360
    rotation -= 360 if rotation > 180
    rotation

  updateIsometricRotation: (rotation, imageObject) ->
    action = @currentRootAction
    return unless action
#    @flipOccasionally() if action.name is 'idle'
    imageObject ?= @imageObject
    imageObject.scaleX *= -1 if imageObject.scaleX < 0 # normalize to point right
    imageObject.scaleX *= -1 if Math.abs(rotation) >= 135
#    imageObject.scaleX *= -1 if @flipped and action.name is 'idle'

  flipOccasionally: ->
    @flippedCount += 1
    return unless _.random(0,1000) <= 15 and @flippedCount > 30
    @flipped = not @flipped
    @flippedCount = 0

  ##################################################
  updateAction: ->
    action = @determineAction()
    isDifferent = action isnt @currentRootAction
    console.error "action is", action, "for", @thang?.id, "from", @currentRootAction, @thang.action, @thang.getActionName?() if not action and @thang?.actionActivated and @thang.id is 'Artillery'
    @queueAction(action) if isDifferent or (@thang?.actionActivated and action.name isnt 'move')
    @updateActionDirection()

  determineAction: ->
    action = null
    action = @thang.getActionName() if @thang?.acts
    action ?= @currentRootAction.name if @currentRootAction?
    action ?= 'idle'
    action = null unless @actions[action]?
    return null unless action
    action = 'break' if @actions.break? and @thang?.erroredOut
    action = 'die' if @actions.die? and @thang?.health? and @thang.health <= 0
    @actions[action]

  updateActionDirection: (@wallGrid=null) ->
    # wallGrid is only needed for wall grid face updates; should refactor if this works
    return unless action = @getActionDirection()
    @playAction(action) if action isnt @currentAction

  getActionDirection: (rootAction=null) ->
    rootAction ?= @currentRootAction
    return null unless relatedActions = rootAction?.relatedActions ? {}
    rotation = @getRotation()
    if relatedActions["111111111111"]  # has grid-surrounding-wall-based actions
      if @wallGrid
        action = ''
        tileSize = 4
        [gx, gy] = [@thang.pos.x, @thang.pos.y]
        for y in [gy + tileSize, gy, gy - tileSize, gy - tileSize * 2]
          for x in [gx - tileSize, gx, gx + tileSize]
            if x >= 0 and y >= 0 and x < @wallGrid.width and y < @wallGrid.height
              wallThangs = @wallGrid.contents x, y
            else
              wallThangs = ['outside of the map yo']
            if wallThangs.length is 0
              if y is gy and x is gx
                action += "1"  # the center wall we're placing
              else
                action += "0"
            else if wallThangs.length is 1
              action += "1"
            else
              console.error "Overlapping walls at", x, y, "...", wallThangs
              action += "1"
        matchedAction = '111111111111'
        for relatedAction of relatedActions
          if action.match(relatedAction.replace(/\?/g, '.'))
            matchedAction = relatedAction
            break
        #console.log "returning", matchedAction, "for", @thang.id, "at", gx, gy
        return relatedActions[matchedAction]
      else
        keys = _.keys relatedActions
        index = Math.max 0, Math.floor((179 + rotation) / 360 * keys.length)
        #console.log "Showing", relatedActions[keys[index]]
        return relatedActions[keys[index]]
    value = Math.abs(rotation)
    direction = null
    direction = 'side' if value <= 45 or value >= 135
    direction = 'fore' if 135 > rotation > 45
    direction = 'back' if -135 < rotation < -45
    relatedActions[direction]

  updateStats: ->
    if bar = @healthBar
      return if @thang.health is @lastHealth
      @lastHealth = @thang.health
      healthPct = Math.max(@thang.health / @thang.maxHealth, 0)
      bar.scaleX = healthPct
      healthOffset = @getOffset 'aboveHead'
      [bar.x, bar.y] = [healthOffset.x - bar.width / 2, healthOffset.y]

  configureMouse: ->
    @displayObject.cursor = 'pointer' if @thang?.isSelectable
    @displayObject.mouseEnabled = @displayObject.mouseChildren = false unless @thang?.isSelectable or @thang?.isLand
    if @displayObject.mouseEnabled
      @displayObject.on 'mousedown', @onMouseEvent, @, false, 'sprite:mouse-down'
      @displayObject.on 'click',     @onMouseEvent, @, false, 'sprite:clicked'
      @displayObject.on 'dblclick',  @onMouseEvent, @, false, 'sprite:double-clicked'
      @displayObject.on 'pressmove', @onMouseEvent, @, false, 'sprite:dragged'
      @displayObject.on 'pressup',   @onMouseEvent, @, false, 'sprite:mouse-up'

  onSetLetterbox: (e) ->
    @letterboxOn = e.on

  onMouseEvent: (e, ourEventName) ->
    return if @letterboxOn
    Backbone.Mediator.publish ourEventName, sprite: @, thang: @thang, originalEvent: e

  addHealthBar: ->
    @displayObject.removeChild @healthBar if @healthBar?.parent
    return unless @thang?.health? and "health" in (@thang?.hudProperties ? [])
    healthColor = healthColors[@thang?.team] ? healthColors["neutral"]
    healthOffset = @getOffset 'aboveHead'
    bar = @healthBar = createProgressBar(healthColor, healthOffset.y)
    bar.x = healthOffset.x - bar.width / 2
    bar.name = 'health bar'
    bar.cache 0, -bar.height / 2, bar.width, bar.height
    @displayObject.addChild bar

  getActionProp: (prop, subProp, def=null) ->
    # Get a property or sub-property from an action, falling back to ThangType
    for val in [@currentAction?[prop], @thangType.get(prop)]
      val = val[subProp] if val? and subProp
      return val if val?
    def

  getOffset: (prop) ->
    # Get the proper offset from either the current action or the ThangType
    def = x: 0, y: {registration: 0, torso: -50, mouth: -60, aboveHead: -100}[prop]
    pos = @getActionProp 'positions', prop, def
    pos = x: pos.x, y: pos.y
    scale = @getActionProp 'scale', null, 1
    scale *= @options.resolutionFactor if prop is 'registration'
    pos.x *= scale
    pos.y *= scale
    pos

  updateMarks: ->
    return unless @options.camera
    @addMark 'repair', null, @options.markThangTypes.repair if @thang?.errorsOut
    @marks.repair?.toggle @thang?.errorsOut
    @addMark('bounds').toggle true if @thang?.drawsBounds
    @addMark('shadow').toggle true unless @thangType.get('shadow') is 0
    mark.update() for name, mark of @marks

  setHighlight: (to, delay) ->
    @addMark 'highlight', @options.floatingLayer, @options.markThangTypes.highlight if to
    @marks.highlight?.highlightDelay = delay
    @marks.highlight?.toggle to and not @dimmed

  setDimmed: (@dimmed) ->
    @marks.highlight?.toggle @marks.highlight.on and not @dimmed

  setThang: (@thang) ->
    @options.thang = @thang

  setDebug: (debug) ->
    return unless @thang?.collides and @options.camera?
    @addMark 'debug', @options.floatingLayer if debug
    @marks.debug?.toggle debug

  getAverageDimension: ->
    bounds = @imageObject.getBounds()
    averageDimension = (bounds.height + bounds.width) / 2
    Math.min(80, averageDimension)

  addLabel: (name, style) ->
    @labels[name] ?= new Label sprite: @, camera: @options.camera, layer: @options.textLayer, style: style
    @labels[name]

  addMark: (name, layer, thangType=null) ->
    @marks[name] ?= new Mark name: name, sprite: @, camera: @options.camera, layer: layer ? @options.groundLayer, thangType: thangType
    @marks[name]

  notifySpeechUpdated: (e) ->
    e = _.clone(e)
    e.sprite = @
    e.blurb ?= '...'
    e.thang = @thang
    Backbone.Mediator.publish 'sprite:speech-updated', e

  isTalking: ->
    Boolean @labels.dialogue?.text or @labels.say?.text

  onDialogue: (e) ->
    return unless @thang?.id is e.spriteID
    label = @addLabel 'dialogue', Label.STYLE_DIALOGUE
    label.setText e.blurb or '...'
    sound = e.sound ? AudioPlayer.soundForDialogue e.message, @thangType.get 'soundTriggers'
    @instance?.stop()
    if @instance = @playSound sound, false
      @instance.addEventListener "complete", => Backbone.Mediator.publish 'dialogue-sound-completed'
    @notifySpeechUpdated e

  onClearDialogue: (e) ->
    @labels.dialogue?.setText null
    @instance?.stop()
    @notifySpeechUpdated {}

  setNameLabel: (name) ->
    label = @addLabel 'name', Label.STYLE_NAME
    label.setText name

  updateLabels: ->
    return unless @thang
    blurb = if @thang.health <= 0 then null else @thang.sayMessage  # Dead men tell no tales
    @addLabel 'say', Label.STYLE_SAY if blurb
    if @labels.say?.setText blurb
      @notifySpeechUpdated blurb: blurb
    label.update() for name, label of @labels

  playSounds: (withDelay=true, volume=1.0) ->
    for event in @thang.currentEvents ? []
      @playSound event, withDelay, volume
    if @thang.actionActivated and (action = @thang.getActionName()) isnt 'say'
      @playSound action, withDelay, volume
    if @thang.sayMessage and withDelay  # don't play sayMessages while scrubbing, annoying
      offsetFrames = Math.abs(@thang.sayStartTime - @thang.world.age) / @thang.world.dt
      if offsetFrames <= 2  # or (not withDelay and offsetFrames < 30)
        sound = AudioPlayer.soundForDialogue @thang.sayMessage, @thangType.get 'soundTriggers'
        @playSound sound, false, volume

  playSound: (sound, withDelay=true, volume=1.0) ->
    if _.isString sound
      sound = @thangType.get('soundTriggers')?[sound]
    if _.isArray sound
      sound = sound[Math.floor Math.random() * sound.length]
    return null unless sound
    delay = if withDelay and sound.delay then 1000 * sound.delay / createjs.Ticker.getFPS() else 0
    name = AudioPlayer.nameForSoundReference sound
    instance = createjs.Sound.play name, "none", delay, 0, 0, volume
#    console.log @thang?.id, "played sound", name, "with delay", delay, "volume", volume, "and got sound instance", instance
    instance