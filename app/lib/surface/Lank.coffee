CocoClass = require 'core/CocoClass'
{createProgressBar} = require './sprite_utils'
Camera = require './Camera'
Mark = require './Mark'
Label = require './Label'
AudioPlayer = require 'lib/AudioPlayer'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
utils = require 'core/utils'
createjs = require 'lib/createjs-parts'

# We'll get rid of this once level's teams actually have colors
healthColors =
  ogres: [64, 128, 212]
  humans: [255, 0, 0]
  neutral: [64, 212, 128]

# Sprite: EaselJS-based view/controller for Thang model
module.exports = Lank = class Lank extends CocoClass
  thangType: null # ThangType instance

  sprite: null

  healthBar: null
  marks: null
  labels: null
  ranges: null

  options:
    groundLayer: null
    textLayer: null
    floatingLayer: null
    thang: null
    camera: null
    showInvisible: false
    preloadSounds: true

  possessed: false
  flipped: false
  flippedCount: 0
  actionQueue: null
  actions: null
  rotation: 0

  # Scale numbers
  scaleFactorX: 1 # Current scale adjustment. This can change rapidly.
  scaleFactorY: 1
  targetScaleFactorX: 1 # What the scaleFactor is going toward during a tween.
  targetScaleFactorY: 1

  # ACTION STATE
  # Actions have relations. If you say 'move', 'move_side' may play because of a direction
  # relationship, and if you say 'cast', 'cast_begin' may happen first, or 'cast_end' after.
  currentRootAction: null  # action that, in general, is playing or will play
  currentAction: null  # related action that is right now playing

  subscriptions:
    'level:sprite-dialogue': 'onDialogue'
    'level:sprite-clear-dialogue': 'onClearDialogue'
    'level:set-letterbox': 'onSetLetterbox'
    'surface:ticked': 'onSurfaceTicked'
    'sprite:move': 'onMove'

  constructor: (@thangType, options={}) ->
    super()
    spriteName = @thangType.get('name')
    @isMissile = /(Missile|Arrow|Spear|Bolt)/.test(spriteName) and not /(Tower|Charge)/.test(spriteName)
    @options = _.extend($.extend(true, {}, @options), options)
    @gameUIState = @options.gameUIState
    @handleEvents = @options.handleEvents
    @isCinematicLank = @options.isCinematic or false
    @setThang @options.thang
    @setColorConfig()

    console.error @toString(), 'has no ThangType!' unless @thangType

    # this is a stub, use @setSprite to swap it out for something else later
    @sprite = new createjs.Container

    @actionQueue = []
    @marks = {}
    @labels = {}
    @ranges = []
    @handledDisplayEvents = {}
    @age = 0
    @stillLoading = true
    if @thangType.isFullyLoaded() then @onThangTypeLoaded() else @listenToOnce(@thangType, 'sync', @onThangTypeLoaded)

  toString: -> "<Lank: #{@thang?.id}>"

  setColorConfig: ->
    return unless colorConfig = @thang?.getLankOptions?().colorConfig
    if @thangType.get('original') is ThangType.heroes['code-ninja']
      unlockedLevels = me.levels()
      if '5522b98685fca53105544b53' in unlockedLevels  # vital-powers, start of course 5
        colorConfig.belt = {hue: 0.4, saturation: 0.75, lightness: 0.25}
      else if '56fc56ac7cd2381f00d758b4' in unlockedLevels  # friend-and-foe, start of course 3
        colorConfig.belt = {hue: 0.067, saturation: 0.75, lightness: 0.5}
      else
        colorConfig.belt = {hue: 0.167, saturation: 0.75, lightness: 0.4}
    @options.colorConfig = colorConfig

  onThangTypeLoaded: ->
    @stillLoading = false
    if @options.preloadSounds
      for trigger, sounds of @thangType.get('soundTriggers') or {} when trigger isnt 'say'
        AudioPlayer.preloadSoundReference sound for sound in sounds when sound
    if @thangType.get('raster')
      @actions = {}
      @isRaster = true
    else
      @actions = @thangType.getActions()
      @createMarks()

    @scaleFactorX = @thang.scaleFactorX if @thang?.scaleFactorX?
    @scaleFactorX = @thang.scaleFactor if @thang?.scaleFactor?
    @scaleFactorY = @thang.scaleFactorY if @thang?.scaleFactorY?
    @scaleFactorY = @thang.scaleFactor if @thang?.scaleFactor?
    @updateAction() unless @currentAction

  setSprite: (newSprite) ->
    if @sprite
      @sprite.off 'animationend', @playNextAction
      @sprite.destroy?()
      if parent = @sprite.parent
        parent.removeChild @sprite
        if parent.spriteSheet is newSprite.spriteSheet
          parent.addChild newSprite

    # get the lank to update things
    for prop in ['lastPos', 'currentRootAction']
      delete @[prop]

    @sprite = newSprite
    if @thang and @thang.stateChanged is false
      @thang.stateChanged = true
    @configureMouse()
    @sprite.on 'animationend', @playNextAction
    @playAction(@currentAction) if @currentAction and not @stillLoading
    @trigger 'new-sprite', @sprite

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
    if action.goesTo and nextAction = @actions[action.goesTo]
      @actionQueue.push nextAction if nextAction
    @currentRootAction = action
    @playNextAction()

  onSurfaceTicked: (e) -> @age += e.dt

  playNextAction: =>
    return if @destroyed
    @playAction(@actionQueue.splice(0, 1)[0]) if @actionQueue.length

  playAction: (action) ->
    return if @isRaster
    @currentAction = action
    return @hide() unless action.animation or action.container or action.relatedActions or action.goesTo
    @show()
    return @updateActionDirection() unless action.animation or action.container or action.goesTo
    return if @sprite.placeholder
    m = if action.container then 'gotoAndStop' else 'gotoAndPlay'
    @sprite[m]?(action.name)
    @updateScale()
    @updateRotation()

  hide: ->
    @hiding = true
    @updateAlpha()

  show: ->
    @hiding = false
    @updateAlpha()

  stop: ->
    @sprite?.stop?()
    mark.stop() for name, mark of @marks
    @stopped = true

  play: ->
    @sprite?.play?()
    mark.play() for name, mark of @marks
    @stopped = false

  update: (frameChanged) ->
    # Gets the sprite to reflect what the current state of the thangs and surface are
    return false if @stillLoading
    thangUnchanged = @thang and @thang.stateChanged is false
    if (frameChanged and not thangUnchanged) or (@thang and @thang.bobHeight) or @notOfThisWorld
      @updatePosition()
    return false if thangUnchanged
    frameChanged = frameChanged or @targetScaleFactorX isnt @scaleFactorX or @targetScaleFactorY isnt @scaleFactorY
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
    @thang.stateChanged = false if @thang and @thang.stateChanged is true
    return true

  showAreaOfEffects: ->
    return unless @thang?.currentEvents
    for event in @thang.currentEvents
      continue unless _.string.startsWith event, 'aoe-'
      continue if @handledDisplayEvents[event]
      @handledDisplayEvents[event] = true
      args = JSON.parse(event[4...])
      key = 'aoe-' + JSON.stringify(args[2..])
      layerName = args[6] ? 'ground'  # Can also specify 'floating'.
      unless layer = @options[layerName + 'Layer']
        console.error "#{@thang.id} couldn't find layer #{layerName}Layer for AOE effect #{key}; using ground layer."
        layer = @options.groundLayer

      unless key in layer.spriteSheet.animations
        circle = new createjs.Shape()
        radius = args[2] * Camera.PPM
        if args.length is 4
          circle.graphics.beginFill(args[3]).drawCircle(0, 0, radius)
        else
          startAngle = args[4] or 0
          endAngle = args[5] or 2 * Math.PI
          if startAngle is endAngle
            startAngle = 0
            endAngle = 2 * Math.PI
          circle.graphics.beginFill(args[3])
            .lineTo(0, 0)
            .lineTo(radius * Math.cos(startAngle), radius * Math.sin(startAngle))
            .arc(0, 0, radius, startAngle, endAngle)
            .lineTo(0, 0)
        layer.addCustomGraphic(key, circle, [-radius, -radius, radius*2, radius*2])

      circle = new createjs.Sprite(layer.spriteSheet)
      circle.gotoAndStop(key)
      pos = @options.camera.worldToSurface {x: args[0], y: args[1]}
      circle.x = pos.x
      circle.y = pos.y
      resFactor = layer.resolutionFactor
      circle.scaleY = @options.camera.y2x * 0.7 / resFactor
      circle.scaleX = 0.7 / resFactor
      circle.alpha = 0.2
      layer.addChild circle
      createjs.Tween.get(circle)
        .to({alpha: 0.6, scaleY: @options.camera.y2x / resFactor, scaleX: 1 / resFactor}, 100, createjs.Ease.circOut)
        .to({alpha: 0, scaleY: 0, scaleX: 0}, 700, createjs.Ease.circIn)
        .call =>
          return if @destroyed
          layer.removeChild circle
          delete @handledDisplayEvents[event]

  showTextEvents: ->
    return unless @thang?.currentEvents
    for event in @thang.currentEvents
      continue unless _.string.startsWith event, 'text-'
      continue if @handledDisplayEvents[event]
      @handledDisplayEvents[event] = true
      options = JSON.parse(event[5...])
      label = new createjs.Text options.text, "bold #{options.size or 16}px Arial", options.color or '#FFF'
      shadowColor = {humans: '#F00', ogres: '#00F', neutral: '#0F0', common: '#0F0'}[@thang.team] ? '#000'
      label.shadow = new createjs.Shadow shadowColor, 1, 1, 3
      offset = @getOffset 'aboveHead'
      [label.x, label.y] = [@sprite.x + offset.x - label.getMeasuredWidth() / 2, @sprite.y + offset.y]
      @options.textLayer.addChild label
      window.labels ?= []
      window.labels.push label
      label.alpha = 0
      createjs.Tween.get(label)
        .to({y: label.y-2, alpha: 1}, 200, createjs.Ease.linear)
        .to({y: label.y-12}, 1000, createjs.Ease.linear)
        .to({y: label.y-22, alpha: 0}, 1000, createjs.Ease.linear)
        .call =>
          return if @destroyed
          @options.textLayer.removeChild label

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

  updatePosition: (whileLoading=false) ->
    return if @stillLoading and not whileLoading
    return unless @thang?.pos and @options.camera?
    [p0, p1] = [@lastPos, @thang.pos]
    return if p0 and p0.x is p1.x and p0.y is p1.y and p0.z is p1.z and not @thang.bobHeight
    wop = @getWorldPosition()
    sup = @options.camera.worldToSurface wop
    [@sprite.x, @sprite.y] = [sup.x, sup.y]
    @lastPos = p1.copy?() or _.clone(p1) unless whileLoading
    @hasMoved = true
    if @thangType.get('name') is 'Flag' and not @notOfThisWorld
      # Let the pending flags know we're here (but not this call stack, they need to delete themselves, and we may be iterating sprites).
      _.defer => Backbone.Mediator.publish 'surface:flag-appeared', sprite: @

  updateScale: (force) ->
    return unless @sprite
    if @thangType.get('matchWorldDimensions') and @thang and @options.camera
      if force or @thang.width isnt @lastThangWidth or @thang.height isnt @lastThangHeight or @thang.rotation isnt @lastThangRotation
        bounds = @sprite.getBounds()
        return unless bounds
        @sprite.scaleX = @thang.width  * Camera.PPM / bounds.width  * (@options.camera.y2x + (1 - @options.camera.y2x) * Math.abs Math.cos @thang.rotation)
        @sprite.scaleY = @thang.height * Camera.PPM / bounds.height * (@options.camera.y2x + (1 - @options.camera.y2x) * Math.abs Math.sin @thang.rotation)
        @sprite.regX = bounds.width  * 3 / 4  # Why not / 2? I don't know.
        @sprite.regY = bounds.height * 3 / 4  # Why not / 2? I don't know.

        unless @thang.spriteName is 'Beam'
          @sprite.scaleX *= @thangType.get('scale') ? 1
          @sprite.scaleY *= @thangType.get('scale') ? 1
        [@lastThangWidth, @lastThangHeight, @lastThangRotation] = [@thang.width, @thang.height, @thang.rotation]
      return

    scaleX = scaleY = 1

    if @isMissile
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
    @sprite.scaleX = @sprite.baseScaleX * @scaleFactorX * scaleX
    @sprite.scaleY = @sprite.baseScaleY * @scaleFactorY * scaleY

    newScaleFactorX = @thang?.scaleFactorX ? @thang?.scaleFactor ? 1
    newScaleFactorY = @thang?.scaleFactorY ? @thang?.scaleFactor ? 1
    if @layer?.name is 'Land' or @thang?.isLand or @thang?.spriteName is 'Beam' or @isCinematicLank
      @scaleFactorX = newScaleFactorX
      @scaleFactorY = newScaleFactorY
    else if @thang and (newScaleFactorX isnt @targetScaleFactorX or newScaleFactorY isnt @targetScaleFactorY)
      @targetScaleFactorX = newScaleFactorX
      @targetScaleFactorY = newScaleFactorY
      createjs.Tween.removeTweens(@)
      createjs.Tween.get(@).to({scaleFactorX: @targetScaleFactorX, scaleFactorY: @targetScaleFactorY}, 2000, createjs.Ease.elasticOut)

  updateAlpha: ->
    @sprite.alpha = if @hiding then 0 else 1
    return unless @thang?.alpha?
    return if @sprite.alpha is @thang.alpha
    @sprite.alpha = @thang.alpha
    if @options.showInvisible
      @sprite.alpha = Math.max 0.5, @sprite.alpha
    mark.updateAlpha @thang.alpha for name, mark of @marks
    @healthBar?.alpha = @thang.alpha

  updateRotation: (sprite) ->
    rotationType = @thangType.get('rotationType')
    return if rotationType is 'fixed'
    rotation = @getRotation()
    if @isMissile and @thang.velocity
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
    sprite ?= @sprite
    return sprite.rotation = rotation if rotationType is 'free' or not rotationType
    @updateIsometricRotation(rotation, sprite)

  getRotation: ->
    thang = if @possessed then @shadow else @thang
    return @rotation if not thang?.rotation
    rotation = thang?.rotation
    rotation = (360 - (rotation * 180 / Math.PI) % 360) % 360
    rotation -= 360 if rotation > 180
    rotation

  updateIsometricRotation: (rotation, sprite) ->
    return unless @currentAction
    return if _.string.endsWith(@currentAction.name, 'back')
    return if _.string.endsWith(@currentAction.name, 'fore')
    sprite.scaleX *= -1 if Math.abs(rotation) >= 90

  ##################################################
  updateAction: ->
    return if @isRaster or @actionLocked
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
    #action = 'break' if @actions.break? and @thang?.erroredOut  # This makes it looks like it's dead when it's not: bad in Brawlwood.
    action = 'die' if @actions.die? and thang?.health? and thang.health <= 0
    @actions[action]

  updateActionDirection: (@wallGrid=null) ->
    # wallGrid is only needed for wall grid face updates; should refactor if this works
    return unless action = @getActionDirection()
    @playAction(action) if action isnt @currentAction

  lockAction: -> (@actionLocked=true)

  getActionDirection: (rootAction=null) ->
    rootAction ?= @currentRootAction
    return null unless relatedActions = rootAction?.relatedActions ? {}
    rotation = @getRotation()
    if relatedActions['111111111111']  # has grid-surrounding-wall-based actions
      if @wallGrid
        @hadWallGrid = true
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
      else if @hadWallGrid
        return null
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
    return unless @thang and @thang.health isnt @lastHealth
    @lastHealth = @thang.health
    if bar = @healthBar
      healthPct = Math.max(@thang.health / @thang.maxHealth, 0)
      bar.scaleX = healthPct / @options.floatingLayer.resolutionFactor
    if @thang.showsName
      @setNameLabel(if @thang.health <= 0 then '' else @thang.id)
    else if @options.playerName
      @setNameLabel @options.playerName

  configureMouse: ->
    @sprite.cursor = 'pointer' if @thang?.isSelectable
    @sprite.mouseEnabled = @sprite.mouseChildren = false unless @thang?.isSelectable or @thang?.isLand
    if @sprite.mouseEnabled
      @sprite.on 'mousedown', @onMouseEvent, @, false, 'sprite:mouse-down'
      @sprite.on 'click',     @onMouseEvent, @, false, 'sprite:clicked'
      @sprite.on 'dblclick',  @onMouseEvent, @, false, 'sprite:double-clicked'
      @sprite.on 'pressmove', @onMouseEvent, @, false, 'sprite:dragged'
      @sprite.on 'pressup',   @onMouseEvent, @, false, 'sprite:mouse-up'

  onMouseEvent: (e, ourEventName) ->
    return if @letterboxOn or not @sprite
    p = @sprite
    p = p.parent while p.parent
    newEvent = sprite: @, thang: @thang, originalEvent: e, canvas: p.canvas
    @trigger ourEventName, newEvent
    Backbone.Mediator.publish ourEventName, newEvent
    @gameUIState.trigger(ourEventName, newEvent)

  addHealthBar: ->
    return unless @thang?.health? and 'health' in (@thang?.hudProperties ? []) and @options.floatingLayer
    team = @thang?.team or 'neutral'
    key = "#{team}-health-bar"

    unless key in @options.floatingLayer.spriteSheet.animations
      healthColor = healthColors[team]
      bar = createProgressBar(healthColor)
      @options.floatingLayer.addCustomGraphic(key, bar, bar.bounds)

    hadHealthBar = @healthBar
    @healthBar = new createjs.Sprite(@options.floatingLayer.spriteSheet)
    @healthBar.gotoAndStop(key)
    offset = @getOffset 'aboveHead'
    @healthBar.scaleX = @healthBar.scaleY = 1 / @options.floatingLayer.resolutionFactor
    @healthBar.name = 'health bar'
    @options.floatingLayer.addChild @healthBar
    @updateHealthBar()
    @lastHealth = null
    if not hadHealthBar
      @listenTo @options.floatingLayer, 'new-spritesheet', @addHealthBar

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
      scale *= @sprite.parent.resolutionFactor if prop is 'registration'
      pos.x *= scale
      pos.y *= scale
    if @thang and prop isnt 'registration'
      pos.x *= @thang.scaleFactorX ? @thang.scaleFactor ? 1
      pos.y *= @thang.scaleFactorY ? @thang.scaleFactor ? 1
    # We might need to do this, but I don't have a good test case yet. TODO: figure out.
    #if prop isnt @registration
    #  pos.x *= if @getActionProp 'flipX' then -1 else 1
    #  pos.y *= if @getActionProp 'flipY' then -1 else 1
    pos

  createMarks: ->
    return unless @options.camera
    if @thang
      # TODO: Add back ranges
