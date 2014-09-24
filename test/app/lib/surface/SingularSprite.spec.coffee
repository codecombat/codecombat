LayerAdapter = require 'lib/surface/LayerAdapter'
SingularSprite = require 'lib/surface/SingularSprite'
CocoSprite = require 'lib/surface/CocoSprite'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
ThangType = require 'models/ThangType'
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')

describe 'SingularSprite', ->
  singularSprite = null
  stage = null

  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.Stage(canvas[0]) # this is not a SpriteStage because some tests require adding MovieClips
    stage.addChild(singularSprite)
    window.stage = stage

    ticks = 0
    listener = {
      handleEvent: ->
        return if ticks >= 100
        ticks += 1
        stage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

  describe 'with Tree ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true})
      layer.buildAutomatically = false
      layer.buildAsync = false
      treeThangType.markToRevert()
      treeThangType.set('spriteType', 'singular')
      sprite = new CocoSprite(treeThangType)
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(treeThangType) + '.'
      window.singularSprite = singularSprite = new SingularSprite(sheet, treeThangType, prefix)
      singularSprite.x = 100
      singularSprite.y = 200

    it 'scales rendered containers to the size of the source container', ->
      # build a movie clip, put it on top of the singular sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(treeThangType)
      container = builder.buildContainerFromStore('Tree_4')
      container.x = 100
      container.y = 200
      container.regX = 59
      container.regY = 100
      showMe()
      stage.addChild(container)
      stage.update()
      t = new Date()
      tests = hits = 0
      for x in _.range(30, 190, 20)
        for y in _.range(90, 250, 20)
          tests += 1
          objects = stage.getObjectsUnderPoint(x, y)
          if objects.length
            hasSprite = _.any objects, (o) -> o instanceof createjs.Sprite
            hasShape = _.any objects, (o) -> o instanceof createjs.Shape
            hits+= 1 if hasSprite and hasShape
            g = new createjs.Graphics()
            if hasSprite and hasShape
              g.beginFill(createjs.Graphics.getRGB(64,64,164,0.7))
            else if hasSprite
              g.beginFill(createjs.Graphics.getRGB(64,164,64,0.7))
            else
              g.beginFill(createjs.Graphics.getRGB(164,64,64,0.7))
            g.drawCircle(0, 0, 2)
            s = new createjs.Shape(g)
            s.x = x
            s.y = y
            stage.addChild(s)
          else
            hits += 1

      expect(hits / tests).toBeGreaterThan(0.98)
      expect(singularSprite.baseScaleX).toBeCloseTo(1.1111)
      expect(singularSprite.baseScaleY).toBeCloseTo(1.1111)
      $('canvas').remove()

    it 'scales placeholder containers to the size of the source container', ->
      # build a movie clip, put it on top of the singular sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.usePlaceholders = true
      singularSprite.gotoAndStop('idle')
      builder = new SpriteBuilder(treeThangType)
      container = builder.buildContainerFromStore('Tree_4')
      container.x = 100
      container.y = 200
      container.regX = 59
      container.regY = 100
      showMe()
      stage.addChild(container)
      stage.update()
      t = new Date()
      tests = hits = 0
      for x in _.range(30, 190, 20)
        for y in _.range(90, 250, 20)
          tests += 1
          objects = stage.getObjectsUnderPoint(x, y)
          if objects.length
            hasSprite = _.any objects, (o) -> o instanceof createjs.Sprite
            hasShape = _.any objects, (o) -> o instanceof createjs.Shape
            hits+= 1 if hasSprite and hasShape
            g = new createjs.Graphics()
            if hasSprite and hasShape
              g.beginFill(createjs.Graphics.getRGB(64,64,164,0.7))
            else if hasSprite
              g.beginFill(createjs.Graphics.getRGB(64,164,64,0.7))
            else
              g.beginFill(createjs.Graphics.getRGB(164,64,64,0.7))
            g.drawCircle(0, 0, 2)
            s = new createjs.Shape(g)
            s.x = x
            s.y = y
            stage.addChild(s)
          else
            hits += 1

      expect(hits / tests).toBeGreaterThan(0.84)
#      $('canvas').remove()
      
  describe 'with Ogre Munchkin ThangType', ->
    beforeEach ->
      layer = new LayerAdapter({webGL:true})
      layer.buildAutomatically = false
      layer.buildAsync = false
      ogreMunchkinThangType.markToRevert()
      ogreMunchkinThangType.set('spriteType', 'singular')
      actions = ogreMunchkinThangType.getActions()

      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.'
      window.singularSprite = singularSprite = new SingularSprite(sheet, ogreMunchkinThangType, prefix)
      singularSprite.x = 100
      singularSprite.y = 200

    afterEach ->
      ogreMunchkinThangType.revert()

    it 'has the same interface as Sprite for animation', ->
      singularSprite.gotoAndPlay('move_fore')
      singularSprite.gotoAndStop('attack')

    it 'scales rendered animations like a MovieClip', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.gotoAndStop('idle')
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
      $('canvas').remove()

    it 'scales placeholder animations like a MovieClip', ->
      # build a movie clip, put it on top of the segmented sprite and make sure
      # they both 'hit' at the same time.

      singularSprite.usePlaceholders = true
      singularSprite.gotoAndStop('idle')
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

      expect(hits / tests).toBeGreaterThan(0.87) # not perfect, but pretty close.
      $('canvas').remove()