# paths before the current state taper out,
# and have a different color than the future
PAST_PATH_TAIL_BRIGHTNESS = 150
PAST_PATH_TAIL_ALPHA = 0.3
PAST_PATH_HEAD_BRIGHTNESS = 200
PAST_PATH_HEAD_ALPHA = 0.75

PAST_PATH_HEAD_LENGTH = 50
PAST_PATH_TAIL_WIDTH = 2
PAST_PATH_HEAD_WIDTH = 2
PAST_PATH_MAX_LENGTH = 200

# paths in the future are single color dotted lines
FUT_PATH_BRIGHTNESS = 153
FUT_PATH_ALPHA = 0.8
FUT_PATH_HEAD_LENGTH = 0
FUT_PATH_WIDTH = 1
FUT_PATH_MAX_LENGTH = 2000

# selected paths are single color, and larger, more prominent
# most other properties are the same as non-selected
SELECTED_PATH_TAIL_BRIGHTNESS = 146
SELECTED_PATH_TAIL_ALPHA = 0.5
SELECTED_PATH_HEAD_BRIGHTNESS = 200
SELECTED_PATH_HEAD_ALPHA = 1.0
SELECTED_PAST_PATH_MAX_LENGTH = 2000

FUT_SELECTED_PATH_WIDTH = 3

# for sprites along the path
CLONE_INTERVAL = 250 # distance between them, ignored for new actions
CLONE_SCALE = 1.0
CLONE_ALPHA = 0.4

# path defaults
PATH_DOT_LENGTH = 3
PATH_SEGMENT_LENGTH = 15 # should be > PATH_DOT_LENGTH

Camera = require './Camera'

