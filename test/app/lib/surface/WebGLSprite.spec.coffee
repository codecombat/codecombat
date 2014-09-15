WebGLLayer = require 'lib/surface/WebGLLayer'
WebGLSprite = require 'lib/surface/WebGLSprite'
CocoSprite = require 'lib/surface/CocoSprite'
ThangType = require 'models/ThangType'
treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
ogreFangriderThangType = new ThangType(require 'test/app/fixtures/ogre-fangrider.thang.type')

describe 'WebGLSprite', ->
  webGLSprite = null
  
  showMe = ->
    canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000)#.css('background', 'white')
    $('body').append(canvas)
    stage = new createjs.SpriteStage(canvas[0])
    stage.addChild(webGLSprite)
  
    ticks = 0
    listener = {
      handleEvent: ->
#        return if ticks >= 100
        webGLSprite.tick(arguments[0].delta)
        stage.update()
        ticks += 1
    }
    createjs.Ticker.addEventListener "tick", listener
    
  describe 'with Ogre Munchkin ThangType', ->
    beforeEach ->
      layer = new WebGLLayer()
      ogreMunchkinThangType.markToRevert()
      ogreMunchkinThangType.set('renderStrategy', 'container')
      actions = ogreMunchkinThangType.getActions()
      
      # couple extra actions for doing some tests
      actions.littledance = {animation:'enemy_small_move_side',framerate:1, frames:'0,6,2,6,2,8,0'}
      actions.onestep = {animation:'enemy_small_move_side', loops: false}
      
      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.'
      window.webGLSprite = webGLSprite = new WebGLSprite(sheet, ogreMunchkinThangType, prefix)
    
    afterEach ->
      ogreMunchkinThangType.revert()

    it 'has gotoAndPlay, gotoAndStop, and paused like a MovieClip or Sprite', ->
      webGLSprite.gotoAndPlay('move_fore')
      expect(webGLSprite.baseMovieClip).toBeDefined()
      expect(webGLSprite.paused).toBe(false)
      webGLSprite.gotoAndStop('move_fore')
      expect(webGLSprite.paused).toBe(true)
  
    it 'is paused when the action is a single frame', ->
      webGLSprite.gotoAndPlay('idle')
      expect(webGLSprite.paused).toBe(true)
      
    it 'has a tick function which moves the animation forward', ->
      webGLSprite.gotoAndPlay('move_fore')
      webGLSprite.tick(100) # one hundred milliseconds
      expect(webGLSprite.baseMovieClip.currentFrame).toBe(webGLSprite.framerate*100/1000)
      
    it 'will interpolate between frames of a custom frame set', ->
      webGLSprite.gotoAndPlay('littledance')
      webGLSprite.tick(1000)
      expect(webGLSprite.baseMovieClip.currentFrame).toBe(6)
      webGLSprite.tick(1000)
      expect(webGLSprite.baseMovieClip.currentFrame).toBe(2)
      webGLSprite.tick(500)
      expect(webGLSprite.baseMovieClip.currentFrame).toBe(4)
      webGLSprite.tick(500)
      expect(webGLSprite.baseMovieClip.currentFrame).toBe(6)
  
    it 'emits animationend for animations where loops is false and there is no goesTo', ->
      fired = false
      webGLSprite.gotoAndPlay('onestep')
      webGLSprite.on('animationend', -> fired = true)
      webGLSprite.tick(1000)
      expect(fired).toBe(true)

  describe 'with Ogre Fangrider ThangType', ->
    beforeEach ->
      layer = new WebGLLayer()
      ogreFangriderThangType.markToRevert()
      ogreFangriderThangType.set('renderStrategy', 'container')
      colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
      sprite = new CocoSprite(ogreFangriderThangType, {colorConfig: colorConfig})
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      prefix = layer.renderGroupingKey(ogreFangriderThangType, null, colorConfig) + '.'
      window.webGLSprite = webGLSprite = new WebGLSprite(sheet, ogreFangriderThangType, prefix)
  
    afterEach ->
      ogreFangriderThangType.revert()
  
    it 'has gotoAndPlay, gotoAndStop, and paused like a MovieClip or Sprite', ->
      webGLSprite.gotoAndPlay('move_fore')
      webGLSprite.tick(100) # one hundred milliseconds
      expectedFrame = webGLSprite.framerate*100/1000
      expect(webGLSprite.baseMovieClip.currentFrame).toBe(expectedFrame)
      for child in webGLSprite.childSpriteContainers
        expect(child.movieClip.currentFrame).toBe(expectedFrame)
      showMe()
