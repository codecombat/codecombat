WebGLLayer = require 'lib/surface/WebGLLayer'
CocoSprite = require 'lib/surface/CocoSprite'
ThangType = require 'models/ThangType'
treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')

describe 'WebGLLayer', ->
  it 'creates containers for animated actions if set to renderStrategy=container', ->
    layer = new WebGLLayer()
    ogreMunchkinThangType.set('renderStrategy', 'container')
    colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
    sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(ogreMunchkinThangType, 'head', colorConfig)
    expect(key in sheet.getAnimations()).toBe(true)

  it 'creates the container for static actions if set to renderStrategy=container', ->
    layer = new WebGLLayer()
    treeThangType.set('renderStrategy', 'container')
    sprite = new CocoSprite(treeThangType)
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(treeThangType, 'Tree_4')
    expect(key in sheet.getAnimations()).toBe(true)

  it 'creates animations for animated actions if set to renderStrategy=spriteSheet', ->
    layer = new WebGLLayer()
    ogreMunchkinThangType.set('renderStrategy', 'spriteSheet')
    colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
    sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(ogreMunchkinThangType, 'idle', colorConfig)
    expect(key in sheet.getAnimations()).toBe(true)

  it 'creates animations for static actions if set to renderStrategy=spriteSheet', ->
    layer = new WebGLLayer()
    treeThangType.set('renderStrategy', 'spriteSheet')
    sprite = new CocoSprite(treeThangType)
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(treeThangType, 'idle')
    expect(key in sheet.getAnimations()).toBe(true)
    
  it 'only renders frames used by actions when renderStrategy=spriteSheet', ->
    layer = new WebGLLayer()
    layer.setDefaultActions(['idle']) # uses the move side animation
    ogreMunchkinThangType.set('renderStrategy', 'spriteSheet')
    colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
    sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(ogreMunchkinThangType, 'idle', colorConfig)
    animations = sheet.getAnimations()
    expect(animations.length).toBe(1)
    expect(animations[0]).toBe(key)
    expect(sheet.getNumFrames()).toBe(1)

  it 'renders a raster image onto a sheet', (done) ->
    bootsThangType = new ThangType(require 'test/app/fixtures/leather-boots.thang.type')
    bootsThangType.loadRasterImage()
    bootsThangType.once('raster-image-loaded', ->
      layer = new WebGLLayer()
      sprite = new CocoSprite(bootsThangType)
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      key = layer.renderGroupingKey(bootsThangType)
      expect(key in sheet.getAnimations()).toBe(true)
      done()
      #$('body').attr('class', '').empty().css('background', 'white').append($(sheet._images))
    )