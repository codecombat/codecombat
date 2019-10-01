LayerAdapter = require 'lib/surface/LayerAdapter'
SingularSprite = require 'lib/surface/SingularSprite'
Lank = require 'lib/surface/Lank'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
ThangType = require 'models/ThangType'
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')
scaleTestUtils = require './scale-testing-utils'
createjs = require 'lib/createjs-parts'

describe 'SingularSprite', ->
  singularSprite = null
  stage = null

  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.Stage(canvas[0])
    stage.addChild(singularSprite)
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
        stage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

  afterEach ->
    g = new createjs.Graphics()
    g.beginFill(createjs.Graphics.getRGB(64,255,64,0.7))
    g.drawCircle(0, 0, 1)
    s = new createjs.Shape(g)
    stage.addChild(s)

  describe 'with Tree ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true, name:'Default'})
      layer.buildAutomatically = false
      layer.buildAsync = false
      treeThangType.markToRevert()
      treeThangType.set('spriteType', 'singular')
      sprite = new Lank(treeThangType)
      layer.addLank(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(treeThangType) + '.'
      window.singularSprite = singularSprite = new SingularSprite(sheet, treeThangType, prefix)
      singularSprite.x = 0
      singularSprite.y = 0

    it 'scales rendered containers to the size of the source container, taking into account ThangType scaling', ->
      # build a movie clip, put it on top of the singular sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(treeThangType)
      container = builder.buildContainerFromStore('Tree_4')
      container.regX = 59
      container.regY = 100
      container.scaleX = container.scaleY = 0.3
      showMe()
      stage.addChild(container)
      stage.update()
      hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40))
      expect(hitRate).toBeGreaterThan(0.92)
#      $('canvas').remove()

    it 'scales placeholder containers to the size of the source container, taking into account ThangType scaling', ->
      # build a movie clip, put it on top of the singular sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.usePlaceholders = true
      singularSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(treeThangType)
      container = builder.buildContainerFromStore('Tree_4')
      container.regX = 59
      container.regY = 100
      container.scaleX = container.scaleY = 0.3
      showMe()
      stage.addChild(container)
      stage.update()
      hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40))
      expect(hitRate).toBeGreaterThan(0.73)
#      $('canvas').remove()

  describe 'with Ogre Munchkin ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true, name:'Default'})
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreMunchkinThangType.markToRevert()
      ogreMunchkinThangType.set('spriteType', 'singular')
      actions = ogreMunchkinThangType.getActions()

      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new Lank(ogreMunchkinThangType, {colorConfig: colorConfig})
      layer.addLank(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.'
      window.singularSprite = singularSprite = new SingularSprite(sheet, ogreMunchkinThangType, prefix)

    afterEach ->
      ogreMunchkinThangType.revert()

    it 'has the same interface as Sprite for animation', ->
      singularSprite.gotoAndPlay('move_fore')
      singularSprite.gotoAndStop('attack')

    it 'scales rendered animations like a MovieClip, taking into account ThangType scaling', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.gotoAndStop('idle')
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
      $('canvas').remove()

    it 'scales placeholder animations like a MovieClip, taking into account ThangType scaling', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.usePlaceholders = true
      singularSprite.gotoAndStop('idle')
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
      expect(hitRate).toBeGreaterThan(0.71)
      $('canvas').remove()
