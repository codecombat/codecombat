WebGLLayer = require 'lib/surface/WebGLLayer'
CocoSprite = require 'lib/surface/CocoSprite'
ThangType = require 'models/ThangType'
treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')

describe 'WebGLLayer', ->
  layer = null
  beforeEach ->
    layer = new WebGLLayer()
    layer.buildAutomatically = false
    layer.buildAsync = false
  
  it 'creates containers for animated actions if set to renderStrategy=container', ->
    ogreMunchkinThangType.set('renderStrategy', 'container')
    colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
    sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(ogreMunchkinThangType, 'head', colorConfig)
    expect(key in sheet.getAnimations()).toBe(true)

  it 'creates the container for static actions if set to renderStrategy=container', ->
    treeThangType.set('renderStrategy', 'container')
    sprite = new CocoSprite(treeThangType)
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(treeThangType, 'Tree_4')
    expect(key in sheet.getAnimations()).toBe(true)

  it 'creates animations for animated actions if set to renderStrategy=spriteSheet', ->
    ogreMunchkinThangType.set('renderStrategy', 'spriteSheet')
    colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}}
    sprite = new CocoSprite(ogreMunchkinThangType, {colorConfig: colorConfig})
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(ogreMunchkinThangType, 'idle', colorConfig)
    expect(key in sheet.getAnimations()).toBe(true)

  it 'creates animations for static actions if set to renderStrategy=spriteSheet', ->
    treeThangType.set('renderStrategy', 'spriteSheet')
    sprite = new CocoSprite(treeThangType)
    layer.addCocoSprite(sprite)
    sheet = layer.renderNewSpriteSheet()
    key = layer.renderGroupingKey(treeThangType, 'idle')
    expect(key in sheet.getAnimations()).toBe(true)
    
  it 'only renders frames used by actions when renderStrategy=spriteSheet', ->
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
      sprite = new CocoSprite(bootsThangType)
      layer.addCocoSprite(sprite)
      sheet = layer.renderNewSpriteSheet()
      key = layer.renderGroupingKey(bootsThangType)
      expect(key in sheet.getAnimations()).toBe(true)
      done()
      #$('body').attr('class', '').empty().css('background', 'white').append($(sheet._images))
    )
  
  it 'loads ThangTypes for CocoSprites that are added to it and need to be loaded', ->
    thangType = new ThangType({_id: 1})
    sprite = new CocoSprite(thangType)
    layer.addCocoSprite(sprite)
    expect(layer.numThingsLoading).toBe(1)
    expect(jasmine.Ajax.requests.count()).toBe(1)
    
  it 'loads raster images for ThangType', (done) ->
    bootsThangTypeData = require 'test/app/fixtures/leather-boots.thang.type'
    thangType = new ThangType({_id: 1})
    sprite = new CocoSprite(thangType)
    layer.addCocoSprite(sprite)
    expect(layer.numThingsLoading).toBe(1)
    jasmine.Ajax.requests.sendResponses({'/db/thang.type/1': bootsThangTypeData})
    expect(layer.numThingsLoading).toBe(1)
    thangType.once('raster-image-loaded', ->
      expect(layer.numThingsLoading).toBe(0)
      done()
    )
    
  it 'renders a new SpriteSheet only once everything has loaded', (done) ->
    bootsThangTypeData = require 'test/app/fixtures/leather-boots.thang.type'
    thangType1 = new ThangType({_id: 1})
    thangType2 = new ThangType({_id: 2})
    layer.addCocoSprite(new CocoSprite(thangType1))
    expect(layer.numThingsLoading).toBe(1)
    layer.addCocoSprite(new CocoSprite(thangType2))
    expect(layer.numThingsLoading).toBe(2)
    spyOn layer, '_renderNewSpriteSheet'
    jasmine.Ajax.requests.sendResponses({'/db/thang.type/1': ogreMunchkinThangType.attributes})
    expect(layer.numThingsLoading).toBe(1)
    jasmine.Ajax.requests.sendResponses({'/db/thang.type/2': bootsThangTypeData})
    expect(layer.numThingsLoading).toBe(1)
    expect(layer._renderNewSpriteSheet).not.toHaveBeenCalled()
    thangType2.once('raster-image-loaded', ->
      expect(layer.numThingsLoading).toBe(0)
      expect(layer._renderNewSpriteSheet).toHaveBeenCalled()
      done()
    )
