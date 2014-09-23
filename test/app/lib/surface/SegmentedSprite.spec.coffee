LayerAdapter = require 'lib/surface/LayerAdapter'
SegmentedSprite = require 'lib/surface/SegmentedSprite'
CocoSprite = require 'lib/surface/CocoSprite'
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
ogreFangriderThangType = new ThangType(require 'test/app/fixtures/ogre-fangrider.thang.type')

describe 'SegmentedSprite', ->
  segmentedSprite = null
  stage = null
  
  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.Stage(canvas[0]) # this is not a SpriteStage because some tests require adding MovieClips
    stage.addChild(segmentedSprite)
    window.stage = stage
  
    ticks = 0
    listener = {
      handleEvent: ->
        return if ticks >= 100
        ticks += 1
        segmentedSprite.tick(arguments[0].delta)
        stage.update()
    }
    createjs.Ticker.addEventListener "tick", listener
    
  describe 'with Ogre Munchkin ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true})
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreMunchkinThangType.markToRevert()
      ogreMunchkinThangType.set('spriteType', 'segmented')
      actions = ogreMunchkinThangType.getActions()
      
      # couple extra actions for doing some tests
      actions.littledance = {animation:'enemy_small_move_side',framerate:1, frames:'0,6,2,6,2,8,0'}
      actions.onestep = {animation:'enemy_small_move_side', loops: false}
      actions.head = {container:'head'}
      
      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.'
      window.segmentedSprite = segmentedSprite = new SegmentedSprite(sheet, ogreMunchkinThangType, prefix)
      segmentedSprite.x = 100
      segmentedSprite.y = 200
    
    afterEach ->
      ogreMunchkinThangType.revert()

    it 'has gotoAndPlay, gotoAndStop, currentAnimation, and paused like a MovieClip or Sprite', ->
      segmentedSprite.gotoAndPlay('move_fore')
      expect(segmentedSprite.baseMovieClip).toBeDefined()
      expect(segmentedSprite.paused).toBe(false)
      segmentedSprite.gotoAndStop('move_fore')
      expect(segmentedSprite.paused).toBe(true)
      expect(segmentedSprite.currentAnimation).toBe('move_fore')
  
    it 'has a tick function which moves the animation forward', ->
      segmentedSprite.gotoAndPlay('attack')
      segmentedSprite.tick(100) # one hundred milliseconds
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(segmentedSprite.framerate*100/1000)
      
    it 'will interpolate between frames of a custom frame set', ->
      segmentedSprite.gotoAndPlay('littledance')
      segmentedSprite.tick(1000)
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(6)
      segmentedSprite.tick(1000)
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(2)
      segmentedSprite.tick(500)
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(4)
      segmentedSprite.tick(500)
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(6)

    it 'emits animationend for animations where loops is false and there is no goesTo', ->
      fired = false
      segmentedSprite.gotoAndPlay('onestep')
      segmentedSprite.on('animationend', -> fired = true)
      segmentedSprite.tick(1000)
      expect(fired).toBe(true)

    it 'scales rendered animations like a MovieClip', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      segmentedSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(ogreMunchkinThangType)
      movieClip = builder.buildMovieClip('enemy_small_move_side')
      movieClip.x = 100
      movieClip.y = 200
      movieClip.regX = 285
      movieClip.regY = 300
      movieClip.stop()
      showMe()
      stage.addChild(movieClip)
      stage.update()
      t = new Date()
      tests = hits = 0
      for x in _.range(50, 160, 20)
        for y in _.range(50, 220, 20)
          tests += 1
          objects = stage.getObjectsUnderPoint(x, y)
          if objects.length
            hasSprite = _.any objects, (o) -> o instanceof createjs.Sprite
            hasShape = _.any objects, (o) -> o instanceof createjs.Shape
            hits+= 1 if hasSprite and hasShape
          else
            hits += 1

      expect(hits / tests).toBeGreaterThan(0.98) # not perfect, but pretty close.
      expect(segmentedSprite.baseScaleX).toBe(0.3)
      expect(segmentedSprite.baseScaleY).toBe(0.3)
      $('canvas').remove()

    it 'scales placeholder animations like a MovieClip', ->
      segmentedSprite.usePlaceholders = true
      segmentedSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(ogreMunchkinThangType)
      movieClip = builder.buildMovieClip('enemy_small_move_side')
      movieClip.x = 100
      movieClip.y = 200
      movieClip.regX = 285
      movieClip.regY = 300
      movieClip.stop()
      showMe()
      stage.addChild(movieClip)
      stage.update()
      t = new Date()
      tests = hits = 0
      for x in _.range(50, 160, 20)
        for y in _.range(50, 220, 20)
          tests += 1
          objects = stage.getObjectsUnderPoint(x, y)
          if objects.length
            hasSprite = _.any objects, (o) -> o instanceof createjs.Sprite
            hasShape = _.any objects, (o) -> o instanceof createjs.Shape
            hits+= 1 if hasSprite and hasShape
          else
            hits += 1

      expect(hits / tests).toBeGreaterThan(0.96) # not as perfect, but still, close!
      $('canvas').remove()
      
    it 'propagates events from the segments through the segmented sprite', ->
      fired = {}
      segmentedSprite.on('click', -> fired.didIt = true)
      segmentedSprite.gotoAndStop('idle')
      segmentedSprite.children[0].children[0].dispatchEvent('click')
      expect(fired.didIt).toBe(true)

  describe 'with Ogre Fangrider ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true})
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreFangriderThangType.markToRevert()
      ogreFangriderThangType.set('spriteType', 'segmented')
      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new CocoSprite(ogreFangriderThangType, {colorConfig: colorConfig})
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreFangriderThangType, null, colorConfig) + '.'
      window.segmentedSprite = segmentedSprite = new SegmentedSprite(sheet, ogreFangriderThangType, prefix)
      segmentedSprite.x = 300
      segmentedSprite.y = 300
  
    afterEach ->
      ogreFangriderThangType.revert()
  
    it 'synchronizes animations with child movie clips properly', ->
      segmentedSprite.gotoAndPlay('die')
      segmentedSprite.tick(100) # one hundred milliseconds
      expectedFrame = segmentedSprite.framerate*100/1000
      expect(segmentedSprite.currentFrame).toBe(expectedFrame)
      for movieClip in segmentedSprite.childMovieClips
        expect(movieClip.currentFrame).toBe(expectedFrame)

    it 'does not include shapes from the original animation', ->
      segmentedSprite.gotoAndPlay('attack')
      segmentedSprite.tick(230)
      for child in segmentedSprite.children
        expect(_.isString(child)).toBe(false)

    it 'maintains the right number of shapes', ->
      segmentedSprite.gotoAndPlay('idle')
      lengths = []
      for i in _.range(10)
        segmentedSprite.tick(10)
        expect(segmentedSprite.children.length).toBe(20)
