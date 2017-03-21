CocoClass = require 'core/CocoClass'
GameUIState = require 'models/GameUIState'

# If I were the kind of math major who remembered his math, this would all be done with matrix transforms.

r2d = (radians) -> radians * 180 / Math.PI
d2r = (degrees) -> degrees / 180 * Math.PI

MAX_ZOOM = 8
MIN_ZOOM = 0.1
DEFAULT_ZOOM = 2.0
DEFAULT_TARGET = {x: 0, y: 0}
DEFAULT_TIME = 1000
STANDARD_ZOOM_WIDTH = 924
STANDARD_ZOOM_HEIGHT = 589

# You can't mutate any of the constructor parameters after construction.
# You can only call zoomTo to change the zoom target and zoom level.
module.exports = class Camera extends CocoClass
  @PPM: 10   # pixels per meter
  @MPP: 0.1  # meters per pixel; should match @PPM

  bounds: null  # list of two surface points defining the viewable rectangle in the world
                # or null if there are no bounds

  # what the camera is pointed at right now
  target: DEFAULT_TARGET
  zoom: DEFAULT_ZOOM
  canvasScaleFactorX: 1
  canvasScaleFactorY: 1

  # properties for tracking going between targets
  oldZoom: null
  newZoom: null
  oldTarget: null
  newTarget: null
  tweenProgress: 0.0

  instant: false

  # INIT

  subscriptions:
    'camera:zoom-in': 'onZoomIn'
    'camera:zoom-out': 'onZoomOut'
    'camera:zoom-to': 'onZoomTo'
    'level:restarted': 'onLevelRestarted'

  constructor: (@canvas, @options={}) ->
    angle=Math.asin(0.75)
    hFOV=d2r(30)
    super()
    @gameUIState = @options.gameUIState or new GameUIState()
    @listenTo @gameUIState, 'surface:stage-mouse-move', @onMouseMove
    @listenTo @gameUIState, 'surface:stage-mouse-down', @onMouseDown
    @listenTo @gameUIState, 'surface:stage-mouse-up', @onMouseUp
    @listenTo @gameUIState, 'surface:mouse-scrolled', @onMouseScrolled
    @handleEvents = @options.handleEvents ? true
    @canvasWidth = parseInt(@canvas.attr('width'), 10)
    @canvasHeight = parseInt(@canvas.attr('height'), 10)
    @offset = {x: 0, y: 0}
    @calculateViewingAngle angle
    @calculateFieldOfView hFOV
    @calculateAxisConversionFactors()
    @calculateMinMaxZoom()
    @updateViewports()

  onResize: (newCanvasWidth, newCanvasHeight) ->
    @canvasScaleFactorX = newCanvasWidth / @canvasWidth
    @canvasScaleFactorY = newCanvasHeight / @canvasHeight
    Backbone.Mediator.publish 'camera:zoom-updated', camera: @, zoom: @zoom, surfaceViewport: @surfaceViewport

  calculateViewingAngle: (angle) ->
    # Operate on open interval between 0 - 90 degrees to make the math easier
    epsilon = 0.000001  # Too small and numerical instability will get us.
    @angle = Math.max(Math.min(Math.PI / 2 - epsilon, angle), epsilon)
    if @angle isnt angle and angle isnt 0 and angle isnt Math.PI / 2
      console.log "Restricted given camera angle of #{r2d(angle)} to #{r2d(@angle)}."

  calculateFieldOfView: (hFOV) ->
    # http://en.wikipedia.org/wiki/Field_of_view_in_video_games
    epsilon = 0.000001  # Too small and numerical instability will get us.
    @hFOV = Math.max(Math.min(Math.PI - epsilon, hFOV), epsilon)
    if @hFOV isnt hFOV and hFOV isnt 0 and hFOV isnt Math.PI
      console.log "Restricted given horizontal field of view to #{r2d(hFOV)} to #{r2d(@hFOV)}."
    @vFOV = 2 * Math.atan(Math.tan(@hFOV / 2) * @canvasHeight / @canvasWidth)
    if @vFOV > Math.PI
      console.log 'Vertical field of view problem: expected canvas not to be taller than it is wide with high field of view.'
      @vFOV = Math.PI - epsilon

  calculateAxisConversionFactors: ->
    @y2x = Math.sin @angle      # 1 unit along y is equivalent to y2x units along x
    @z2x = Math.cos @angle      # 1 unit along z is equivalent to z2x units along x
    @z2y = @z2x / @y2x          # 1 unit along z is equivalent to z2y units along y
    @x2y = 1 / @y2x             # 1 unit along x is equivalent to x2y units along y
    @x2z = 1 / @z2x             # 1 unit along x is equivalent to x2z units along z
    @y2z = 1 / @z2y             # 1 unit along y is equivalent to y2z units along z

  # CONVERSIONS AND CALCULATIONS

  worldToSurface: (pos) ->
    x = pos.x * Camera.PPM
    y = -pos.y * @y2x * Camera.PPM
    if pos.z
      y -= @z2y * @y2x * pos.z * Camera.PPM
    {x: x, y: y}

  surfaceToCanvas: (pos) ->
    {x: (pos.x - @surfaceViewport.x) * @zoom, y: (pos.y - @surfaceViewport.y) * @zoom}

  canvasToScreen: (pos) ->
    {x: pos.x * @canvasScaleFactorX, y: pos.y * @canvasScaleFactorY}

  screenToCanvas: (pos) ->
    {x: pos.x / @canvasScaleFactorX, y: pos.y / @canvasScaleFactorY}

  canvasToSurface: (pos) ->
    {x: pos.x / @zoom + @surfaceViewport.x, y: pos.y / @zoom + @surfaceViewport.y}

  surfaceToWorld: (pos) ->
    {x: pos.x * Camera.MPP, y: -pos.y * Camera.MPP * @x2y, z: 0}

  canvasToWorld: (pos) -> @surfaceToWorld @canvasToSurface pos
  worldToCanvas: (pos) -> @surfaceToCanvas @worldToSurface pos
  worldToScreen: (pos) -> @canvasToScreen @worldToCanvas pos
  surfaceToScreen: (pos) -> @canvasToScreen @surfaceToCanvas pos
  screenToSurface: (pos) -> @canvasToSurface @screenToCanvas pos
  screenToWorld: (pos) -> @surfaceToWorld @screenToSurface pos

  cameraWorldPos: ->
    # I tried to figure out the math for how much of @vFOV is below the midpoint (botFOV) and how much is above (topFOV), but I failed.
    # So I'm just making something up. This would give botFOV 20deg, topFOV 10deg at @vFOV 30deg and @angle 45deg, or an even 15/15 at @angle 90deg.
    botFOV = @x2y * @vFOV / (@y2x + @x2y)
    topFOV = @y2x * @vFOV / (@y2x + @x2y)
    botDist = @worldViewport.height / 2 * Math.sin(@angle) / Math.sin(botFOV)
    z = botDist * Math.sin(@angle + botFOV)
    x: @worldViewport.cx, y: @worldViewport.cy - z * @z2y, z: z

  distanceTo: (pos) ->
    # Get the physical distance in meters from the camera to the given world pos.
    cpos = @cameraWorldPos()
    dx = pos.x - cpos.x
    dy = pos.y - cpos.y
    dz = (pos.z or 0) - cpos.z
    Math.sqrt dx * dx + dy * dy + dz * dz

  distanceRatioTo: (pos) ->
    # Get the ratio of the distance to the given world pos over the distance to the center of the camera view.
    cpos = @cameraWorldPos()
    dy = @worldViewport.cy - cpos.y
    camDist = Math.sqrt(dy * dy + cpos.z * cpos.z)
    return @distanceTo(pos) / camDist

    # Old method for flying things below; could re-integrate this
    ## Because none of our maps are designed to get smaller with distance along the y-axis, we'll only use z, as if we were looking straight down, until we get high enough. Based on worldPos.z, we gradually shift over to the more-realistic scale. This is pretty hacky.
    #ratioWithoutY = dz * dz / (cPos.z * cPos.z)
    #zv = Math.min(Math.max(0, worldPos.z - 5), cPos.z - 5) / (cPos.z - 5)
    #zv * ratioWithY + (1 - zv) * ratioWithoutY

  # SUBSCRIPTIONS

  onZoomIn: (e) -> @zoomTo @target, @zoom * 1.15, 300
  onZoomOut: (e) -> @zoomTo @target, @zoom / 1.15, 300

  onMouseDown: (e) ->
    return if @dragDisabled
    @lastPos = {x: e.originalEvent.rawX, y: e.originalEvent.rawY}
    @mousePressed = true

  onMouseMove: (e) ->
    return unless @mousePressed and @gameUIState.get('canDragCamera')
    return if @dragDisabled
    target = @boundTarget(@target, @zoom)
    newPos =
      x: target.x + (@lastPos.x - e.originalEvent.rawX) / @zoom
      y: target.y + (@lastPos.y - e.originalEvent.rawY) / @zoom
    @zoomTo newPos, @zoom, 0
    @lastPos = {x: e.originalEvent.rawX, y: e.originalEvent.rawY}
    Backbone.Mediator.publish 'camera:dragged', {}

  onMouseUp: (e) ->
    @mousePressed = false

  onMouseScrolled: (e) ->
    ratio = 1 + 0.05 * Math.sqrt(Math.abs(e.deltaY))
    ratio = 1 / ratio if e.deltaY > 0
    newZoom = @zoom * ratio
    if e.screenPos and not @focusedOnSprite()
      # zoom based on mouse position, adjusting the target so the point under the mouse stays the same
      mousePoint = @screenToSurface(e.screenPos)
      ratioPosX = (mousePoint.x - @surfaceViewport.x) / @surfaceViewport.width
      ratioPosY = (mousePoint.y - @surfaceViewport.y) / @surfaceViewport.height
      newWidth = @canvasWidth / newZoom
      newHeight = @canvasHeight / newZoom
      newTargetX = mousePoint.x - (newWidth * ratioPosX) + (newWidth / 2)
      newTargetY = mousePoint.y - (newHeight * ratioPosY) + (newHeight / 2)
      target = {x: newTargetX, y: newTargetY}
    else
      target = @target
    @zoomTo target, newZoom, 0

  onLevelRestarted: ->
    @setBounds(@firstBounds, false)

  # COMMANDS

  setBounds: (worldBounds, updateZoom=true) ->
    # receives an array of two world points. Normalize and apply them
    @firstBounds = worldBounds unless @firstBounds
    @bounds = @normalizeBounds(worldBounds)
    @calculateMinMaxZoom()
    @updateZoom true if updateZoom
    @target = @currentTarget unless @focusedOnSprite()

  normalizeBounds: (worldBounds) ->
    return null unless worldBounds
    top = Math.max(worldBounds[0].y, worldBounds[1].y)
    left = Math.min(worldBounds[0].x, worldBounds[1].x)
    bottom = Math.min(worldBounds[0].y, worldBounds[1].y)
    right = Math.max(worldBounds[0].x, worldBounds[1].x)
    bottom -= 1 if top is bottom
    right += 1 if left is right
    p1 = @worldToSurface({x: left, y: top})
    p2 = @worldToSurface({x: right, y: bottom})
    {x: p1.x, y: p1.y, width: p2.x-p1.x, height: p2.y-p1.y}

  calculateMinMaxZoom: ->
    # Zoom targets are always done in Surface coordinates.
    @maxZoom = MAX_ZOOM
    return @minZoom = MIN_ZOOM unless @bounds
    @minZoom = Math.max @canvasWidth / @bounds.width, @canvasHeight / @bounds.height
    if @zoom
      @zoom = Math.max @minZoom, @zoom
      @zoom = Math.min @maxZoom, @zoom

  zoomTo: (newTarget=null, newZoom=1.0, time=1500) ->
    # Target is either just a {x, y} pos or a display object with {x, y} that might change; surface coordinates.
    time = 0 if @instant
    newTarget ?= {x: 0, y: 0}
    newTarget = (@newTarget or @target) if @locked
    newZoom = Math.max newZoom, @minZoom
    newZoom = Math.min newZoom, @maxZoom

    thangType = @target?.sprite?.thangType
    if thangType
      @offset = _.clone(thangType.get('positions')?.torso or {x: 0, y: 0})
      scale = thangType.get('scale') or 1
      @offset.x *= scale
      @offset.y *= scale
    else
      @offset = {x: 0, y: 0}

    return if @zoom is newZoom and newTarget is newTarget.x and newTarget.y is newTarget.y

    @finishTween(true)
    if time
      @newTarget = newTarget
      @oldTarget = @boundTarget(@target, @zoom)
      @oldZoom = @zoom
      @newZoom = newZoom
      @tweenProgress = 0.01
      createjs.Tween.get(@)
        .to({tweenProgress: 1.0}, time, createjs.Ease.getPowOut(4))
        .call @finishTween

    else
      @target = newTarget
      @zoom = newZoom
      @updateZoom true

  focusedOnSprite: ->
    return @target?.name

  finishTween: (abort=false) =>
    createjs.Tween.removeTweens(@)
    return unless @newTarget
    unless abort is true
      @target = @newTarget
      @zoom = @newZoom
    @newZoom = @oldZoom = @newTarget = @newTarget = @tweenProgress = null
    @updateZoom true

  updateZoom: (force=false) ->
    # Update when we're focusing on a Thang, tweening, or forcing it, unless we're locked
    return if (not force) and (@locked or (not @newTarget and not @focusedOnSprite()))
    if @newTarget
      t = @tweenProgress
      @zoom = @oldZoom + t * (@newZoom - @oldZoom)
      [p1, p2] = [@oldTarget, @boundTarget(@newTarget, @newZoom)]
      target = @target = x: p1.x + t * (p2.x - p1.x), y: p1.y + t * (p2.y - p1.y)
    else
      target = @boundTarget @target, @zoom
      return if not force and _.isEqual target, @currentTarget
    @currentTarget = target
    viewportDifference = @updateViewports target
    if viewportDifference > 0.1  # Roughly 0.1 pixel difference in what we can see
      Backbone.Mediator.publish 'camera:zoom-updated', camera: @, zoom: @zoom, surfaceViewport: @surfaceViewport, minZoom: @minZoom

  boundTarget: (pos, zoom) ->
    # Given an {x, y} in Surface coordinates, return one that will keep our viewport on the Surface.
    return pos unless @bounds
    y = pos.y
    if thang = pos.sprite?.thang
      y = @worldToSurface(x: thang.pos.x, y: thang.pos.y).y  # ignore z
    marginX = (@canvasWidth / zoom / 2)
    marginY = (@canvasHeight / zoom / 2)
    x = Math.min(Math.max(marginX + @bounds.x, pos.x + @offset.x), @bounds.x + @bounds.width - marginX)
    y = Math.min(Math.max(marginY + @bounds.y, y + @offset.y), @bounds.y + @bounds.height - marginY)
    {x: x, y: y}

  updateViewports: (target) ->
    target ?= @target
    sv = width: @canvasWidth / @zoom, height: @canvasHeight / @zoom, cx: target.x, cy: target.y
    sv.x = sv.cx - sv.width / 2
    sv.y = sv.cy - sv.height / 2
    if @surfaceViewport
      # Calculate how different this viewport is. (If it's basically not different, we can avoid visualizing the update.)
      viewportDifference = Math.abs(@surfaceViewport.x - sv.x) + 1.01 * Math.abs(@surfaceViewport.y - sv.y) + 1.02 * Math.abs(@surfaceViewport.width - sv.width)
    else
      viewportDifference = 9001
    @surfaceViewport = sv

    wv = @surfaceToWorld sv  # get x and y
    wv.width = sv.width * Camera.MPP
    wv.height = sv.height * Camera.MPP * @x2y
    wv.cx = wv.x + wv.width / 2
    wv.cy = wv.y + wv.height / 2
    @worldViewport = wv

    viewportDifference

  lock: ->
    @target = @currentTarget
    @locked = true

  unlock: ->
    @locked = false

  destroy: ->
    createjs.Tween.removeTweens @
    super()

  onZoomTo: (e) ->
    @zoomTo @worldToSurface(e.pos), @zoom, e.duration
