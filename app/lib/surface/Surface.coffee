CocoClass = require 'lib/CocoClass'
path = require './path'
Dropper = require './Dropper'
AudioPlayer = require 'lib/AudioPlayer'
{me} = require 'lib/auth'
Camera = require './Camera'
CameraBorder = require './CameraBorder'
Layer = require './Layer'
Letterbox = require './Letterbox'
Dimmer = require './Dimmer'
CastingScreen = require './CastingScreen'
PlaybackOverScreen = require './PlaybackOverScreen'
DebugDisplay = require './DebugDisplay'
CoordinateDisplay = require './CoordinateDisplay'
SpriteBoss = require './SpriteBoss'
PointChooser = require './PointChooser'
RegionChooser = require './RegionChooser'
MusicPlayer = require './MusicPlayer'

module.exports = Surface = class Surface extends CocoClass
  stage: null

  layers: null
  surfaceLayer: null
  surfaceTextLayer: null
  screenLayer: null
  gridLayer: null  # TODO: maybe

  spriteBoss: null

  debugDisplay: null
  currentFrame: 0
  lastFrame: null
  totalFramesDrawn: 0
  playing: true  # play vs. pause
  dead: false  # if we kill it for some reason
  imagesLoaded: false
  worldLoaded: false
  scrubbing: false
  debug: false

  defaults:
    wizards: true
    paths: true
    grid: false
    navigateToSelection: true
    choosing: false # 'point', 'region', 'ratio-region'
    coords: true
    playJingle: false
    showInvisible: false
    frameRate: 30  # Best as a divisor of 60, like 15, 30, 60, with RAF_SYNCHED timing.

  subscriptions:
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'level-set-playing': 'onSetPlaying'
    'level-set-debug': 'onSetDebug'
    'level-toggle-debug': 'onToggleDebug'
    'level-set-grid': 'onSetGrid'
    'level-toggle-grid': 'onToggleGrid'
    'level-toggle-pathfinding': 'onTogglePathFinding'
    'level-set-time': 'onSetTime'
    'level-set-surface-camera': 'onSetCamera'
    'level:restarted': 'onLevelRestarted'
    'god:new-world-created': 'onNewWorld'
    'tome:cast-spells': 'onCastSpells'
    'level-set-letterbox': 'onSetLetterbox'
    'application:idle-changed': 'onIdleChanged'
    'camera:zoom-updated': 'onZoomUpdated'

  shortcuts:
    'ctrl+\\, ⌘+\\': 'onToggleDebug'
    'ctrl+g, ⌘+g': 'onToggleGrid'
    'ctrl+o, ⌘+o': 'onTogglePathFinding'

  # external functions

  constructor: (@world, @canvas, givenOptions) ->
    super()
    @layers = []
    @options = _.clone(@defaults)
    @options = _.extend(@options, givenOptions) if givenOptions
    @initEasel()
    @initAudio()
    @onResize = _.debounce @onResize, 500
    $(window).on 'resize', @onResize
    if @world.ended
      _.defer => @setWorld @world

  destroy: ->
    @dead = true
    @camera?.destroy()
    createjs.Ticker.removeEventListener('tick', @tick)
    createjs.Sound.stop()
    layer.destroy() for layer in @layers
    @spriteBoss.destroy()
    @chooser?.destroy()
    @dimmer?.destroy()
    @castingScreen?.destroy()
    @playbackOverScreen?.destroy()
    @stage.clear()
    @musicPlayer?.destroy()
    @stage.removeAllChildren()
    @stage.removeEventListener 'stagemousemove', @onMouseMove
    @stage.removeEventListener 'stagemousedown', @onMouseDown
    @stage.removeEventListener 'stagemouseup', @onMouseUp
    @stage.removeAllEventListeners()
    @stage.enableDOMEvents false
    @stage.enableMouseOver 0
    @canvas.off 'mousewheel', @onMouseWheel
    $(window).off 'resize', @onResize
    clearTimeout @surfacePauseTimeout if @surfacePauseTimeout
    clearTimeout @surfaceZoomPauseTimeout if @surfaceZoomPauseTimeout
    super()

  setWorld: (@world) ->
    @worldLoaded = true
    @world.getFrame(Math.min(@getCurrentFrame(), @world.totalFrames - 1)).restoreState() unless @options.choosing
    @spriteBoss.world = @world

    @showLevel()
    @updateState true if @loaded
    # TODO: synchronize both ways of choosing whether to show coords (@world via UI System or @options via World Select modal)
    if @world.showCoordinates and @options.coords
      @coordinateDisplay = new CoordinateDisplay camera: @camera
      @surfaceTextLayer.addChild @coordinateDisplay
    @onFrameChanged()
    Backbone.Mediator.publish 'surface:world-set-up'

  onTogglePathFinding: (e) ->
    e?.preventDefault?()
    @hidePathFinding()
    @showingPathFinding = not @showingPathFinding
    if @showingPathFinding then @showPathFinding() else @hidePathFinding()

  hidePathFinding: ->
    @surfaceLayer.removeChild @navRectangles if @navRectangles
    @surfaceLayer.removeChild @navPaths if @navPaths
    @navRectangles = @navPaths = null

  showPathFinding: ->
    @hidePathFinding()

    mesh = _.values(@world.navMeshes or {})[0]
    return unless mesh
    @navRectangles = new createjs.Container()
    @navRectangles.layerPriority = -1
    @addMeshRectanglesToContainer mesh, @navRectangles
    @surfaceLayer.addChild @navRectangles
    @surfaceLayer.updateLayerOrder()

    graph = _.values(@world.graphs or {})[0]
    return @surfaceLayer.updateLayerOrder() unless graph
    @navPaths = new createjs.Container()
    @navPaths.layerPriority = -1
    @addNavPathsToContainer graph, @navPaths
    @surfaceLayer.addChild @navPaths
    @surfaceLayer.updateLayerOrder()

  addMeshRectanglesToContainer: (mesh, container) ->
    for rect in mesh
      shape = new createjs.Shape()
      pos = @camera.worldToSurface {x: rect.x, y: rect.y}
      dim = @camera.worldToSurface {x: rect.width, y: rect.height}
      shape.graphics
        .setStrokeStyle(3)
        .beginFill('rgba(0,0,128,0.3)')
        .beginStroke('rgba(0,0,128,0.7)')
        .drawRect(pos.x - dim.x/2, pos.y - dim.y/2, dim.x, dim.y)
      container.addChild shape

  addNavPathsToContainer: (graph, container) ->
    for node in _.values graph
      for edgeVertex in node.edges
        @drawLine node.vertex, edgeVertex, container

  drawLine: (v1, v2, container) ->
    shape = new createjs.Shape()
    v1 = @camera.worldToSurface v1
    v2 = @camera.worldToSurface v2
    shape.graphics
      .setStrokeStyle(1)
      .moveTo(v1.x, v1.y)
      .beginStroke('rgba(128,0,0,0.4)')
      .lineTo(v2.x, v2.y)
      .endStroke()
    container.addChild shape

  setProgress: (progress, scrubDuration=500) ->
    progress = Math.max(Math.min(progress, 1), 0.0)

    @scrubbing = true
    onTweenEnd = =>
      @scrubbingTo = null
      @scrubbing = false
      @scrubbingPlaybackSpeed = null
      @fastForwarding = false

    if @scrubbingTo?
      # cut to the chase for existing tween
      createjs.Tween.removeTweens(@)
      @currentFrame = @scrubbingTo

    @scrubbingTo = Math.min(Math.round(progress * @world.totalFrames), @world.totalFrames)
    @scrubbingPlaybackSpeed = Math.sqrt(Math.abs(@scrubbingTo - @currentFrame) * @world.dt / (scrubDuration or 0.5))
    if scrubDuration
      t = createjs.Tween
        .get(@)
        .to({currentFrame: @scrubbingTo}, scrubDuration, createjs.Ease.sineInOut)
        .call(onTweenEnd)
      t.addEventListener('change', @onFramesScrubbed)
    else
      @currentFrame = @scrubbingTo
      @onFramesScrubbed()  # For performance, don't play these for instant transitions.
      onTweenEnd()

    return unless @loaded
    @updateState true
    @onFrameChanged()

  onFramesScrubbed: (e) =>
    return unless @loaded
    if e
      # Gotta play all the sounds when scrubbing (but not when doing an immediate transition).
      rising = @currentFrame > @lastFrame
      actualCurrentFrame = @currentFrame
      tempFrame = if rising then Math.ceil(@lastFrame) else Math.floor(@lastFrame)
      while true  # temporary fix to stop cacophony
        break if rising and tempFrame > actualCurrentFrame
        break if (not rising) and tempFrame < actualCurrentFrame
        @currentFrame = tempFrame
        frame = @world.getFrame(@getCurrentFrame())
        frame.restoreState()
        volume = Math.max(0.05, Math.min(1, 1 / @scrubbingPlaybackSpeed))
        sprite.playSounds false, volume for sprite in @spriteBoss.spriteArray
        tempFrame += if rising then 1 else -1
      @currentFrame = actualCurrentFrame

    @restoreWorldState()
    @spriteBoss.update true
    @onFrameChanged()

  getCurrentFrame: ->
    return Math.max(0, Math.min(Math.floor(@currentFrame), @world.totalFrames - 1))

  getProgress: -> @currentFrame / @world.totalFrames

  onLevelRestarted: (e) ->
    @setProgress 0, 0

  onSetCamera: (e) ->
    if e.thangID
      return unless target = @spriteBoss.spriteFor(e.thangID)?.imageObject
    else if e.pos
      target = @camera.worldToSurface e.pos
    else
      target = null
    @camera.setBounds e.bounds if e.bounds
    @cameraBorder.updateBounds @camera.bounds
    @camera.zoomTo target, e.zoom, e.duration  # TODO: SurfaceScriptModule perhaps shouldn't assign e.zoom if not set

  onZoomUpdated: (e) ->
    if @ended
      @setPaused false
      @surfaceZoomPauseTimeout = _.delay (=> @setPaused true), 3000

  setDisabled: (@disabled) ->
    @spriteBoss.disabled = @disabled

  onDisableControls: (e) ->
    return if e.controls and not ('surface' in e.controls)
    @setDisabled true
    @dimmer ?= new Dimmer camera: @camera, layer: @screenLayer
    @dimmer.setSprites @spriteBoss.sprites

  onEnableControls: (e) ->
    return if e.controls and not ('surface' in e.controls)
    @setDisabled false

  onSetLetterbox: (e) ->
    @setDisabled e.on

  onSetPlaying: (e) ->
    @playing = (e ? {}).playing ? true
    @setPlayingCalled = true
    if @playing and @currentFrame >= (@world.totalFrames - 5)
      @currentFrame = 0
    if @fastForwarding and not @playing
      @setProgress @currentFrame / @world.totalFrames

  onSetTime: (e) ->
    toFrame = @currentFrame
    if e.time?
      @worldLifespan = @world.totalFrames / @world.frameRate
      e.ratio = e.time / @worldLifespan
    if e.ratio?
      toFrame = @world.totalFrames * e.ratio
    if e.frameOffset
      toFrame += e.frameOffset
    if e.ratioOffset
      toFrame += @world.totalFrames * e.ratioOffset
    unless _.isNumber(toFrame) and not _.isNaN(toFrame)
      return console.error('set-time event', e, 'produced invalid target frame', toFrame)
    @setProgress(toFrame / @world.totalFrames, e.scrubDuration)

  onFrameChanged: (force) ->
    @currentFrame = Math.min(@currentFrame, @world.totalFrames)
    @debugDisplay?.updateFrame @currentFrame
    return if @currentFrame is @lastFrame and not force
    progress = @getProgress()
    Backbone.Mediator.publish('surface:frame-changed',
      type: 'frame-changed'
      selectedThang: @spriteBoss.selectedSprite?.thang
      progress: progress
      frame: @currentFrame
      world: @world
    )

    if @lastFrame < @world.totalFrames and @currentFrame >= @world.totalFrames - 1
      @ended = true
      @setPaused true
      Backbone.Mediator.publish 'surface:playback-ended'
    else if @currentFrame < @world.totalFrames and @ended
      @ended = false
      @setPaused false
      Backbone.Mediator.publish 'surface:playback-restarted'

    @lastFrame = @currentFrame

  onIdleChanged: (e) ->
    @setPaused e.idle unless @ended

  setPaused: (paused) ->
    # We want to be able to essentially stop rendering the surface if it doesn't need to animate anything.
    # If pausing, though, we want to give it enough time to finish any tweens.
    performToggle = =>
      createjs.Ticker.setFPS if paused then 1 else @options.frameRate
      @surfacePauseTimeout = null
    clearTimeout @surfacePauseTimeout if @surfacePauseTimeout
    clearTimeout @surfaceZoomPauseTimeout if @surfaceZoomPauseTimeout
    @surfacePauseTimeout = @surfaceZoomPauseTimeout = null
    if paused
      @surfacePauseTimeout = _.delay performToggle, 2000
      @spriteBoss.stop()
      @playbackOverScreen.show()
    else
      performToggle()
      @spriteBoss.play()
      @playbackOverScreen.hide()

  onCastSpells: (e) ->
    return if e.preload
    @setPaused false if @ended
    @casting = true
    @wasPlayingWhenCastingBegan = @playing
    Backbone.Mediator.publish 'level-set-playing', {playing: false}
    @setPlayingCalled = false # don't overwrite playing settings if they changed by, say, scripts

    if @coordinateDisplay?
      @surfaceTextLayer.removeChild @coordinateDisplay
      @coordinateDisplay.destroy()

    createjs.Tween.removeTweens(@surfaceLayer)
    createjs.Tween.get(@surfaceLayer).to({alpha: 0.9}, 1000, createjs.Ease.getPowOut(4.0))

  onNewWorld: (event) ->
    return unless event.world.name is @world.name
    @casting = false
    if @ended and not @wasPlayingWhenCastingBegan
      @setPaused true
    else
      @spriteBoss.play()

    # This has a tendency to break scripts that are waiting for playback to change when the level is loaded
    # so only run it after the first world is created.
    Backbone.Mediator.publish 'level-set-playing', {playing: @wasPlayingWhenCastingBegan} unless event.firstWorld or @setPlayingCalled

    fastForwardTo = null
    if @playing
      fastForwardTo = Math.min event.world.firstChangedFrame, @currentFrame
      @currentFrame = 0

    createjs.Tween.removeTweens(@surfaceLayer)
    f = =>
      @setWorld event.world
      @onFrameChanged(true)
      if fastForwardTo and @playing
        fastForwardToRatio = fastForwardTo / @world.totalFrames
        fastForwardToTime = fastForwardTo * @world.dt
        fastForwardSpeed = Math.max 4, fastForwardToTime / 3
        @setProgress fastForwardToRatio, 1000 * fastForwardToTime / fastForwardSpeed
        @fastForwarding = true
    createjs.Tween.get(@surfaceLayer)
      .to({alpha: 0.0}, 50)
      .call(f)
      .to({alpha: 1.0}, 2000, createjs.Ease.getPowOut(2.0))

  # initialization

  initEasel: ->
    # takes DOM objects, not jQuery objects
    @stage = new createjs.Stage(@canvas[0])
    canvasWidth = parseInt @canvas.attr('width'), 10
    canvasHeight = parseInt @canvas.attr('height'), 10
    @camera?.destroy()
    @camera = new Camera @canvas
    AudioPlayer.camera = @camera
    @layers.push @surfaceLayer = new Layer name: 'Surface', layerPriority: 0, transform: Layer.TRANSFORM_SURFACE, camera: @camera
    @layers.push @surfaceTextLayer = new Layer name: 'Surface Text', layerPriority: 1, transform: Layer.TRANSFORM_SURFACE_TEXT, camera: @camera
    @layers.push @screenLayer = new Layer name: 'Screen', layerPriority: 2, transform: Layer.TRANSFORM_SCREEN, camera: @camera
    @stage.addChild @layers...
    @surfaceLayer.addChild @cameraBorder = new CameraBorder bounds: @camera.bounds
    @screenLayer.addChild new Letterbox canvasWidth: canvasWidth, canvasHeight: canvasHeight
    @spriteBoss = new SpriteBoss camera: @camera, surfaceLayer: @surfaceLayer, surfaceTextLayer: @surfaceTextLayer, world: @world, thangTypes: @options.thangTypes, choosing: @options.choosing, navigateToSelection: @options.navigateToSelection, showInvisible: @options.showInvisible
    @castingScreen ?= new CastingScreen camera: @camera, layer: @screenLayer
    @playbackOverScreen ?= new PlaybackOverScreen camera: @camera, layer: @screenLayer
    @stage.enableMouseOver(10)
    @stage.addEventListener 'stagemousemove', @onMouseMove
    @stage.addEventListener 'stagemousedown', @onMouseDown
    @canvas[0].addEventListener 'mouseup', @onMouseUp
    @canvas.on 'mousewheel', @onMouseWheel
    @hookUpChooseControls() if @options.choosing
    createjs.Ticker.timingMode = createjs.Ticker.RAF_SYNCHED
    createjs.Ticker.setFPS @options.frameRate
    @onResize()

  onResize: (e) =>
    oldWidth = parseInt @canvas.attr('width'), 10
    oldHeight = parseInt @canvas.attr('height'), 10
    newWidth = @canvas.width()
    newHeight = @canvas.height()
    return unless newWidth > 0 and newHeight > 0
    #if InstallTrigger?  # Firefox rendering performance goes down as canvas size goes up
    #  newWidth = Math.min 924, newWidth
    #  newHeight = Math.min 589, newHeight
    @canvas.attr width: newWidth, height: newHeight
    @stage.scaleX *= newWidth / oldWidth
    @stage.scaleY *= newHeight / oldHeight
    @camera.onResize newWidth, newHeight

  showLevel: ->
    return if @dead
    return unless @worldLoaded
    return if @loaded
    @loaded = true
    @spriteBoss.createMarks()
    @spriteBoss.createIndieSprites @world.indieSprites, @options.wizards
    Backbone.Mediator.publish 'registrar-echo-states'
    @updateState true
    @drawCurrentFrame()
    @showGrid() if @options.grid  # TODO: pay attention to world grid setting (which we only know when world simulates)
    createjs.Ticker.addEventListener 'tick', @tick
    Backbone.Mediator.publish 'level:started'

  createOpponentWizard: (opponent) ->
    @spriteBoss.createOpponentWizard opponent

  initAudio: ->
    @musicPlayer = new MusicPlayer()

  # grid; should probably refactor into separate class

  showGrid: ->
    return if @gridShowing()
    unless @gridLayer
      @gridLayer = new createjs.Container()
      @gridShape = new createjs.Shape()
      @gridLayer.addChild @gridShape
      @gridLayer.z = 90019001
      @gridLayer.mouseEnabled = false
      @gridShape.alpha = 0.125
      @gridShape.graphics.beginStroke 'blue'
      gridSize = Math.round(@world.size()[0] / 20)
      unless gridSize > 0.1
        return console.error 'Grid size is', gridSize, 'so we can\'t draw a grid.'
      wopStart = x: 0, y: 0
      wopEnd = x: @world.size()[0], y: @world.size()[1]
      supStart = @camera.worldToSurface wopStart
      supEnd = @camera.worldToSurface wopEnd
      wop = x: wopStart.x, y: wopStart.y
      while wop.x < wopEnd.x
        sup = @camera.worldToSurface wop
        @gridShape.graphics.mt(sup.x, supStart.y).lt(sup.x, supEnd.y)
        t = new createjs.Text(wop.x.toFixed(0), '16px Arial', 'blue')
        t.x = sup.x - t.getMeasuredWidth() / 2
        t.y = supStart.y - 10 - t.getMeasuredHeight() / 2
        t.alpha = 0.75
        @gridLayer.addChild t
        wop.x += gridSize
      while wop.y < wopEnd.y
        sup = @camera.worldToSurface wop
        @gridShape.graphics.mt(supStart.x, sup.y).lt(supEnd.x, sup.y)
        t = new createjs.Text(wop.y.toFixed(0), '16px Arial', 'blue')
        t.x = 10 - t.getMeasuredWidth() / 2
        t.y = sup.y - t.getMeasuredHeight() / 2
        t.alpha = 0.75
        @gridLayer.addChild t
        wop.y += gridSize
      @gridShape.graphics.endStroke()
      bounds = @gridLayer.getBounds()
      return unless bounds?.width and bounds.height
      @gridLayer.cache bounds.x, bounds.y, bounds.width, bounds.height
    @surfaceLayer.addChild @gridLayer

  hideGrid: ->
    return unless @gridShowing()
    @gridLayer.parent.removeChild @gridLayer

  gridShowing: ->
    @gridLayer?.parent?

  onToggleGrid: (e) ->
    # TODO: figure out a better way of managing grid / debug so it's not split across PlaybackView and Surface
    e?.preventDefault?()
    if @gridShowing() then @hideGrid() else @showGrid()
    flag = $('#grid-toggle i.icon-ok')
    flag.toggleClass 'invisible', not @gridShowing()

  onSetGrid: (e) ->
    if e.grid then @showGrid() else @hideGrid()

  onToggleDebug: (e) ->
    e?.preventDefault?()
    Backbone.Mediator.publish 'level-set-debug', {debug: not @debug}

  onSetDebug: (e) ->
    return if e.debug is @debug
    @debug = e.debug
    if @debug and not @debugDisplay
      @screenLayer.addChild @debugDisplay = new DebugDisplay canvasWidth: @camera.canvasWidth, canvasHeight: @camera.canvasHeight

  # Some mouse handling callbacks

  onMouseMove: (e) =>
    @mouseScreenPos = {x: e.stageX, y: e.stageY}
    return if @disabled
    Backbone.Mediator.publish 'surface:mouse-moved', x: e.stageX, y: e.stageY

  onMouseDown: (e) =>
    return if @disabled
    onBackground = not @stage.hitTest e.stageX, e.stageY
    Backbone.Mediator.publish 'surface:stage-mouse-down', onBackground: onBackground, x: e.stageX, y: e.stageY, originalEvent: e

  onMouseUp: (e) =>
    return if @disabled
    onBackground = not @stage.hitTest e.stageX, e.stageY
    Backbone.Mediator.publish 'surface:stage-mouse-up', onBackground: onBackground, x: e.stageX, y: e.stageY, originalEvent: e

  onMouseWheel: (e) =>
    # https://github.com/brandonaaron/jquery-mousewheel
    e.preventDefault()
    return if @disabled
    event =
      deltaX: e.deltaX
      deltaY: e.deltaY
      screenPos: @mouseScreenPos
      canvas: @canvas
    Backbone.Mediator.publish 'surface:mouse-scrolled', event unless @disabled

  hookUpChooseControls: ->
    chooserOptions = stage: @stage, surfaceLayer: @surfaceLayer, camera: @camera, restrictRatio: @options.choosing is 'ratio-region'
    klass = if @options.choosing is 'point' then PointChooser else RegionChooser
    @chooser = new klass chooserOptions

  # Main Surface update loop

  tick: (e) =>
    # seems to be a bug where only one object can register with the Ticker...
    oldFrame = @currentFrame
    oldWorldFrame = Math.floor oldFrame
    lastFrame = @world.totalFrames - 1
    while true
      Dropper.tick()
      @trailmaster.tick() if @trailmaster
      # Skip some frame updates unless we're playing and not at end (or we haven't drawn much yet)
      frameAdvanced = (@playing and @currentFrame < lastFrame) or @totalFramesDrawn < 2
      if frameAdvanced and @playing
        @currentFrame += @world.frameRate / @options.frameRate
        @currentFrame = Math.min @currentFrame, lastFrame
      newWorldFrame = Math.floor @currentFrame
      worldFrameAdvanced = newWorldFrame isnt oldWorldFrame
      if worldFrameAdvanced
        # Only restore world state when it will correspond to an integer WorldFrame, not interpolated frame.
        @restoreWorldState()
        oldWorldFrame = newWorldFrame
      break unless Dropper.drop()
    if frameAdvanced and not worldFrameAdvanced
      # We didn't end the above loop on an integer frame, so do the world state update.
      @restoreWorldState()

    # these are skipped for dropped frames
    @updateState @currentFrame isnt oldFrame
    @drawCurrentFrame e
    @onFrameChanged()
    @updatePaths() if (@totalFramesDrawn % 4) is 0 or createjs.Ticker.getMeasuredFPS() > createjs.Ticker.getFPS() - 5
    Backbone.Mediator.publish('surface:ticked', {dt: 1 / @options.frameRate})
    mib = @stage.mouseInBounds
    if @mouseInBounds isnt mib
      Backbone.Mediator.publish('surface:mouse-' + (if mib then 'over' else 'out'), {})
      @mouseInBounds = mib

  restoreWorldState: ->
    frame = @world.getFrame(@getCurrentFrame())
    frame.restoreState()
    current = Math.max(0, Math.min(@currentFrame, @world.totalFrames - 1))
    if current - Math.floor(current) > 0.01
      next = Math.ceil current
      ratio = current % 1
      @world.frames[next].restorePartialState ratio if next > 1
    frame.clearEvents() if parseInt(@currentFrame) is parseInt(@lastFrame)
    @spriteBoss.updateSounds()

  updateState: (frameChanged) ->
    # world state must have been restored in @restoreWorldState
    @camera.updateZoom()
    @spriteBoss.update frameChanged unless @casting
    @dimmer?.setSprites @spriteBoss.sprites

  drawCurrentFrame: (e) ->
    ++@totalFramesDrawn
    @stage.update e

  # paths - TODO: move to SpriteBoss? but only update on frame drawing instead of on every frame update?

  updatePaths: ->
    return unless @options.paths
    return if @casting
    @hidePaths()
    selectedThang = @spriteBoss.selectedSprite?.thang
    return if @world.showPaths is 'never'
    return if @world.showPaths is 'paused' and @playing
    return if @world.showPaths is 'selected' and not selectedThang
    @trailmaster ?= new path.Trailmaster @camera
    selectedOnly = @playing and @world.showPaths is 'selected'
    @paths = @trailmaster.generatePaths @world, @getCurrentFrame(), selectedThang, @spriteBoss.sprites, selectedOnly
    @paths.name = 'paths'
    @spriteBoss.spriteLayers['Path'].addChild @paths

  hidePaths: ->
    return if not @paths
    @paths.parent.removeChild @paths
    @paths = null

  screenshot: (scale=0.25, format='image/jpeg', quality=0.8, zoom=2) ->
    # Quality doesn't work with image/png, just image/jpeg and image/webp
    [w, h] = [@camera.canvasWidth, @camera.canvasHeight]
    margin = (1 - 1 / zoom) / 2
    @stage.cache margin * w, margin * h, w / zoom, h / zoom, scale * zoom
    imageData = @stage.cacheCanvas.toDataURL(format, quality)
    #console.log 'Screenshot with scale', scale, 'format', format, 'quality', quality, 'was', Math.floor(imageData.length / 1024), 'kB'
    screenshot = document.createElement('img')
    screenshot.src = imageData
    @stage.uncache()
    imageData
