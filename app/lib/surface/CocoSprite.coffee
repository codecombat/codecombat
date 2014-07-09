CocoClass = require 'lib/CocoClass'
{createProgressBar} = require './sprite_utils'
Camera = require './Camera'
Mark = require './Mark'
Label = require './Label'
AudioPlayer = require 'lib/AudioPlayer'
{me} = require 'lib/auth'

# We'll get rid of this once level's teams actually have colors
healthColors =
  ogres: [64, 128, 212]
  humans: [255, 0, 0]
  neutral: [64, 212, 128]

# Sprite: EaselJS-based view/controller for Thang model
module.exports = CocoSprite = class CocoSprite extends CocoClass
  thangType: null # ThangType instance

  imageObject: null

  healthBar: null
  marks: null
  labels: null
  ranges: null

  options:
    resolutionFactor: SPRITE_RESOLUTION_FACTOR
    groundLayer: null
    textLayer: null
    floatingLayer: null
    frameRateFactor: 1  # TODO: use or lose?
    thang: null
    camera: null
    spriteSheetCache: null
    showInvisible: false
    async: true

  possessed: false
  flipped: false
  flippedCount: 0
  actionQueue: null
  actions: null
  rotation: 0

  # Scale numbers
  baseScaleX: 1 # scale + flip (for current action) / resolutionFactor.
  baseScaleY: 1 # These numbers rarely change, so keep them around.
  scaleFactor: 1 # Current scale adjustment. This can change rapidly.
  targetScaleFactor: 1 # What the scaleFactor is going toward during a tween.

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
    'level-sprite-move': 'onMove'

  constructor: (@thangType, options) ->
    super()
    @options = _.extend($.extend(true, {}, @options), options)
    @setThang @options.thang
    console.error @toString(), 'has no ThangType!' unless @thangType

    # this is a stub, use @setImageObject to swap it out for something else later
    @imageObject = new createjs.Container

    @actionQueue = []
    @marks = {}
    @labels = {}
    @ranges = []
    @handledDisplayEvents = {}
    @age = 0
    @stillLoading = true
    if @thangType.isFullyLoaded()
      @setupSprite()
    else
      @thangType.fetch()
      @listenToOnce(@thangType, 'sync', @setupSprite)

  setupSprite: ->
    for trigger, sounds of @thangType.get('soundTriggers') or {} when trigger isnt 'say'
      AudioPlayer.preloadSoundReference sound for sound in sounds
    if @thangType.get('raster')
      @stillLoading = false
      @actions = {}
      @isRaster = true
      @setUpRasterImage()
    else
      result = @buildSpriteSheet()
      if _.isString result # async build
        @listenToOnce @thangType, 'build-complete', @setupSprite
      else
        @stillLoading = false
        @actions = @thangType.getActions()
        @buildFromSpriteSheet result
        @createMarks()
        @queueAction 'idle'

  finishSetup: ->
    @updateBaseScale()
    @scaleFactor = @thang.scaleFactor if @thang?.scaleFactor
    @update true  # Reflect initial scale and other state

  setUpRasterImage: ->
    raster = @thangType.get('raster')
    image = new createjs.Bitmap('/file/'+raster)
    @setImageObject image
    $(image.image).one 'load', => @updateScale?()
    @configureMouse()
    @imageObject.sprite = @
    @imageObject.layerPriority = @thangType.get 'layerPriority'
    @imageObject.name = @thang?.spriteName or @thangType.get 'name'
    reg = @getOffset 'registration'
    @imageObject.regX = -reg.x
    @imageObject.regY = -reg.y
    @finishSetup()

  toString: -> "<CocoSprite: #{@thang?.id}>"

  buildSpriteSheet: ->
    options = _.extend @options, @thang?.getSpriteOptions?() ? {}
    options.colorConfig = @options.colorConfig if @options.colorConfig
    options.async = @options.async
    @thangType.getSpriteSheet options

  setImageObject: (newImageObject) ->
    if parent = @imageObject?.parent
      parent.removeChild @imageObject
      parent.addChild newImageObject
    @imageObject = newImageObject

  buildFromSpriteSheet: (spriteSheet) ->
    if spriteSheet
      sprite = new createjs.Sprite(spriteSheet)
    else
      sprite = new createjs.Shape()

    @setImageObject sprite
    @addHealthBar()
    @configureMouse()
    # TODO: generalize this later?
    @imageObject.sprite = @
    @imageObject.layerPriority = @thangType.get 'layerPriority'
    @imageObject.name = @thang?.spriteName or @thangType.get 'name'
    @imageObject.on 'animationend', @playNextAction
    @finishSetup()

  ##################################################
  # QUEUEING AND PLAYING ACTIONS

  queueAction: (action) ->
    # The normal way to have an action play
    return unless @thangType.isFullyLoaded()
    action = @actions[action] if _.isString(action)
    action ?= @actions.idle
    @actionQueue = []
    @actionQueue.push @currentRootAction.relatedActions.end if @currentRootAction?.relatedActions?.end
    @actionQueue.push action.relatedActions.begin if action.relatedActions?.begin
    @actionQueue.push action
    if action.goesTo and nextAction = @actions[action.goesTo]
      @actionQueue.push nextAction if nextAction
    @currentRootAction = action
    @playNextAction()

  onSurfaceTicked: (e) -> @age += e.dt

  playNextAction: =>
    @playAction(@actionQueue.splice(0, 1)[0]) if @actionQueue.length

  playAction: (action) ->
    return if @isRaster
    @currentAction = action
    return @hide() unless action.animation or action.container or action.relatedActions
    @show()
    @updateBaseScale()
    return @updateActionDirection() unless action.animation or action.container
    m = if action.container then 'gotoAndStop' else 'gotoAndPlay'
    @imageObject.framerate = action.framerate or 20
    @imageObject[m] action.name
    reg = @getOffset 'registration'
    @imageObject.regX = -reg.x
    @imageObject.regY = -reg.y
    if @currentRootAction.name is 'move' and action.frames
      start = Math.floor(Math.random() * action.frames.length)
      @imageObject.currentAnimationFrame = start

  hide: ->
    @hiding = true
    @updateAlpha()

  show: ->
    @hiding = false
    @updateAlpha()

  stop: ->
    @imageObject?.stop?()
    mark.stop() for name, mark of @marks
    @stopped = true

  play: ->
    @imageObject?.play?()
    mark.play() for name, mark of @marks
    @stopped = false

  update: (frameChanged) ->
    # Gets the sprite to reflect what the current state of the thangs and surface are
    return if @stillLoading
    @updatePosition()
    frameChanged = frameChanged or @targetScaleFactor isnt @scaleFactor
    if frameChanged
      @handledDisplayEvents = {}
      @updateScale()  # must happen before rotation
      @updateAlpha()
      @updateRotation()
      @updateAction()
      @updateStats()
      @updateGold()
      @showAreaOfEffects()
      @showTextEvents()
      @updateHealthBar()
    @updateMarks()
    @updateLabels()

  showAreaOfEffects: ->
    return unless @thang?.currentEvents
    for event in @thang.currentEvents
      continue unless event.startsWith 'aoe-'
      continue if @handledDisplayEvents[event]

      @handledDisplayEvents[event] = true
      args = JSON.parse(event[4...])
      pos = @options.camera.worldToSurface {x: args[0], y: args[1]}
      circle = new createjs.Shape()
      circle.graphics.beginFill(args[3]).drawCircle(0, 0, args[2]*Camera.PPM)
      circle.x = pos.x
      circle.y = pos.y
      circle.scaleY = @options.camera.y2x * 0.7
      circle.scaleX = 0.7
      circle.alpha = 0.2
      circle
      @options.groundLayer.addChild circle
      createjs.Tween.get(circle)
        .to({alpha: 0.6, scaleY: @options.camera.y2x, scaleX: 1}, 100, createjs.Ease.circOut)
        .to({alpha: 0, scaleY: 0, scaleX: 0}, 700, createjs.Ease.circIn)
        .call =>
          return if @destroyed
          @options.groundLayer.removeChild circle
          delete @handledDisplayEvents[event]

  showTextEvents: ->
    return unless @thang?.currentEvents
    for event in @thang.currentEvents
      continue unless event.startsWith 'text-'
      continue if @handledDisplayEvents[event]
      @handledDisplayEvents[event] = true
      options = JSON.parse(event[5...])
      label = new createjs.Text options.text, "bold #{options.size or 16}px Arial", options.color or '#FFF'
      shadowColor = {humans: '#F00', ogres: '#00F', neutral: '#0F0', common: '#0F0'}[@thang.team] ? '#000'
      label.shadow = new createjs.Shadow shadowColor, 1, 1, 3
      offset = @getOffset 'aboveHead'
      [label.x, label.y] = [@imageObject.x + offset.x - label.getMeasuredWidth() / 2, @imageObject.y + offset.y]
      @options.floatingLayer.addChild label
      window.labels ?= []
      window.labels.push label
      label.alpha = 0
      createjs.Tween.get(label)
        .to({y: label.y-2, alpha: 1}, 200, createjs.Ease.linear)
        .to({y: label.y-12}, 1000, createjs.Ease.linear)
        .to({y: label.y-22, alpha: 0}, 1000, createjs.Ease.linear)
        .call =>
          return if @destroyed
          @options.floatingLayer.removeChild label

  cache: ->
    bounds = @imageObject.getBounds()
    @imageObject.cache 0, 0, bounds.width, bounds.height
    #console.log 'just cached', @thang.id, 'which was at', @imageObject.x, @imageObject.y, bounds.width, bounds.height, 'with scale', Math.max(@imageObject.scaleX, @imageObject.scaleY)

  getBobOffset: ->
    return 0 unless @thang.bobHeight
    return @lastBobOffset if @stopped
    return @lastBobOffset = @thang.bobHeight * (1 + Math.sin(@age * Math.PI / @thang.bobTime))

  getWorldPosition: ->
    p1 = if @possessed then @shadow.pos else @thang.pos
    if bobOffset = @getBobOffset()
      p1 = p1.copy?() or _.clone(p1)
      p1.z += bobOffset
    x: p1.x, y: p1.y, z: if @thang.isLand then 0 else p1.z - @thang.depth / 2

  updatePosition: (log) ->
    return if @stillLoading
    return unless @thang?.pos and @options.camera?
    wop = @getWorldPosition()
    [p0, p1] = [@lastPos, @thang.pos]
    return if p0 and p0.x is p1.x and p0.y is p1.y and p0.z is p1.z and not @options.camera.tweeningZoomTo and not @thang.bobHeight
    sup = @options.camera.worldToSurface wop
    [@imageObject.x, @imageObject.y] = [sup.x, sup.y]
    @lastPos = p1.copy?() or _.clone(p1)
    @hasMoved = true

  updateBaseScale: ->
    scale = 1
    scale = @thangType.get('scale') or 1 if @isRaster
    scale /= @options.resolutionFactor unless @isRaster
    @baseScaleX = @baseScaleY = scale
    @baseScaleX *= -1 if @getActionProp 'flipX'
    @baseScaleY *= -1 if @getActionProp 'flipY'
    # temp, until these are re-exported with perspective
    floors = ['Dungeon Floor', 'Indoor Floor', 'Grass', 'Goal Trigger', 'Obstacle']
    if @options.camera and @thangType.get('name') in floors
      @baseScaleY *= @options.camera.y2x

  updateScale: ->
    return unless @imageObject
    if @thangType.get('matchWorldDimensions') and @thang
      if @thang.width isnt @lastThangWidth or @thang.height isnt @lastThangHeight
        bounds = @imageObject.getBounds()
        return unless bounds
        @imageObject.scaleX = @thang.width * Camera.PPM / bounds.width
        @imageObject.scaleY = @thang.height * Camera.PPM * @options.camera.y2x / bounds.height
        @imageObject.regX = bounds.width / 2
        @imageObject.regY = bounds.height / 2

        unless @thang.spriteName is 'Beam'
          @imageObject.scaleX *= @thangType.get('scale') ? 1
          @imageObject.scaleY *= @thangType.get('scale') ? 1
        [@lastThangWidth, @lastThangHeight] = [@thang.width, @thang.height]
      return

    scaleX = scaleY = 1

    if @thangType.get('name') in ['Arrow', 'Spear']
      # Scales the arrow so it appears longer when flying parallel to horizon.
      # To do that, we convert angle to [0, 90] (mirroring half-planes twice), then make linear function out of it:
      # (a - x) / a: equals 1 when x = 0, equals 0 when x = a, monotonous in between. That gives us some sort of
      # degenerative multiplier.
      # For our purposes, a = 90 - the direction straight upwards.
      # Then we use r + (1 - r) * x function with r = 0.5, so that
      # maximal scale equals 1 (when x is at it's maximum) and minimal scale is 0.5.
      # Notice that the value of r is empirical.
      angle = @getRotation()
      angle = -angle if angle < 0
      angle = 180 - angle if angle > 90
      scaleX = 0.5 + 0.5 * (90 - angle) / 90

