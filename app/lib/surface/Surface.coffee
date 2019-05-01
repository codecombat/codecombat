CocoClass = require 'core/CocoClass'
TrailMaster = require './TrailMaster'
Dropper = require './Dropper'
AudioPlayer = require 'lib/AudioPlayer'
{me} = require 'core/auth'
Camera = require './Camera'
CameraBorder = require './CameraBorder'
Layer = require('./LayerAdapter')
Letterbox = require './Letterbox'
Dimmer = require './Dimmer'
CountdownScreen = require './CountdownScreen'
PlaybackOverScreen = require './PlaybackOverScreen'
DebugDisplay = require './DebugDisplay'
CoordinateDisplay = require './CoordinateDisplay'
CoordinateGrid = require './CoordinateGrid'
LankBoss = require './LankBoss'
PointChooser = require './PointChooser'
RegionChooser = require './RegionChooser'
MusicPlayer = require './MusicPlayer'
GameUIState = require 'models/GameUIState'
createjs = require 'lib/createjs-parts'
require 'jquery-mousewheel'

resizeDelay = 1  # At least as much as $level-resize-transition-time.

module.exports = Surface = class Surface extends CocoClass
  stage: null

  normalLayers: null
  surfaceLayer: null
  surfaceTextLayer: null
  screenLayer: null
  gridLayer: null

  lankBoss: null

  debugDisplay: null
  currentFrame: 0
  lastFrame: null
  totalFramesDrawn: 0
  playing: false  # play vs. pause -- match default button state in playback.jade
  dead: false  # if we kill it for some reason
  imagesLoaded: false
  worldLoaded: false
  scrubbing: false
  debug: false

  defaults:
    paths: true
    grid: false
    navigateToSelection: true
    choosing: false # 'point', 'region', 'ratio-region'
    coords: null  # use world defaults, or set to false/true to override
    showInvisible: false
    frameRate: 30  # Best as a divisor of 60, like 15, 30, 60, with RAF_SYNCHED timing.
    levelType: 'hero'

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'level:set-playing': 'onSetPlaying'
    'level:set-debug': 'onSetDebug'
    'level:toggle-debug': 'onToggleDebug'
    'level:toggle-pathfinding': 'onTogglePathFinding'
    'level:set-time': 'onSetTime'
    'camera:set-camera': 'onSetCamera'
    'level:restarted': 'onLevelRestarted'
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'tome:cast-spells': 'onCastSpells'
    'level:set-letterbox': 'onSetLetterbox'
    'application:idle-changed': 'onIdleChanged'
    'camera:zoom-updated': 'onZoomUpdated'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'playback:cinematic-playback-started': 'onCinematicPlaybackStarted'
    'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded'
    'level:flag-color-selected': 'onFlagColorSelected'
    'tome:manual-cast': 'onManualCast'
    'playback:stop-real-time-playback': 'onStopRealTimePlayback'

  shortcuts:
    'ctrl+\\, ⌘+\\': 'onToggleDebug'
    'ctrl+o, ⌘+o': 'onTogglePathFinding'



  #- Initialization

  constructor: (@world, @normalCanvas, @webGLCanvas, givenOptions) ->
    super()
    $(window).on('keydown', @onKeyEvent)
    $(window).on('keyup', @onKeyEvent)
    @normalLayers = []
    @options = _.clone(@defaults)
    @options = _.extend(@options, givenOptions) if givenOptions
    @handleEvents = @options.handleEvents ? true
    @zoomToHero = @options.levelType isnt "game-dev" # In game-dev levels the hero is gameReferee
    @gameUIState = @options.gameUIState or new GameUIState({
      canDragCamera: true
    })
    @realTimeInputEvents = @gameUIState.get('realTimeInputEvents')
    @listenTo(@gameUIState, 'sprite:mouse-down', @onSpriteMouseDown)
    if @world.trackMouseMove # This is defined as a parameter of Systems.UI and setup there for a level
      @listenTo(@gameUIState, 'surface:stage-mouse-move', @onWorldMouseMove)
    @onResize = _.debounce @onResize, resizeDelay
    @initEasel()
    @initAudio()
    $(window).on 'resize', @onResize
    if @world.ended
      _.defer => @setWorld @world

  initEasel: ->
    @normalStage = new createjs.Stage(@normalCanvas[0])
    @webGLStage = new createjs.StageGL(@webGLCanvas[0])
    @normalStage.nextStage = @webGLStage
    @camera = new Camera(@webGLCanvas, { @gameUIState, @handleEvents })
    @camera.dragDisabled = @world.cameraDragDisabled # This is defined as a parameter of Systems.UI and setup there for a level
    AudioPlayer.camera = @camera unless @options.choosing

    @normalLayers.push @surfaceTextLayer = new Layer name: 'Surface Text', layerPriority: 1, transform: Layer.TRANSFORM_SURFACE_TEXT, camera: @camera
    @normalLayers.push @gridLayer = new Layer name: 'Grid', layerPriority: 2, transform: Layer.TRANSFORM_SURFACE, camera: @camera
    @normalLayers.push @screenLayer = new Layer name: 'Screen', layerPriority: 3, transform: Layer.TRANSFORM_SCREEN, camera: @camera
