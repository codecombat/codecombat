IndieLank = require 'lib/surface/IndieLank'
{me} = require 'core/auth'

module.exports = class WizardLank extends IndieLank
  # Wizard targets are constantly changing, so a simple tween doesn't work.
  # Instead, the wizard stores its origin point and the (possibly) moving target.
  # Then it figures out its current position based on tween percentage and
  # those two points.
  tweenPercentage: 1.0
  originPos: null
  targetPos: null
  targetLank: null
  reachedTarget: true
  spriteXOffset: 4  # meters from target sprite
  spriteYOffset: 0  # meters from target sprite

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'
    'auth:me-synced': 'onMeSynced'
    'surface:sprite-selected': 'onLankSelected'
    'sprite:echo-all-wizard-sprites': 'onEchoAllWizardLanks'

  shortcuts:
    'up': 'onMoveKey'
    'down': 'onMoveKey'
    'left': 'onMoveKey'
    'right': 'onMoveKey'

  constructor: (thangType, options) ->
    if @isSelf = options.isSelf
      options.colorConfig = $.extend(true, {}, me.get('wizard')?.colorConfig) or {}
    super thangType, options
    @targetPos = @thang.pos
    if @isSelf
      @setNameLabel me.displayName()
    else if options.name
      @setNameLabel options.name
    Backbone.Mediator.publish 'self-wizard:created', sprite: @

  makeIndieThang: (thangType, options) ->
    thang = super thangType, options
    thang.isSelectable = false
    thang.bobHeight = 0.75
    thang.bobTime = 2
    thang.pos.z += thang.bobHeight
    thang

  finishSetup: ->
    @scaleFactor = @thang.scaleFactor if @thang?.scaleFactor
    @updateScale()
    @updateRotation()
    # Don't call general update() because Thang isn't built yet

  setNameLabel: (name) ->
    if @options.codeLanguage and @options.codeLanguage isnt 'javascript' and not @isSelf
      name += " (#{@options.codeLanguage})"  # TODO: move on second line, capitalize properly
    super name

  toggle: (to) ->
    @sprite?.visible = to
    label[if to then 'show' else 'hide']() for name, label of @labels
    mark.mark?.visible = to for name, mark of @marks

  onPlayerStatesChanged: (e) ->
    for playerID, state of e.states
      continue unless playerID is @thang.id
      @setEditing state.wizard?.editing
      continue if playerID is me.id  # ignore changes for self wizard lank
      @setNameLabel state.name
      continue unless state.wizard?
      if targetID = state.wizard.targetLank
        return console.warn 'Wizard Lank couldn\'t find target lank', targetID unless targetID of @options.lanks
        @setTarget @options.lanks[targetID]
      else
        @setTarget state.wizard.targetPos

  onMeSynced: (e) ->
    return unless @isSelf
    @setNameLabel me.displayName() if @sprite.visible  # not if we hid the wiz
    newColorConfig = me.get('wizard')?.colorConfig or {}
    shouldUpdate = not _.isEqual(newColorConfig, @options.colorConfig)
    @options.colorConfig = $.extend(true, {}, newColorConfig)
    if shouldUpdate
      @playAction(@currentAction) if @currentAction

  onLankSelected: (e) ->
    return unless @isSelf
    @setTarget e.sprite or e.worldPos

  animateIn: ->
    @sprite.scaleX = @sprite.scaleY = @sprite.alpha = 0
    createjs.Tween.get(@sprite)
      .to({scaleX: 1, scaleY: 1, alpha: 1}, 1000, createjs.Ease.getPowInOut(2.2))
    @labels.name?.show()

  animateOut: (callback) ->
    tween = createjs.Tween.get(@sprite)
      .to({scaleX: 0, scaleY: 0, alpha: 0}, 1000, createjs.Ease.getPowInOut(2.2))
    tween.call(callback) if callback
    @labels.name?.hide()

  setEditing: (@editing) ->
    if @editing
      @thang.actionActivated = @thang.action isnt 'cast'
      @thang.action = 'cast'
    else
      @thang.action = 'idle' if @thang.action is 'cast'

  setInitialState: (targetPos, @targetLank) ->
    @targetPos = @getPosFromTarget(@targetLank or targetPos)
    @endMoveTween()

  onEchoAllWizardLanks: (e) -> e.payload.push @
  defaultPos: -> x: 35, y: 24, z: @thang.depth / 2 + @thang.bobHeight
  move: (pos, duration) -> @setTarget(pos, duration)

  setTarget: (newTarget, duration, isLinear=false) ->
    # ignore targets you're already heading for
    targetPos = @getPosFromTarget(newTarget)
    return if @targetPos and @targetPos.x is targetPos.x and @targetPos.y is targetPos.y

    # ignore selecting sprites you can't control
    isLank = newTarget?.thang?
    return if isLank and not newTarget.thang.isProgrammable
    return if isLank and newTarget is @targetLank

    @shoveOtherWizards(true) if @targetLank
    @targetLank = if isLank then newTarget else null
    @targetPos = @boundWizard targetPos
    @beginMoveTween(duration, isLinear)
    @shoveOtherWizards()
    Backbone.Mediator.publish('self-wizard:target-changed', {sprite: @}) if @isSelf

  boundWizard: (target) ->
    # Passed an {x, y} in world coordinates, returns {x, y} within world bounds
    return target unless @options.camera.bounds
    @bounds = @options.camera.bounds
    surfaceTarget = @options.camera.worldToSurface target
    x = Math.min(Math.max(surfaceTarget.x, @bounds.x), @bounds.x + @bounds.width)
    y = Math.min(Math.max(surfaceTarget.y, @bounds.y), @bounds.y + @bounds.height)
    return @options.camera.surfaceToWorld {x: x, y: y}

  getPosFromTarget: (target) ->
    """
    Could be null, a vector, or sprite object. Get the position from any of these.
    """
    return @defaultPos() unless target?
    return target if target.x?
    return target.thang.pos

  beginMoveTween: (duration=1000, isLinear=false) ->
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
    if isLinear
      ease = createjs.Ease.linear
    else
      ease = createjs.Ease.getPowInOut(3.0)

    createjs.Tween
      .get(@)
      .to({tweenPercentage: 0.0}, duration, ease)
      .call(@endMoveTween)
    @reachedTarget = false
    @update true

  shoveOtherWizards: (removeMe) ->
    return unless @targetLank
    allWizards = []
    Backbone.Mediator.publish 'sprite:echo-all-wizard-sprites', payload: allWizards
    allOfUs = (wizard for wizard in allWizards when wizard.targetLank is @targetLank)
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
    return if @destroyed
    @thang.action = if @editing then 'cast' else 'idle'
    @thang.actionActivated = @thang.action is 'cast'
    @reachedTarget = true
    @faceTarget()
    @update true

  updatePosition: (whileLoading=false) ->
    return if whileLoading or not @options.camera
    @thang.pos = @getCurrentPosition()
    @faceTarget()
    sup = @options.camera.worldToSurface x: @thang.pos.x, y: @thang.pos.y, z: @thang.pos.z - @thang.depth / 2
    @sprite.x = sup.x
    @sprite.y = sup.y

  getCurrentPosition: ->
    """
    Takes into account whether the wizard is in transit or not, and the bobbing up and down.
    Eventually will also adjust based on where other wizards are.
    """
    @targetPos = @targetLank.thang.pos if @targetLank?.thang
    pos = _.clone(@targetPos)
    pos.z = @defaultPos().z + @getBobOffset()
    @adjustPositionToSideOfTarget(pos) if @targetLank  # be off to the side depending on placement in world
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
    if @targetLank?.thang
      @pointToward(@targetLank.thang.pos)

  updateMarks: ->
    super() if @sprite.visible  # not if we hid the wiz

  onMoveKey: (e) ->
    return unless @isSelf
    e?.preventDefault()
    yMovement = 0
    xMovement = 0
    yMovement += 2 if key.isPressed('up')
    yMovement -= 2 if key.isPressed('down')
    xMovement += 2 if key.isPressed('right')
    xMovement -= 2 if key.isPressed('left')
    @moveWizard xMovement, yMovement

  moveWizard: (x, y) ->
    interval = 500
    position = {x: @targetPos.x + x, y: @targetPos.y + y}
    @setTarget(position, interval, true)
    @updatePosition()
    Backbone.Mediator.publish 'camera:zoom-to', pos: position, duration: interval
