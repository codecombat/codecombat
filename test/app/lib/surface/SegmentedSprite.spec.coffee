LayerAdapter = require 'lib/surface/LayerAdapter'
SegmentedSprite = require 'lib/surface/SegmentedSprite'
CocoSprite = require 'lib/surface/CocoSprite'
ThangType = require 'models/ThangType'
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
ogreFangriderThangType = new ThangType(require 'test/app/fixtures/ogre-fangrider.thang.type')

describe 'SegmentedSprite', ->
  segmentedSprite = null
  
  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.SpriteStage(canvas[0])
    stage.addChild(segmentedSprite)
  
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
      layer = new LayerAdapter()
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreMunchkinThangType.markToRevert()
      ogreMunchkinThangType.set('spriteType', 'segmented')
      actions = ogreMunchkinThangType.getActions()
      
      # couple extra actions for doing some tests
      actions.littledance = {animation:'enemy_small_move_side',framerate:1, frames:'0,6,2,6,2,8,0'}
      actions.onestep = {animation:'enemy_small_move_side', loops: false}
      
      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.'
      window.segmentedSprite = segmentedSprite = new SegmentedSprite(sheet, ogreMunchkinThangType, prefix)
      segmentedSprite.x = 200
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

  describe 'with Ogre Fangrider ThangType', ->
    beforeEach ->
      layer = new LayerAdapter()
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