#    @normalLayers.push @cameraBorderLayer = new Layer name: 'Camera Border', layerPriority: 4, transform: Layer.TRANSFORM_SURFACE, camera: @camera
#    @cameraBorderLayer.addChild @cameraBorder = new CameraBorder(bounds: @camera.bounds)
    @normalStage.addChild (layer.container for layer in @normalLayers)...

    canvasWidth = parseInt @normalCanvas.attr('width'), 10
    canvasHeight = parseInt @normalCanvas.attr('height'), 10
    @screenLayer.addChild new Letterbox canvasWidth: canvasWidth, canvasHeight: canvasHeight

    @lankBoss = new LankBoss({
      @camera
      @webGLStage
      @surfaceTextLayer
      @world
      thangTypes: @options.thangTypes
      choosing: @options.choosing
      navigateToSelection: @options.navigateToSelection
      showInvisible: @options.showInvisible
      playerNames: if @options.levelType is 'course-ladder' then @options.playerNames else null
      @gameUIState
      @handleEvents
    })
    @countdownScreen = new CountdownScreen camera: @camera, layer: @screenLayer, showsCountdown: @world.showsCountdown
    unless @options.levelType is 'game-dev'
      @playbackOverScreen = new PlaybackOverScreen camera: @camera, layer: @screenLayer, playerNames: @options.playerNames
      @normalStage.addChildAt @playbackOverScreen.dimLayer, 0  # Put this below the other layers, actually, so we can more easily read text on the screen.
    @initCoordinates()
    @webGLStage.enableMouseOver(10)
    @webGLStage.addEventListener 'stagemousemove', @onMouseMove
    @webGLStage.addEventListener 'stagemousedown', @onMouseDown
    @webGLStage.addEventListener 'stagemouseup', @onMouseUp
    @webGLCanvas.on 'mousewheel', @onMouseWheel
    @hookUpChooseControls() if @options.choosing # TODO: figure this stuff out
    createjs.Ticker.timingMode = createjs.Ticker.RAF_SYNCHED
    createjs.Ticker.framerate = @options.frameRate
    @onResize()

  initCoordinates: ->
    @coordinateGrid ?= new CoordinateGrid {camera: @camera, layer: @gridLayer, textLayer: @surfaceTextLayer}, @world.size()
    @coordinateGrid.showGrid() if @world.showGrid or @options.grid
    @showCoordinates = if @options.coords? then @options.coords else @world.showCoordinates
    @coordinateDisplay ?= new CoordinateDisplay camera: @camera, layer: @surfaceTextLayer if @showCoordinates

  hookUpChooseControls: ->
    chooserOptions = stage: @webGLStage, surfaceLayer: @surfaceTextLayer, camera: @camera, restrictRatio: @options.choosing is 'ratio-region'
    klass = if @options.choosing is 'point' then PointChooser else RegionChooser
    @chooser = new klass chooserOptions

  initAudio: ->
    @musicPlayer = new MusicPlayer()



  #- Setting the world

  setWorld: (@world) ->
    @worldLoaded = true
    @lankBoss.world = @world
    @restoreWorldState() unless @options.choosing
    @showLevel()
    @updateState true if @loaded
    @onFrameChanged()

  showLevel: ->
    return if @destroyed
    return if @loaded
    @loaded = true
    @lankBoss.createMarks()
    @updateState true
    @drawCurrentFrame()
    createjs.Ticker.addEventListener 'tick', @tick
    Backbone.Mediator.publish 'level:started', {}

  #- Update loop

  tick: (e) =>
    # seems to be a bug where only one object can register with the Ticker...
    oldFrame = @currentFrame
    oldWorldFrame = Math.floor oldFrame
    lastFrame = @world.frames.length - 1
    framesDropped = 0
    while true
      Dropper.tick()
      # Skip some frame updates unless we're playing and not at end (or we haven't drawn much yet)
      frameAdvanced = (@playing and @currentFrame < lastFrame) or @totalFramesDrawn < 2
      if frameAdvanced and @playing
        advanceBy = @world.frameRate / @options.frameRate
        if @fastForwardingToFrame and @currentFrame < @fastForwardingToFrame - advanceBy
          advanceBy = Math.min(@currentFrame + advanceBy * @fastForwardingSpeed, @fastForwardingToFrame) - @currentFrame
        else if @fastForwardingToFrame
          @fastForwardingToFrame = @fastForwardingSpeed = null
        @currentFrame += advanceBy
        @currentFrame = Math.min @currentFrame, lastFrame
      newWorldFrame = Math.floor @currentFrame
      if Dropper.drop()
        ++framesDropped
      else
        worldFrameAdvanced = newWorldFrame isnt oldWorldFrame
        if worldFrameAdvanced
          # Only restore world state when it will correspond to an integer WorldFrame, not interpolated frame.
          @restoreWorldState()
          oldWorldFrame = newWorldFrame
        break
    if frameAdvanced and not worldFrameAdvanced
      # We didn't end the above loop on an integer frame, so do the world state update.
      @restoreWorldState()

    # these are skipped for dropped frames
    @updateState @currentFrame isnt oldFrame
    @drawCurrentFrame e
    @onFrameChanged()
    Backbone.Mediator.publish('surface:ticked', {dt: 1 / @options.frameRate})
    mib = @webGLStage.mouseInBounds
    if @mouseInBounds isnt mib
      Backbone.Mediator.publish('surface:mouse-' + (if mib then 'over' else 'out'), {})
      @mouseInBounds = mib
      @mouseIsDown = false

  restoreWorldState: ->
    if @world.synchronous
      @lankBoss.updateSounds() if parseInt(@currentFrame) isnt parseInt(@lastFrame)
      return
    frame = @world.getFrame(@getCurrentFrame())
    return unless frame
    frame.restoreState()
    @restoreScores frame

    current = Math.max(0, Math.min(@currentFrame, @world.frames.length - 1))
    if current - Math.floor(current) > 0.01 and Math.ceil(current) < @world.frames.length - 1
      next = Math.ceil current
      ratio = current % 1
      @world.frames[next].restorePartialState ratio if next > 1
    frame.clearEvents() if parseInt(@currentFrame) is parseInt(@lastFrame)
    @lankBoss.updateSounds() if parseInt(@currentFrame) isnt parseInt(@lastFrame)

  updateState: (frameChanged) ->
    # world state must have been restored in @restoreWorldState
    if @handleEvents
      if @zoomToHero and @playing and @currentFrame < @world.frames.length - 1 and @heroLank and not @mouseIsDown and @camera.newTarget isnt @heroLank.sprite and @camera.target isnt @heroLank.sprite
        @camera.zoomTo @heroLank.sprite, @camera.zoom, 750
    @lankBoss.update frameChanged
    @camera.updateZoom()  # Make sure to do this right after the LankBoss updates, not before, so it can properly target sprite positions.
    @dimmer?.setSprites @lankBoss.lanks

  drawCurrentFrame: (e) ->
    ++@totalFramesDrawn
    @normalStage.update e
    @webGLStage.update e

  restoreScores: (frame) ->
    return unless frame.scores and @options.level
    scores = []
    for scoreType in @options.level.get('scoreTypes') ? []
      scoreType = scoreType.type if scoreType.type
      if scoreType is 'code-length'
        score = @world.scores?['code-length']
      else
        score = frame.scores[scoreType]
      if score?
        scores.push type: scoreType, score: score
    Backbone.Mediator.publish 'level:scores-updated', scores: scores

  #- Setting play/pause and progress

  setProgress: (progress, scrubDuration=500) ->
    progress = Math.max(Math.min(progress, 1), 0.0)

    @fastForwardingToFrame = null
    @scrubbing = true
    onTweenEnd = =>
      @scrubbingTo = null
      @scrubbing = false
      @scrubbingPlaybackSpeed = null

    if @scrubbingTo?
      # cut to the chase for existing tween
      createjs.Tween.removeTweens(@)
      @currentFrame = @scrubbingTo

    @scrubbingTo = Math.round(progress * (@world.frames.length - 1))
    @scrubbingTo = Math.max @scrubbingTo, 1
    @scrubbingTo = Math.min @scrubbingTo, @world.frames.length - 1
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
        lank.playSounds false, volume for lank in @lankBoss.lankArray
        tempFrame += if rising then 1 else -1
      @currentFrame = actualCurrentFrame

    @restoreWorldState()
    @lankBoss.update true
    @onFrameChanged()

  getCurrentFrame: ->
    return Math.max(0, Math.min(Math.floor(@currentFrame), @world.frames.length - 1))

  setPaused: (paused) ->
    # We want to be able to essentially stop rendering the surface if it doesn't need to animate anything.
    # If pausing, though, we want to give it enough time to finish any tweens.
    performToggle = =>
      createjs.Ticker.framerate = if paused then 1 else @options.frameRate
      @surfacePauseTimeout = null
    clearTimeout @surfacePauseTimeout if @surfacePauseTimeout
    clearTimeout @surfaceZoomPauseTimeout if @surfaceZoomPauseTimeout
    @surfacePauseTimeout = @surfaceZoomPauseTimeout = null
    if paused
      @surfacePauseTimeout = _.delay performToggle, 2000
      @lankBoss.stop()
      @trailmaster?.stop()
      @playbackOverScreen?.show()
    else
      performToggle()
      @lankBoss.play()
      @trailmaster?.play()
      @playbackOverScreen?.hide()



  #- Changes and events that only need to happen when the frame has changed

  onFrameChanged: (force) ->
    @currentFrame = Math.min(@currentFrame, @world.frames.length - 1)
    @debugDisplay?.updateFrame @currentFrame
    return if @currentFrame is @lastFrame and not force
    progress = @getProgress()
    Backbone.Mediator.publish('surface:frame-changed',
      selectedThang: @lankBoss.selectedLank?.thang
      progress: progress
      frame: @currentFrame
      world: @world
    )

    if (not @world.indefiniteLength) and @lastFrame < @world.frames.length and @currentFrame >= @world.totalFrames - 1
      @ended = true
      @setPaused true
      Backbone.Mediator.publish 'surface:playback-ended', {}
      @updatePaths()  # TODO: this is a hack to make sure paths are on the first time the level loads
    else if @currentFrame < @world.totalFrames and @ended
      @ended = false
      @setPaused false
      Backbone.Mediator.publish 'surface:playback-restarted', {}

    @lastFrame = @currentFrame

  getProgress: -> @currentFrame / Math.max(1, @world.frames.length - 1)



  #- Subscription callbacks

  onToggleDebug: (e) ->
    e?.preventDefault?()
    Backbone.Mediator.publish 'level:set-debug', {debug: not @debug}

  onSetDebug: (e) ->
    return if e.debug is @debug
    @debug = e.debug
    if @debug and not @debugDisplay
      @screenLayer.addChild @debugDisplay = new DebugDisplay canvasWidth: @camera.canvasWidth, canvasHeight: @camera.canvasHeight

  onLevelRestarted: (e) ->
    @setProgress 0, 0

  onSetCamera: (e) ->
    if e.thangID
      return unless target = @lankBoss.lankFor(e.thangID)?.sprite
    else if e.pos
      target = @camera.worldToSurface e.pos
    else
      target = null
    @camera.setBounds e.bounds if e.bounds
