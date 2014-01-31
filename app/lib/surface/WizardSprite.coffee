IndieSprite = require 'lib/surface/IndieSprite'
Camera = require './Camera'
{me} = require 'lib/auth'

module.exports = class WizardSprite extends IndieSprite
  # Wizard targets are constantly changing, so a simple tween doesn't work.
  # Instead, the wizard stores its origin point and the (possibly) moving target.
  # Then it figures out its current position based on tween percentage and
  # those two points.
  tweenPercentage: 1.0
  originPos: null
  targetPos: null
  targetSprite: null
  reachedTarget: true
  spriteXOffset: 4  # meters from target sprite
  spriteYOffset: 0  # meters from target sprite

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'
    'me:synced': 'onMeSynced'
    'surface:sprite-selected': 'onSpriteSelected'
    'echo-self-wizard-sprite': 'onEchoSelfWizardSprite'
    'echo-all-wizard-sprites': 'onEchoAllWizardSprites'

  constructor: (thangType, options) ->
    if options?.isSelf
      options.colorConfig = me.get('wizard')?.colorConfig or {}
    super thangType, options
    @isSelf = options.isSelf
    @targetPos = @thang.pos
    if @isSelf
      @setNameLabel me.displayName()
      @setColorHue me.get('wizardColor1')

  makeIndieThang: (thangType, thangID, pos) ->
    thang = super thangType, thangID, pos
    thang.isSelectable = false
    thang.bobHeight = 1.5
    thang.bobTime = 2
    thang

  onPlayerStatesChanged: (e) ->
    for playerID, state of e.states
      continue unless playerID is @thang.id
      @setEditing state.wizard?.editing
      continue if playerID is me.id  # ignore changes for self wizard sprite
      @setNameLabel state.name
      continue unless state.wizard?
      @setColorHue state.wizard.wizardColor1
      if targetID = state.wizard.targetSprite
        return console.warn "Wizard Sprite couldn't find target sprite", targetID unless targetID of @options.sprites
        @setTarget @options.sprites[targetID]
      else
        @setTarget state.wizard.targetPos

  onMeSynced: (e) ->
    return unless @isSelf
    @setNameLabel me.displayName() if @displayObject.visible  # not if we hid the wiz
    @setColorHue me.get('wizardColor1')

  onSpriteSelected: (e) ->
    return unless @isSelf
    @setTarget e.sprite or e.worldPos

  animateIn: ->
    @displayObject.scaleX = @displayObject.scaleY = @displayObject.alpha = 0
    createjs.Tween.get(@displayObject)
      .to({scaleX: 1, scaleY: 1, alpha: 1}, 1000, createjs.Ease.getPowInOut(2.2))

  animateOut: (callback) ->
    tween = createjs.Tween.get(@displayObject)
      .to({scaleX: 0, scaleY: 0, alpha: 0}, 1000, createjs.Ease.getPowInOut(2.2))
    tween.call(callback) if callback

  # We need the generalizable tinting system included in spritesheet making
  #updateColorFilters: ->
  #  return if @colorHue is undefined
  #  rgb = hslToRgb(@colorHue, 1.0, 0.75)
  #  rgb = (parseInt(val) / 256 for val in rgb)
  #  rgb = rgb.concat([1, 0, 0, 0, 0])
  #  filter = new createjs.ColorFilter(rgb...)
  #  dob = @imageObject
  #  dob.filters = [filter]
  #  dob.cache(0, 0, @data.width, @data.height, Math.abs(dob.scaleX*2))

  setColorHue: (newColorHue) ->
    return if @colorHue is newColorHue
    @colorHue = newColorHue
    #@updateColorFilters()

  setEditing: (@editing) ->
    if @editing
      @thang.actionActivated = @thang.action isnt 'cast'
      @thang.action = 'cast'
    else
      @thang.action = 'idle' if @thang.action is 'cast'

  setInitialState: (targetPos, @targetSprite) ->
    @targetPos = @getPosFromTarget(@targetSprite or targetPos)
    @endMoveTween()

  onEchoSelfWizardSprite: (e) -> e.payload = @ if @isSelf
  onEchoAllWizardSprites: (e) -> e.payload.push @
  defaultPos: -> x: 35, y: 24, z: @thang.depth / 2 + @bobHeight
  move: (pos, duration) -> @setTarget(pos, duration)

  setTarget: (newTarget, duration) ->
    # ignore targets you're already heading for
    targetPos = @getPosFromTarget(newTarget)
    return if @targetPos and @targetPos.x is targetPos.x and @targetPos.y is targetPos.y

    # ignore selecting sprites you can't control
    isSprite = newTarget?.thang?
    return if isSprite and not newTarget.thang.isProgrammable
    return if isSprite and newTarget is @targetSprite

    @shoveOtherWizards(true) if @targetSprite
    @targetSprite = if isSprite then newTarget else null
    @targetPos = targetPos
    @beginMoveTween(duration)
    @shoveOtherWizards()
    Backbone.Mediator.publish('self-wizard:target-changed', {sender:@}) if @isSelf

  getPosFromTarget: (target) ->
    """
    Could be null, a vector, or sprite object. Get the position from any of these.
    """
    return @defaultPos() unless target?
    return target if target.x?
    return target.thang.pos

  beginMoveTween: (duration=1000) ->
    # clear the old tween
    createjs.Tween.removeTweens(@)

    # create a new tween to go from the current location to the new location
    @originPos = _.clone(@thang.pos)
    @tweenPercentage = 1.0
    @thang.action = 'move'
    @pointToward(@targetPos)
    if duration is 0
      @updatePosition()
      @endMoveTween()
      return

    ease = createjs.Ease.getPowInOut(3.0)
    createjs.Tween
      .get(@)
      .to({tweenPercentage:0.0}, duration, ease)
      .call(@endMoveTween)
    @reachedTarget = false

  shoveOtherWizards: (removeMe) ->
    return unless @targetSprite
    allWizards = []
    Backbone.Mediator.publish('echo-all-wizard-sprites', {payload:allWizards})
    allOfUs = (wizard for wizard in allWizards when wizard.targetSprite is @targetSprite)
    allOfUs = (wizard for wizard in allOfUs when wizard isnt @) if removeMe

    # diagonal lineup pattern