module.exports.Trailmaster = class Trailmaster
  paths: null # dictionary of thang ids to containers for their paths
  selectedPath: null # container of path selected
  pathDisplayObject: null
  world: null
  clock: 0

  constructor: (@camera) ->

  tick: ->
    @clock += 1

  generatePaths: (@world, @currentFrame, @selectedThang, @sprites, @selectedOnly) ->
    @paths = {}
    @pathDisplayObject = new createjs.Container()
    @pathDisplayObject.mouseEnabled = @pathDisplayObject.mouseChildren = false
    for thang in world.thangs
      continue unless thang.isSelectable
      continue unless thang.isMovable
      continue if @selectedOnly and thang isnt @selectedThang
      path = @createPathForThang thang
      continue if not path
      @pathDisplayObject.addChild path
      @paths[thang.id] = path
    @pathDisplayObject

  createPathForThang: (thang) ->
    container = new createjs.Container()

    path = @createPastPathForThang(thang)
    container.addChild(path) if path

    path = @createFuturePathForThang(thang)
    container.addChild(path) if path

    targets = @createTargetsForThang(thang)
    container.addChild(targets) if targets

    if thang is @selectedThang
      sprites = @spritesForThang(thang)
      for sprite in sprites
        container.addChild(sprite)

    container

  createPastPathForThang: (thang) ->
    maxLength = if thang is @selectedThang then SELECTED_PAST_PATH_MAX_LENGTH else PAST_PATH_MAX_LENGTH
    start = Math.max(@currentFrame - maxLength, 0)
    start = 0 if thang isnt @selectedThang
    resolution = if thang is @selectedThang then 4 else 12
    return unless points = @world.pointsForThang thang.id, start, @currentFrame, @camera, resolution
    params =
      tailWidth: PAST_PATH_TAIL_WIDTH
      headWidth: PAST_PATH_HEAD_WIDTH
      headLength: PAST_PATH_HEAD_LENGTH
    if thang is @selectedThang
      params['tailColor'] = colorForThang(thang.team, SELECTED_PATH_TAIL_BRIGHTNESS, SELECTED_PATH_TAIL_ALPHA)
      params['headColor'] = colorForThang(thang.team, SELECTED_PATH_HEAD_BRIGHTNESS, SELECTED_PATH_HEAD_ALPHA)
    else
      params['tailColor'] = colorForThang(thang.team, PAST_PATH_TAIL_BRIGHTNESS, PAST_PATH_TAIL_ALPHA)
      params['headColor'] = colorForThang(thang.team, PAST_PATH_HEAD_BRIGHTNESS, PAST_PATH_HEAD_ALPHA)
    return createPath(points, params)


  createFuturePathForThang: (thang) ->
    resolution = 8
    return unless points = @world.pointsForThang thang.id, @currentFrame, @currentFrame + FUT_PATH_MAX_LENGTH, @camera, resolution
    if thang is @selectedThang
      color = colorForThang(thang.team, SELECTED_PATH_HEAD_BRIGHTNESS, SELECTED_PATH_HEAD_ALPHA)
    else
      color = colorForThang(thang.team, FUT_PATH_BRIGHTNESS, FUT_PATH_ALPHA)
    return createPath(points,
      tailColor: color
      tailWidth: if thang is @selectedThang then FUT_SELECTED_PATH_WIDTH else FUT_PATH_WIDTH
      headLength: FUT_PATH_HEAD_LENGTH
      dotted: true
      dotOffset: @clock
    )

  createTargetsForThang: (thang) ->
    return unless thang.allTargets
    g = new createjs.Graphics()
    g.setStrokeStyle(0.5)
    g.beginStroke(createjs.Graphics.getRGB(0, 0, 0))
    color = colorForThang(thang.team)

    i = 0
    while i < thang.allTargets.length
      g.beginStroke(createjs.Graphics.getRGB(0, 0, 0))
      g.beginFill(createjs.Graphics.getRGB(color...))
      sup = @camera.worldToSurface x: thang.allTargets[i], y: thang.allTargets[i + 1]
      g.drawEllipse(sup.x - 5, sup.y - 3, 10, 6)
      g.endStroke()

      i += 2

    s = new createjs.Shape(g)
    s.x = 0
    s.y = 0
    s

  spritesForThang: (thang) ->
    i = 0
    sprites = []
    sprite = @sprites[thang.id]
    return sprites unless sprite?
    lastPos = @camera.surfaceToWorld x: sprite.imageObject.x, y: sprite.imageObject.y
    minDistance = Math.pow(CLONE_INTERVAL * Camera.MPP, 2)
    actions = @world.actionsForThang(thang.id)
    lastAction = null

    for action in actions
      continue if action.name in ['idle', 'move']
      frame = @world.frames[action.frame]
      frame.restoreStateForThang(thang)

      if lastPos
        diff = Math.pow(lastPos.x - thang.pos.x, 2)
        diff += Math.pow(lastPos.y - thang.pos.y, 2)
        continue if diff < minDistance and action.name is lastAction

      clone = sprite.imageObject.clone()
      clonePos = @camera.worldToSurface thang.pos
      clone.x = clonePos.x
      clone.y = clonePos.y
      clone.alpha = CLONE_ALPHA
      clone.scaleX *= CLONE_SCALE
      clone.scaleY *= CLONE_SCALE
      if sprite.expandActions  # old Sprite
        sprite.updateRotation(clone, sprite.data)
        animActions = sprite.expandActions(if thang.acts then thang.getActionName() else 'idle')
        sprite.applyActionsToSprites(animActions, [clone], true)
        animation = clone.spriteSheet.getAnimation(clone.currentAnimation)
        clone.currentAnimationFrame = Math.min(@clock % (animation.frames.length * 3), animation.frames.length - 1)
      else
        continue unless animation = sprite.actions[action.name]
        sprite.updateRotation clone
        animation = sprite.getActionDirection(animation) ? animation  # no idea if this ever works
        clone.gotoAndStop animation.name
        # TODO: use action-specific framerate here?