#      allProps = []
#      allProps = allProps.concat (@thang.hudProperties ? [])
#      allProps = allProps.concat (@thang.programmableProperties ? [])
#      allProps = allProps.concat (@thang.moreProgrammableProperties ? [])
#
#      for property in allProps
#        if m = property.match /.*(Range|Distance|Radius)$/
#          if @thang[m[0]]? and @thang[m[0]] < 9001
#            @ranges.push
#              name: m[0]
#              radius: @thang[m[0]]
#
#      @ranges = _.sortBy @ranges, 'radius'
#      @ranges.reverse()
#
#      @addMark range.name for range in @ranges

      # TODO: add back bounds
#      @addMark('bounds').toggle true if @thang?.drawsBounds
      @addMark('shadow').toggle true unless @thangType.get('shadow') is 0

  updateMarks: ->
    return unless @options.camera
    @addMark 'repair', null, 'repair' if @thang?.erroredOut
    @marks.repair?.toggle @thang?.erroredOut

    if @selected
      @marks[range['name']].toggle true for range in @ranges
    else
      @marks[range['name']].toggle false for range in @ranges

    if @isMissile and @thang.action is 'die'
      @marks.shadow?.hide()
    mark.update() for name, mark of @marks
    #@thang.effectNames = ['warcry', 'confuse', 'control', 'curse', 'fear', 'poison', 'paralyze', 'regen', 'sleep', 'slow', 'haste']
    @updateEffectMarks() if @thang?.effectNames?.length or @previousEffectNames?.length

  updateEffectMarks: ->
    return if _.isEqual @thang.effectNames, @previousEffectNames
    return if @stopped
    @thang.effectNames ?= []
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
    if d = @marks.debug
      d.toggle debug
      d.updatePosition()

  addLabel: (name, style, labelOptions={}) ->
    @labels[name] ?= new Label sprite: @, camera: @options.camera, layer: @options.textLayer, style: style, labelOptions: labelOptions
    @labels[name]

  addMark: (name, layer, thangType=null) ->
    @marks[name] ?= new Mark name: name, lank: @, camera: @options.camera, layer: layer ? @options.groundLayer, thangType: thangType
    @marks[name]

  removeMark: (name) ->
    @marks[name].destroy()
    delete @marks[name]

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
    unless @thang?.id is 'Hero Placeholder'  # Don't show these for heroes, because they aren't actually first-person, just LevelDialogueView narration
      label = @addLabel 'dialogue', Label.STYLE_DIALOGUE
      label.setText e.blurb or '...'
    sound = e.sound ? AudioPlayer.soundForDialogue e.message, @thangType.get 'soundTriggers'
    @dialogueSoundInstance?.stop()
    if @dialogueSoundInstance = @playSound sound, false
      @dialogueSoundInstance.addEventListener 'complete', -> Backbone.Mediator.publish 'sprite:dialogue-sound-completed', {}
    @notifySpeechUpdated e

  onClearDialogue: (e) ->
    return unless @labels.dialogue?.text
    @labels.dialogue?.setText null
    @dialogueSoundInstance?.stop()
    @notifySpeechUpdated {}

  onSetLetterbox: (e) ->
    @letterboxOn = e.on

  setNameLabel: (name) ->
    label = @addLabel 'name', Label.STYLE_NAME
    label.setText name

  updateLabels: ->
    return unless @thang
    blurb = if @thang.health? and @thang.health <= 0 then null else @thang.sayMessage  # Dead men tell no tales, however non-alive can
    blurb = null if blurb in ['For Thoktar!', 'Bones!', 'Behead!', 'Destroy!', 'Die, humans!']  # Let's just hear, not see, these ones.
    if /Hero Placeholder/.test(@thang.id)
      labelStyle = Label.STYLE_DIALOGUE
    else
      labelStyle = @thang.labelStyle ? Label.STYLE_SAY
    if blurb
      @addLabel 'say', labelStyle, @thang.sayLabelOptions
    if @labels.say?.setText blurb
      @notifySpeechUpdated blurb: blurb

    if @thang?.variableNames?
      ls = @addLabel 'variableNames', Label.STYLE_VAR
      ls.setText @thang?.variableNames
    else if @labels.variableNames
      @labels.variableNames.destroy()
      delete @labels.variableNames

    label.update() for name, label of @labels

  updateGold: ->
    # TODO: eventually this should be moved into some sort of team-based update
    # rather than an each-thang-that-shows-gold-per-team thing.
    return unless @thang
    return if @thang.gold is @lastGold
    gold = Math.floor @thang.gold ? 0
    if @thang.world.age is 0
      gold = @thang.world.initialTeamGold[@thang.team].gold
    return if gold is @lastGold
    @lastGold = gold
    Backbone.Mediator.publish 'surface:gold-changed', {team: @thang.team, gold: gold, goldEarned: Math.floor(@thang.goldEarned ? 0)}

  shouldMuteMessage: (m) ->
    return false if m in ['moveRight', 'moveUp', 'moveDown', 'moveLeft']
    @previouslySaidMessages ?= {}
    t0 = @previouslySaidMessages[m] ? 0
    t1 = new Date()
    @previouslySaidMessages[m] = t1
    return true if t1 - t0 < 5 * 1000
    false

  playSounds: (withDelay=true, volume=1.0) ->
    for event in @thang.currentEvents ? []
      @playSound event, withDelay, volume
      if event is 'pay-bounty-gold' and @thang.bountyGold > 25 and @thang.team isnt me.team
        AudioPlayer.playInterfaceSound 'coin_1', 0.25
    if @thang.actionActivated and (action = @thang.getActionName()) isnt 'say'
      @playSound action, withDelay, volume
    if @thang.sayMessage and withDelay and not @thang.silent and not @shouldMuteMessage @thang.sayMessage  # don't play sayMessages while scrubbing, annoying
      offsetFrames = Math.abs(@thang.sayStartTime - @thang.world.age) / @thang.world.dt
      if offsetFrames <= 2  # or (not withDelay and offsetFrames < 30)
        sound = AudioPlayer.soundForDialogue @thang.sayMessage, @thangType.get 'soundTriggers'
        @playSound sound, false, volume

  playSound: (sound, withDelay=true, volume=1.0) ->
    if _.isString sound
      soundTriggers = utils.i18n @thangType.attributes, 'soundTriggers'
      sound = soundTriggers?[sound]
    if _.isArray sound
      sound = sound[Math.floor Math.random() * sound.length]
    return null unless sound
    delay = if withDelay and sound.delay then 1000 * sound.delay / createjs.Ticker.framerate else 0
    name = AudioPlayer.nameForSoundReference sound
    AudioPlayer.preloadSoundReference sound
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
    Backbone.Mediator.publish 'level:sprite-clear-dialogue', {}
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
      @sprite.gotoAndPlay?(endAnimation)
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
      @sprite.gotoAndPlay(endAnimation) unless @stillLoading
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
    bounds = @healthBar.getBounds()
    offset = @getOffset 'aboveHead'
    @healthBar.x = @sprite.x - (-offset.x + bounds.width / 2 / @options.floatingLayer.resolutionFactor)
    @healthBar.y = @sprite.y - (-offset.y + bounds.height / 2 / @options.floatingLayer.resolutionFactor)

  destroy: ->
    mark.destroy() for name, mark of @marks
    label.destroy() for name, label of @labels
    p.removeChild @healthBar if p = @healthBar?.parent
    @sprite?.off 'animationend', @playNextAction
    clearInterval @effectInterval if @effectInterval
    @dialogueSoundInstance?.removeAllEventListeners()
    super()