#    wizardPosition = [[4, 0], [5,1], [3,-1], [6,2], [2,-2]]
#    step = 3
#    for wizard, i in allOfUs
#      [x,y] = wizardPositions[i%@wizardPositions.length]
#      wizard.spriteXOffset = x
#      wizard.spriteYOffset = y
#      wizard.beginMoveTween()

    # circular pattern
    step = Math.PI * 2 / allOfUs.length
    for wizard, i in allOfUs
      wizard.spriteXOffset = 5*Math.cos(step*i)
      wizard.spriteYOffset = 4*Math.sin(step*i)
      wizard.beginMoveTween()

  endMoveTween: =>
    @thang.action = if @editing then 'cast' else 'idle'
    @thang.actionActivated = @thang.action is 'cast'
    @reachedTarget = true
    @faceTarget()

  updatePosition: ->
    return unless @options.camera
    @thang.pos = @getCurrentPosition()
    @faceTarget()
    sup = @options.camera.worldToSurface x: @thang.pos.x, y: @thang.pos.y, z: @thang.pos.z - @thang.depth / 2 + @getBobOffset()
    @displayObject.x = sup.x
    @displayObject.y = sup.y

  getCurrentPosition: ->
    """
    Takes into account whether the wizard is in transit or not, and the bobbing up and down.
    Eventually will also adjust based on where other wizards are.
    """
    @targetPos = @targetSprite.thang.pos if @targetSprite
    pos = _.clone(@targetPos)
    pos.z += @thang.bobHeight
    @adjustPositionToSideOfTarget(pos) if @targetSprite  # be off to the side depending on placement in world
    return pos if @reachedTarget  # stick like glue

    # if here, then the wizard is in transit. Calculate the diff!
    pos =
      x: pos.x + ((@originPos.x - pos.x) * @tweenPercentage)
      y: pos.y + ((@originPos.y - pos.y) * @tweenPercentage)
      z: pos.z
    return pos

  adjustPositionToSideOfTarget: (targetPos) ->
    targetPos.x += @spriteXOffset
    return
    # doesn't work when you're zoomed in on the target, so disabling
    center = @options.camera.surfaceToWorld(@options.camera.currentTarget).x
    distanceFromCenter = Math.abs(targetPos.x - center)
    if @spriteXOffset
      distanceFromTarget = Math.abs(@spriteXOffset) - (1 / (distanceFromCenter + (1/Math.abs(@spriteXOffset))))
    else
      distanceFromTarget = 0
    @onLeftSide = targetPos.x > center
    @onLeftSide = not @onLeftSide if @spriteXOffset < 0
    distanceFromTarget *= -1 if @onLeftSide
    targetPos.x += distanceFromTarget # adjusted
    targetPos.y += @spriteYOffset

  faceTarget: ->
    if @targetSprite
      @pointToward(@targetSprite.thang.pos)

  updateMarks: ->
    super() if @displayObject.visible  # not if we hid the wiz