#        clone.currentAnimationFrame = Math.min(@clock % (animation.frames.length * 3), animation.frames.length - 1)
      sprites.push(clone)
      lastPos = x: thang.pos.x, y: thang.pos.y
      lastAction = action.name

    @world.frames[@currentFrame].restoreStateForThang(thang)
    sprites

createPath = (points, options={}, g=null) ->
  options = options or {}
  tailColor = options.tailColor ? options.headColor
  headColor = options.headColor ? options.tailColor
  oneColor = true
  oneColor = oneColor and headColor[i] is tailColor[i] for i in [0..4]
  maxLength = options.maxLength or 0
  tailWidth = options.tailWidth
  headWidth = options.headWidth
  oneWidth = headWidth is tailWidth
  headLength = options.headLength
  dotted = options.dotted
  dotOffset = if options.dotOffset? then options.dotOffset else 0

  points = points.slice(-maxLength * 2) if maxLength isnt 0
  points = points.slice(((points.length / 2 + dotOffset) % PATH_SEGMENT_LENGTH) * 2) if dotOffset
  g = new createjs.Graphics() unless g
  return new createjs.Shape(g) if not points

  g.setStrokeStyle(tailWidth)
  g.beginStroke(createjs.Graphics.getRGB(tailColor...))
  g.moveTo(points[0], points[1])

  headStart = points.length - headLength
  [lastX, lastY] = [points[0], points[1]]

  for x, i in points by 2
    continue if i is 0
    y = points[i + 1]
    if i >= headStart and not (oneColor and oneWidth)
      diff = (i - headStart) / headLength
      style = transition(tailWidth, headWidth, diff)
      color = colorTransition(tailColor, headColor, diff)
      g.setStrokeStyle(style)
      g.beginStroke(createjs.Graphics.getRGB(color...))
      g.moveTo(lastX, lastY) if lastX?

    else if dotted

      if false and i < 2
        # Test: footprints
        g.beginFill(createjs.Graphics.getRGB(tailColor...))
        xofs = x - lastX
        yofs = y - lastY
        theta = Math.atan2(yofs, xofs)
        [fdist, fwidth] = [4, 2]
        fside = if (i + dotOffset) % 4 is 0 then -1 else 1
        fx = [lastX + fside * fdist * (Math.cos(theta) * xofs - Math.sin(theta) * yofs)]
        fy = [lastY + fside * fdist * (Math.sin(theta) * xofs - Math.cos(theta) * yofs)]
        g.drawCircle(fx, fy, 2)

      offset = ((i / 2) % PATH_SEGMENT_LENGTH)
      if offset >= PATH_DOT_LENGTH
        if offset is PATH_DOT_LENGTH
          g.endStroke()
        lastX = x
        lastY = y
        continue

      else
        if offset is 0
          g.beginStroke(createjs.Graphics.getRGB(tailColor...))
          g.moveTo(lastX, lastY) if lastX?

    g.lineTo(x, y)
    lastX = x
    lastY = y

  g.endStroke()

  s = new createjs.Shape(g)
  return s

colorTransition = (color1, color2, pct) ->
  return color1 if pct <= 0
  return color2 if pct >= 1

  i = 0
  color = []
  while i < 4
    val = transition(color1[i], color2[i], pct)
    val = Math.floor(val) if i isnt 3
    color.push(val)
    i += 1
  color

transition = (num1, num2, pct) ->
  return num1 if pct <= 0
  return num2 if pct >= 1
  num1 + (num2 - num1) * pct

colorForThang = (team, brightness=100, alpha=1.0) =>
  # multipliers should sum to 3.0
  multipliers = [2.0, 0.5, 0.5] if team is 'humans'
  multipliers = [0.5, 0.5, 2.0] if team is 'ogres'
  multipliers = [2.0, 0.5, 0.5] if not multipliers
  color = _.map(multipliers, (m) -> return parseInt(m * brightness))
  color.push(alpha)
  return color

module.exports.createPath = createPath
