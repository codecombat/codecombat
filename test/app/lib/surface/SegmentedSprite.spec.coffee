LayerAdapter = require 'lib/surface/LayerAdapter'
SegmentedSprite = require 'lib/surface/SegmentedSprite'
Lank = require 'lib/surface/Lank'
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
ogreFangriderThangType = new ThangType(require 'test/app/fixtures/ogre-fangrider.thang.type')
treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')
scaleTestUtils = require './scale-testing-utils'
createjs = require 'lib/createjs-parts'

describe 'SegmentedSprite', ->
  segmentedSprite = null
  stage = null

  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.Stage(canvas[0])
    stage.addChild(segmentedSprite)
    scale = 3
    stage.scaleX = stage.scaleY = scale
    stage.regX = -300 / scale
    stage.regY = -200 / scale
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

  describe 'with Tree ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true, name:'Default'})
      layer.buildAutomatically = false
      layer.buildAsync = false
      treeThangType.markToRevert()
      treeThangType.set('spriteType', 'segmented')
      sprite = new Lank(treeThangType)
      layer.addLank(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(treeThangType) + '.'
      window.segmentedSprite = segmentedSprite = new SegmentedSprite(sheet, treeThangType, prefix)

    it 'scales rendered containers to the size of the source container', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      segmentedSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(treeThangType)
      container = builder.buildContainerFromStore('Tree_4')
      container.scaleX = container.scaleY = 0.3
      container.regX = 59
      container.regY = 100
      showMe()
      stage.addChild(container)
      stage.update()
      hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40))
      expect(hitRate).toBeGreaterThan(0.92)
      $('canvas').remove()

    it 'scales placeholder containers to the size of the source container', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      segmentedSprite.usePlaceholders = true
      segmentedSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(treeThangType)
      container = builder.buildContainerFromStore('Tree_4')
      container.scaleX = container.scaleY = 0.3
      container.regX = 59
      container.regY = 100
      showMe()
      stage.addChild(container)
      stage.update()
      hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40))
      expect(hitRate).toBeGreaterThan(0.73)
      $('canvas').remove()

  describe 'with Ogre Munchkin ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true, name:'Default'})
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreMunchkinThangType.markToRevert()
      ogreMunchkinThangType.set('spriteType', 'segmented')
      actions = ogreMunchkinThangType.getActions()

      # couple extra actions for doing some tests
      actions.littledance = {animation:'enemy_small_move_side',framerate:1, frames:'0,6,2,6,2,8,0', name: 'littledance'}
      actions.onestep = {animation:'enemy_small_move_side', loops: false, name:'onestep'}
      actions.head = {container:'head', name:'head'}

      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new Lank(ogreMunchkinThangType, {colorConfig: colorConfig})
      layer.addLank(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.'
      window.segmentedSprite = segmentedSprite = new SegmentedSprite(sheet, ogreMunchkinThangType, prefix)

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

    it 'emits animationend for animations where loops is false and there is no goesTo', (done) ->
      fired = false
      segmentedSprite.gotoAndPlay('onestep')
      segmentedSprite.on('animationend', -> fired = true)
      segmentedSprite.tick(1000)
      _.defer -> # because the event is deferred
        expect(fired).toBe(true)
        done()

    it 'scales rendered animations like a MovieClip', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      segmentedSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(ogreMunchkinThangType)
      movieClip = builder.buildMovieClip('enemy_small_move_side')
      movieClip.scaleX = movieClip.scaleY = 0.3
      movieClip.regX = 285
      movieClip.regY = 300
      movieClip.stop()
      showMe()
      stage.addChild(movieClip)

      stage.update()
      hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-10, -30, 25, 35))
      expect(hitRate).toBeGreaterThan(0.91)
      expect(segmentedSprite.baseScaleX).toBe(0.3)
      expect(segmentedSprite.baseScaleY).toBe(0.3)
      $('canvas').remove()

    it 'scales placeholder animations like a MovieClip', ->
      segmentedSprite.usePlaceholders = true
      segmentedSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(ogreMunchkinThangType)
      movieClip = builder.buildMovieClip('enemy_small_move_side')
      movieClip.scaleX = movieClip.scaleY = 0.3
      movieClip.regX = 285
      movieClip.regY = 300
      movieClip.stop()
      showMe()
      stage.addChild(movieClip)
      stage.update()
      hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-10, -30, 25, 35))
      expect(hitRate).toBeGreaterThan(0.96)
      $('canvas').remove()

  describe 'with Ogre Fangrider ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true})
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreFangriderThangType.markToRevert()
      ogreFangriderThangType.set('spriteType', 'segmented')
      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new Lank(ogreFangriderThangType, {colorConfig: colorConfig})
      layer.addLank(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreFangriderThangType, null, colorConfig) + '.'
      window.segmentedSprite = segmentedSprite = new SegmentedSprite(sheet, ogreFangriderThangType, prefix)

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
