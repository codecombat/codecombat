LayerAdapter = require 'lib/surface/LayerAdapter'
SingularSprite = require 'lib/surface/SingularSprite'
CocoSprite = require 'lib/surface/CocoSprite'
ThangType = require 'models/ThangType'
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')

describe 'SingularSprite', ->
  singularSprite = null

  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.SpriteStage(canvas[0])
    stage.addChild(singularSprite)

    ticks = 0
    listener = {
      handleEvent: ->
        return if ticks >= 100
        ticks += 1
        stage.update()
    }
    createjs.Ticker.addEventListener "tick", listener

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
      singularSprite.x = 200
      singularSprite.y = 200

    afterEach ->
      ogreMunchkinThangType.revert()

    it 'has the same interface as Sprite for animation', ->
      singularSprite.gotoAndPlay('move_fore')
      singularSprite.gotoAndStop('attack') 