#    console.error 'No thang for', @ unless @thang
    # TODO: support using scaleFactorX/Y from the thang object
    @imageObject.scaleX = @baseScaleX * @scaleFactor * scaleX
    @imageObject.scaleY = @baseScaleY * @scaleFactor * scaleY

    if @thang and (@thang.scaleFactor or 1) isnt @targetScaleFactor
      createjs.Tween.removeTweens(@)
      createjs.Tween.get(@).to({scaleFactor: @thang.scaleFactor or 1}, 2000, createjs.Ease.elasticOut)
      @targetScaleFactor = @thang.scaleFactor or 1

  updateAlpha: ->
    @imageObject.alpha = if @hiding then 0 else 1
    return unless @thang?.alpha?
    return if @imageObject.alpha is @thang.alpha
    @imageObject.alpha = @thang.alpha
    if @options.showInvisible
      @imageObject.alpha = Math.max 0.5, @imageObject.alpha
    mark.updateAlpha @thang.alpha for name, mark of @marks
    @healthBar?.alpha = @thang.alpha

  updateRotation: (imageObject) ->
    rotationType = @thangType.get('rotationType')
    return if rotationType is 'fixed'
    rotation = @getRotation()
    if @thangType.get('name') in ['Arrow', 'Spear']
      # Rotates the arrow to see it arc based on velocity.z.
      # Notice that rotation here does not affect thang's state - it is just the effect.
      # Thang's rotation is always pointing where it is heading.
      vz = @thang.velocity.z
      if vz and speed = @thang.velocity.magnitude(true)
        vx = @thang.velocity.x
        heading = @thang.velocity.heading()
        xFactor = Math.cos heading
        zFactor = vz / Math.sqrt(vz * vz + vx * vx)
        rotation -= xFactor * zFactor * 45
    imageObject ?= @imageObject
    return imageObject.rotation = rotation if not rotationType
    @updateIsometricRotation(rotation, imageObject)

  getRotation: ->
    thang = if @possessed then @shadow else @thang
    return @rotation if not thang?.rotation
    rotation = thang?.rotation
    rotation = (360 - (rotation * 180 / Math.PI) % 360) % 360
    rotation -= 360 if rotation > 180
    rotation

  updateIsometricRotation: (rotation, imageObject) ->
    return unless @currentAction
    return if _.string.endsWith(@currentAction.name, 'back')
    return if _.string.endsWith(@currentAction.name, 'fore')
    imageObject.scaleX *= -1 if Math.abs(rotation) >= 90

  ##################################################
  updateAction: ->
    return if @isRaster
    action = @determineAction()
    isDifferent = action isnt @currentRootAction or action is null
    if not action and @thang?.actionActivated and not @stopLogging
      console.error 'action is', action, 'for', @thang?.id, 'from', @currentRootAction, @thang.action, @thang.getActionName?()
      @stopLogging = true
    @queueAction(action) if action and (isDifferent or (@thang?.actionActivated and action.name isnt 'move'))
    @updateActionDirection()

  determineAction: ->
    action = null
    thang = if @possessed then @shadow else @thang
    action = thang.action if thang?.acts
    action ?= @currentRootAction.name if @currentRootAction?
    action ?= 'idle'
    unless @actions[action]?
      @warnedFor ?= {}
      console.warn 'Cannot show action', action, 'for', @thangType.get('name'), 'because it DNE' unless @warnedFor[action]
      @warnedFor[action] = true
      return if @action is 'idle' then null else 'idle'
    action = 'break' if @actions.break? and @thang?.erroredOut
    action = 'die' if @actions.die? and thang?.health? and thang.health <= 0
    @actions[action]

  updateActionDirection: (@wallGrid=null) ->
    # wallGrid is only needed for wall grid face updates; should refactor if this works
    return unless action = @getActionDirection()
    @playAction(action) if action isnt @currentAction

  getActionDirection: (rootAction=null) ->
    rootAction ?= @currentRootAction
    return null unless relatedActions = rootAction?.relatedActions ? {}
    rotation = @getRotation()
    if relatedActions['111111111111']  # has grid-surrounding-wall-based actions
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
                action += '1'  # the center wall we're placing
              else
                action += '0'
            else if wallThangs.length is 1
              action += '1'
            else
              console.error 'Overlapping walls at', x, y, '...', wallThangs
              action += '1'
        matchedAction = '111111111111'
        for relatedAction of relatedActions
          if action.match(relatedAction.replace(/\?/g, '.'))
            matchedAction = relatedAction
            break
        #console.log 'returning', matchedAction, 'for', @thang.id, 'at', gx, gy
        return relatedActions[matchedAction]
      else
        keys = _.keys relatedActions
        index = Math.max 0, Math.floor((179 + rotation) / 360 * keys.length)
        #console.log 'Showing', relatedActions[keys[index]]
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
      bar.scaleX = healthPct / bar.baseScale
      healthOffset = @getOffset 'aboveHead'
      [bar.x, bar.y] = [healthOffset.x - bar.width / 2, healthOffset.y]

  configureMouse: ->
    @imageObject.cursor = 'pointer' if @thang?.isSelectable
    @imageObject.mouseEnabled = @imageObject.mouseChildren = false unless @thang?.isSelectable or @thang?.isLand
    if @imageObject.mouseEnabled
      @imageObject.on 'mousedown', @onMouseEvent, @, false, 'sprite:mouse-down'
      @imageObject.on 'click',     @onMouseEvent, @, false, 'sprite:clicked'
      @imageObject.on 'dblclick',  @onMouseEvent, @, false, 'sprite:double-clicked'
      @imageObject.on 'pressmove', @onMouseEvent, @, false, 'sprite:dragged'
      @imageObject.on 'pressup',   @onMouseEvent, @, false, 'sprite:mouse-up'

  onSetLetterbox: (e) ->
    @letterboxOn = e.on

  onMouseEvent: (e, ourEventName) ->
    return if @letterboxOn
    p = @imageObject
    p = p.parent while p.parent
    newEvent = sprite: @, thang: @thang, originalEvent: e, canvas:p.canvas
    @trigger ourEventName, newEvent
    Backbone.Mediator.publish ourEventName, newEvent

  addHealthBar: ->
    return unless @thang?.health? and 'health' in (@thang?.hudProperties ? []) and @options.floatingLayer
    healthColor = healthColors[@thang?.team] ? healthColors['neutral']
    healthOffset = @getOffset 'aboveHead'
    bar = @healthBar = createProgressBar(healthColor, healthOffset)
    bar.name = 'health bar'
    bar.cache 0, -bar.height * bar.baseScale / 2, bar.width * bar.baseScale, bar.height * bar.baseScale
    @options.floatingLayer.addChild bar
    @updateHealthBar()

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
    if not @isRaster
      scale = @getActionProp 'scale', null, 1
      scale *= @options.resolutionFactor if prop is 'registration'
      pos.x *= scale
      pos.y *= scale
    if @thang and prop isnt 'registration'
      scaleFactor = @thang.scaleFactor ? 1
      pos.x *= @thang.scaleFactorX ? scaleFactor
      pos.y *= @thang.scaleFactorY ? scaleFactor
    # We might need to do this, but I don't have a good test case yet. TODO: figure out.
    #if prop isnt @registration
    #  pos.x *= if @getActionProp 'flipX' then -1 else 1
    #  pos.y *= if @getActionProp 'flipY' then -1 else 1
    pos

  createMarks: ->
    return unless @options.camera
    if @thang
      allProps = []
      allProps = allProps.concat (@thang.hudProperties ? [])
      allProps = allProps.concat (@thang.programmableProperties ? [])
      allProps = allProps.concat (@thang.moreProgrammableProperties ? [])

      for property in allProps
        if m = property.match /.*(Range|Distance|Radius)$/
          if @thang[m[0]]? and @thang[m[0]] < 9001
            @ranges.push
              name: m[0]
              radius: @thang[m[0]]

      @ranges = _.sortBy @ranges, 'radius'
      @ranges.reverse()

      @addMark range.name for range in @ranges

      @addMark('bounds').toggle true if @thang?.drawsBounds
      @addMark('shadow').toggle true unless @thangType.get('shadow') is 0

  updateMarks: ->
    return unless @options.camera
    @addMark 'repair', null, 'repair' if @thang?.errorsOut
    @marks.repair?.toggle @thang?.errorsOut

    if @selected
      @marks[range['name']].toggle true for range in @ranges
    else
      @marks[range['name']].toggle false for range in @ranges

    if @thangType.get('name') in ['Arrow', 'Spear'] and @thang.action is 'die'
      @marks.shadow?.hide()
    mark.update() for name, mark of @marks
    #@thang.effectNames = ['berserk', 'confuse', 'control', 'curse', 'fear', 'poison', 'paralyze', 'regen', 'sleep', 'slow', 'haste']
    @updateEffectMarks() if @thang?.effectNames?.length or @previousEffectNames?.length

  updateEffectMarks: ->
    return if _.isEqual @thang.effectNames, @previousEffectNames
    return if @stopped
    for effect in @thang.effectNames
      mark = @addMark effect, @options.floatingLayer, effect
      mark.statusEffect = true
      mark.toggle 'on'
      mark.show()

    if @previousEffectNames
      for effect in @previousEffectNames
        continue if effect in @thang.effectNames
        mark = @marks[effect]
        mark.toggle false

    if @thang.effectNames.length > 1 and not @effectInterval
      @rotateEffect()
      @effectInterval = setInterval @rotateEffect, 1500

    else if @effectInterval and @thang.effectNames.length <= 1
      clearInterval @effectInterval
      @effectInterval = null

    @previousEffectNames = @thang.effectNames

  rotateEffect: =>
    effects = (m.name for m in _.values(@marks) when m.on and m.statusEffect and m.mark)
    return unless effects.length
    effects.sort()
    @effectIndex ?= 0
    @effectIndex = (@effectIndex + 1) % effects.length
    @marks[effect].hide() for effect in effects
    @marks[effects[@effectIndex]].show()

  setHighlight: (to, delay) ->
    @addMark 'highlight', @options.floatingLayer, 'highlight' if to
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
      @instance.addEventListener 'complete', -> Backbone.Mediator.publish 'dialogue-sound-completed'
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

  updateGold: ->
    # TODO: eventually this should be moved into some sort of team-based update
    # rather than an each-thang-that-shows-gold-per-team thing.
    return unless @thang
    return if @thang.gold is @lastGold
    gold = Math.floor @thang.gold
    if @thang.world.age is 0
      gold = @thang.world.initialTeamGold[@thang.team].gold
    return if gold is @lastGold
    @lastGold = gold
    Backbone.Mediator.publish 'surface:gold-changed', {team: @thang.team, gold: gold, goldEarned: Math.floor(@thang.goldEarned)}

  playSounds: (withDelay=true, volume=1.0) ->
    for event in @thang.currentEvents ? []
      @playSound event, withDelay, volume
      if event is 'pay-bounty-gold' and @thang.bountyGold > 25 and @thang.team isnt me.team
        AudioPlayer.playInterfaceSound 'coin_1', 0.25
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
    instance = AudioPlayer.playSound name, volume, delay, @getWorldPosition()
    #console.log @thang?.id, 'played sound', name, 'with delay', delay, 'volume', volume, 'and got sound instance', instance
    instance

  onMove: (e) ->
    return unless e.spriteID is @thang?.id
    pos = e.pos
    if _.isArray pos
      pos = new Vector pos...
    else if _.isString pos
      return console.warn 'Couldn\'t find target sprite', pos, 'from', @options.sprites unless pos of @options.sprites
      target = @options.sprites[pos].thang
      heading = Vector.subtract(target.pos, @thang.pos).normalize()
      distance = @thang.pos.distance target.pos
      offset = Math.max(target.width, target.height, 2) / 2 + 3
      pos = Vector.add(@thang.pos, heading.multiply(distance - offset))
    Backbone.Mediator.publish 'level-sprite-clear-dialogue', {}
    @onClearDialogue()
    args = [pos]
    args.push(e.duration) if e.duration?
    @move(args...)

  move: (pos, duration=2000, endAnimation='idle') =>
    @updateShadow()
    if not duration
      createjs.Tween.removeTweens(@shadow.pos) if @lastTween
      @lastTween = null
      z = @shadow.pos.z
      @shadow.pos = pos
      @shadow.pos.z = z
      @imageObject.gotoAndPlay?(endAnimation)
      return

    @shadow.action = 'move'
    @shadow.actionActivated = true
    @pointToward(pos)
    @possessed = true
    @update true

    ease = createjs.Ease.getPowInOut(2.2)
    if @lastTween
      ease = createjs.Ease.getPowOut(1.2)
      createjs.Tween.removeTweens(@shadow.pos)

    endFunc = =>
      @lastTween = null
      @imageObject.gotoAndPlay(endAnimation) unless @stillLoading
      @shadow.action = 'idle'
      @update true
      @possessed = false

    @lastTween = createjs.Tween
      .get(@shadow.pos)
      .to({x: pos.x, y: pos.y}, duration, ease)
      .call(endFunc)

  pointToward: (pos) ->
    @shadow.rotation = Math.atan2(pos.y - @shadow.pos.y, pos.x - @shadow.pos.x)
    if (@shadow.rotation * 180 / Math.PI) % 90 is 0
      @shadow.rotation += 0.01

  updateShadow: ->
    @shadow = {} if not @shadow
    @shadow.pos = @thang.pos
    @shadow.rotation = @thang.rotation
    @shadow.action = @thang.action
    @shadow.actionActivated = @thang.actionActivated

  updateHealthBar: ->
    return unless @healthBar
    @healthBar.x = @imageObject.x
    @healthBar.y = @imageObject.y

  destroy: ->
    mark.destroy() for name, mark of @marks
    label.destroy() for name, label of @labels
    p.removeChild @healthBar if p = @healthBar?.parent
    @imageObject?.off 'animationend', @playNextAction
    clearInterval @effectInterval if @effectInterval
    super()