#    @cameraBorder.updateBounds @camera.bounds
    if @handleEvents
      @camera.zoomTo target, e.zoom, e.duration  # TODO: SurfaceScriptModule perhaps shouldn't assign e.zoom if not set

  onZoomUpdated: (e) ->
    if @ended
      @setPaused false
      @surfaceZoomPauseTimeout = _.delay (=> @setPaused true), 3000
    @zoomedIn = e.zoom > e.minZoom * 1.1
    @updateGrabbability()

  updateGrabbability: ->
    @webGLCanvas.toggleClass 'grabbable', @zoomedIn and not @playing and not @disabled

  onDisableControls: (e) ->
    return if e.controls and not ('surface' in e.controls)
    @setDisabled true
    @dimmer ?= new Dimmer camera: @camera, layer: @screenLayer
    @dimmer.setSprites @lankBoss.lanks

  onEnableControls: (e) ->
    return if e.controls and not ('surface' in e.controls)
    @setDisabled false

  onSetLetterbox: (e) ->
    @setDisabled e.on

  setDisabled: (@disabled) ->
    @lankBoss.disabled = @disabled
    @updateGrabbability()

  onSetPlaying: (e) ->
    @playing = (e ? {}).playing ? true
    @setPlayingCalled = true
    if @playing and @currentFrame >= (@world.totalFrames - 5)
      @currentFrame = 1  # Go back to the beginning (but not frame 0, that frame is weird)
    if @fastForwardingToFrame and not @playing
      @fastForwardingToFrame = null
    @updateGrabbability()

  onSetTime: (e) ->
    toFrame = @currentFrame
    if e.time?
      @worldLifespan = @world.frames.length / @world.frameRate
      e.ratio = e.time / @worldLifespan
    if e.ratio?
      toFrame = @world.frames.length * e.ratio
    if e.frameOffset
      toFrame += e.frameOffset
    if e.ratioOffset
      toFrame += @world.frames.length * e.ratioOffset
    unless _.isNumber(toFrame) and not _.isNaN(toFrame)
      return console.error('set-time event', e, 'produced invalid target frame', toFrame)
    @setProgress(toFrame / @world.frames.length, e.scrubDuration)

  onCastSpells: (e) ->
    return if e.preload
    @setPaused false if @ended
    @casting = true
    @setPlayingCalled = false  # Don't overwrite playing settings if they changed by, say, scripts.
    @frameBeforeCast = @currentFrame
    # This is where I wanted to trigger a rewind, but it turned out to be pretty complicated, since the new world gets updated everywhere, and you don't want to rewind through that.
    @setProgress 0, 0

  onNewWorld: (event) ->
    return unless event.world.name is @world.name
    @onStreamingWorldUpdated event

  onStreamingWorldUpdated: (event) ->
    @casting = false
    @lankBoss.play()

    # This has a tendency to break scripts that are waiting for playback to change when the level is loaded
    # so only run it after the first world is created.
    Backbone.Mediator.publish 'level:set-playing', {playing: true} unless event.firstWorld or @setPlayingCalled

    @setWorld event.world
    @onFrameChanged(true)
    fastForwardBuffer = 2
    if @playing and not @realTime and (ffToFrame = Math.min(event.firstChangedFrame, @frameBeforeCast, @world.frames.length - 1)) and ffToFrame > @currentFrame + fastForwardBuffer * @world.frameRate
      @fastForwardingToFrame = ffToFrame
      if @cinematic
        @fastForwardingSpeed = Math.max 1, Math.min(2, (ffToFrame * @world.dt) / 15)
      else
        @fastForwardingSpeed = Math.max 3, 3 * (@world.maxTotalFrames * @world.dt) / 60
    else if @realTime
      buffer = if @world.indefiniteLength then 0 else @world.realTimeBufferMax
      lag = (@world.frames.length - 1) * @world.dt - @world.age
      intendedLag = @world.dt + buffer
      if lag > intendedLag * 1.2
        @fastForwardingToFrame = @world.frames.length - buffer * @world.frameRate
        @fastForwardingSpeed = lag / intendedLag
      else
        @fastForwardingToFrame = @fastForwardingSpeed = null
    #console.log "on new world, lag", lag, "intended lag", intendedLag, "fastForwardingToFrame", @fastForwardingToFrame, "speed", @fastForwardingSpeed, "cause we are at", @world.age, "of", @world.frames.length * @world.dt
    if event.finished
      @updatePaths()
    else
      @hidePaths()

  onIdleChanged: (e) ->
    @setPaused e.idle unless @ended



  #- Mouse event callbacks

  onMouseMove: (e) =>
    @mouseScreenPos = {x: e.stageX, y: e.stageY}
    createjs.lastMouseWorldPos = @camera.screenToWorld x: e.stageX, y: e.stageY
    return if @disabled
    Backbone.Mediator.publish 'surface:mouse-moved', x: e.stageX, y: e.stageY
    @gameUIState.trigger('surface:stage-mouse-move', { originalEvent: e })

  onMouseDown: (e) =>
    return if @disabled
    cap = @camera.screenToCanvas({x: e.stageX, y: e.stageY})
    wop = @camera.screenToWorld x: e.stageX, y: e.stageY
    createjs.lastMouseWorldPos = wop
    # getObject(s)UnderPoint is broken, so we have to use the private method to get what we want
    onBackground = not @webGLStage._getObjectsUnderPoint(e.stageX, e.stageY, null, true)

    event = { onBackground: onBackground, x: e.stageX, y: e.stageY, originalEvent: e, worldPos: wop }
    Backbone.Mediator.publish 'surface:stage-mouse-down', event
    Backbone.Mediator.publish 'tome:focus-editor', {}
    @gameUIState.trigger('surface:stage-mouse-down', event)
    @mouseIsDown = true

  onSpriteMouseDown: (e) =>
    return unless @realTime
    @realTimeInputEvents.add({
      type: 'mousedown'
      pos: @camera.screenToWorld x: e.originalEvent.stageX, y: e.originalEvent.stageY
      time: @world.dt * @world.frames.length
      thangID: e.sprite.thang.id
    })

  onWorldMouseMove: (e) =>
    return unless @realTime
    @realTimeInputEvents.add({
      type: 'mousemove'
      pos: @camera.screenToWorld x: e.originalEvent.stageX, y: e.originalEvent.stageY
      time: @world.dt * @world.frames.length
    })

  onMouseUp: (e) =>
    return if @disabled
    createjs.lastMouseWorldPos = @camera.screenToWorld x: e.stageX, y: e.stageY
    onBackground = not @webGLStage.hitTest e.stageX, e.stageY
    event = { onBackground: onBackground, x: e.stageX, y: e.stageY, originalEvent: e }
    Backbone.Mediator.publish 'surface:stage-mouse-up', event
    Backbone.Mediator.publish 'tome:focus-editor', {}
    @gameUIState.trigger('surface:stage-mouse-up', event)
    @mouseIsDown = false

  onMouseWheel: (e) =>
    # https://github.com/brandonaaron/jquery-mousewheel
    e.preventDefault()
    return if @disabled
    event =
      deltaX: e.deltaX
      deltaY: e.deltaY
      canvas: @webGLCanvas
    event.screenPos = @mouseScreenPos if @mouseScreenPos
    Backbone.Mediator.publish 'surface:mouse-scrolled', event unless @disabled
    @gameUIState.trigger('surface:mouse-scrolled', event)


  #- Keyboard callbacks

  onKeyEvent: (e) =>
    return unless @realTime
    event = _.pick(e, 'type', 'keyCode', 'ctrlKey', 'metaKey', 'shiftKey')
    event.time = @world.dt * @world.frames.length
    @realTimeInputEvents.add(event)

  #- Canvas callbacks

  onResize: (e) =>
    return if @destroyed or @options.choosing
    oldWidth = parseInt @normalCanvas.attr('width'), 10
    oldHeight = parseInt @normalCanvas.attr('height'), 10
    aspectRatio = oldWidth / oldHeight
    pageWidth = $('#page-container').width() - 17  # 17px nano scroll bar
    if application.isIPadApp
      newWidth = 1024
      newHeight = newWidth / aspectRatio
    else if @options.resizeStrategy is 'wrapper-size'
      canvasWrapperWidth = $('#canvas-wrapper').width()
      pageHeight = window.innerHeight - $('#control-bar-view').outerHeight() - $('#playback-view').outerHeight()
      newWidth = Math.min(pageWidth, pageHeight * aspectRatio, canvasWrapperWidth)
      newHeight = newWidth / aspectRatio
    else if @realTime or @cinematic or @options.spectateGame
      pageHeight = window.innerHeight - $('#playback-view').outerHeight()
      if @realTime or @options.spectateGame
        pageHeight -= $('#control-bar-view').outerHeight()
      newWidth = Math.min pageWidth, pageHeight * aspectRatio
      newHeight = newWidth / aspectRatio
    else if $('#thangs-tab-view')
      newWidth = $('#canvas-wrapper').width()
      newHeight = newWidth / aspectRatio
    else
      newWidth = 0.55 * pageWidth
      newHeight = newWidth / aspectRatio
    return unless newWidth > 0 and newHeight > 0

    #scaleFactor = if application.isIPadApp then 2 else 1  # Retina
    scaleFactor = 1
    if @options.stayVisible or features.codePlay
      availableHeight = window.innerHeight
      availableHeight -= ($('.ad-container').outerHeight() or 0)
      availableHeight -= ($('#game-area').outerHeight() or 0) - ($('#canvas-wrapper').outerHeight() or 0)
      if features.codePlay
        bannerHeight = ($('#codeplay-product-banner').height() or 0)
        availableHeight -= bannerHeight
        scaleFactor = availableHeight / newHeight if availableHeight < newHeight
      scaleFactor = availableHeight / newHeight if availableHeight < newHeight

    newWidth *= scaleFactor
    newHeight *= scaleFactor

    return @updateCodePlayMargin() if newWidth is oldWidth and newHeight is oldHeight and not @options.spectateGame
    return @updateCodePlayMargin() if newWidth < 200 or newHeight < 200
    @normalCanvas.add(@webGLCanvas).attr width: newWidth, height: newHeight
    @updateCodePlayMargin()
    @trigger 'resize', { width: newWidth, height: newHeight }

    # Cannot do this to the webGLStage because it does not use scaleX/Y.
    # Instead the LayerAdapter scales webGL-enabled layers.
    @webGLStage.updateViewport(@webGLCanvas[0].width, @webGLCanvas[0].height)
    @normalStage.scaleX *= newWidth / oldWidth
    @normalStage.scaleY *= newHeight / oldHeight
    @camera.onResize newWidth, newHeight
    if @options.spectateGame
      # Since normalCanvas is absolutely positioned, it needs help aligning with webGLCanvas.
      offset = @webGLCanvas.offset().left - ($('#page-container').innerWidth() - $('#canvas-wrapper').innerWidth()) / 2
      @normalCanvas.css 'left', offset

  updateCodePlayMargin: ->
    return unless features.codePlay
    availableWidth = (window.innerWidth * .57 - 200)
    width = @normalCanvas.attr('width')
    margin = Math.max(availableWidth - width, 0)
    @normalCanvas.add(@webGLCanvas).css('margin-left', margin/2)

  #- Camera focus on hero
  focusOnHero: ->
    hadHero = @heroLank
    @heroLank = @lankBoss.lankFor 'Hero Placeholder'
    if me.team is 'ogres'
      # TODO: do this for real
      @heroLank = @lankBoss.lankFor 'Hero Placeholder 1'
    @updatePaths() if not hadHero

  #- Real-time playback

  onRealTimePlaybackStarted: (e) ->
    return if @realTime
    @realTimeInputEvents.reset()
    @realTime = true
    @onResize()
    @playing = false  # Will start when countdown is done.
    if @heroLank
      @previousCameraZoom = @camera.zoom
      #@camera.zoomTo @heroLank.sprite, 2, 3000  # This makes flag placement hard, now that we're only rarely using this as a coolcam.

  onRealTimePlaybackEnded: (e) ->
    return unless @realTime
    @realTime = false
    @onResize()
    _.delay @onResize, resizeDelay + 100  # Do it again just to be double sure that we don't stay zoomed in due to timing problems.
    @normalCanvas.add(@webGLCanvas).removeClass 'flag-color-selected'
    if @handleEvents
      if @previousCameraZoom
        @camera.zoomTo @camera.newTarget or @camera.target, @previousCameraZoom, 3000

  #- Cinematic playback
  onCinematicPlaybackStarted: (e) ->
    return if @cinematic
    @cinematic = true
    @onResize()

  onCinematicPlaybackEnded: (e) ->
    return unless @cinematic
    @cinematic = false
    @onResize()
    _.delay @onResize, resizeDelay + 100  # Do it again just to be double sure that we don't stay zoomed in due to timing problems.

  onFlagColorSelected: (e) ->
    @normalCanvas.add(@webGLCanvas).toggleClass 'flag-color-selected', Boolean(e.color)
    e.pos = @camera.screenToWorld @mouseScreenPos if @mouseScreenPos

  # Force sizing based on width for game-dev levels, so that the instructions panel doesn't obscure the game
  onManualCast: ->
    if @options.levelType is 'game-dev'
      console.log "Force resize strategy"
      @options.originalResizeStrategy = @options.resizeStrategy
      @options.resizeStrategy = 'wrapper-size'

  # Revert back to normal sizing when done playing a game-dev level
  onStopRealTimePlayback: ->
    if @options.levelType is 'game-dev'
      console.log "Reset resize strategy"
      @options.resizeStrategy = @options.originalResizeStrategy

  updatePaths: ->
    return unless @options.paths and @heroLank
    @hidePaths()
    return if @world.showPaths is 'never'
    layerAdapter = @lankBoss.layerAdapters['Path']
    @trailmaster ?= new TrailMaster @camera, layerAdapter
    @paths = @trailmaster.generatePaths @world, @heroLank.thang
    @paths.name = 'paths'
    layerAdapter.addChild @paths

  hidePaths: ->
    return if not @paths
    if @paths.parent
      @paths.parent.removeChild @paths
    @paths = null



  #- Screenshot

  screenshot: (scale=0.25, format='image/jpeg', quality=0.8, zoom=2) ->
    # TODO: get screenshots working again
    # Quality doesn't work with image/png, just image/jpeg and image/webp
    [w, h] = [@camera.canvasWidth * @camera.canvasScaleFactorX, @camera.canvasHeight * @camera.canvasScaleFactorY]
    margin = (1 - 1 / zoom) / 2
    @webGLStage.cache margin * w, margin * h, w / zoom, h / zoom, scale * zoom
    imageData = @webGLStage.cacheCanvas.toDataURL(format, quality)
    #console.log 'Screenshot with scale', scale, 'format', format, 'quality', quality, 'was', Math.floor(imageData.length / 1024), 'kB'
    screenshot = document.createElement('img')
    screenshot.src = imageData
    @webGLStage.uncache()
    imageData



  #- Path finding debugging

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



  #- Teardown

  destroy: ->
    @camera?.destroy()
    createjs.Ticker.removeEventListener('tick', @tick)
    createjs.Sound.stop()
    layer.destroy() for layer in @normalLayers
    @lankBoss.destroy()
    @chooser?.destroy()
    @dimmer?.destroy()
    @countdownScreen?.destroy()
    @playbackOverScreen?.destroy()
    @coordinateDisplay?.destroy()
    @coordinateGrid?.destroy()
    @normalStage.clear()
    @webGLStage.clear()
    @musicPlayer?.destroy()
    @trailmaster?.destroy()
    @normalStage.removeAllChildren()
    @webGLStage.removeAllChildren()
    @webGLStage.removeEventListener 'stagemousemove', @onMouseMove
    @webGLStage.removeEventListener 'stagemousedown', @onMouseDown
    @webGLStage.removeEventListener 'stagemouseup', @onMouseUp
    @webGLStage.removeAllEventListeners()
    @normalStage.enableDOMEvents false
    @webGLStage.enableDOMEvents false
    @webGLStage.enableMouseOver 0
    @webGLCanvas.off 'mousewheel', @onMouseWheel
    $(window).off 'resize', @onResize
    $(window).off('keydown', @onKeyEvent)
    $(window).off('keyup', @onKeyEvent)
    clearTimeout @surfacePauseTimeout if @surfacePauseTimeout
    clearTimeout @surfaceZoomPauseTimeout if @surfaceZoomPauseTimeout
    super()
