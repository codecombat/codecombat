SpriteBoss = require 'lib/surface/SpriteBoss'
Camera = require 'lib/surface/Camera'
World = require 'lib/world/world'
ThangType = require 'models/ThangType'

treeThangType = new ThangType(require 'test/app/fixtures/tree1.thang.type')
ogreMunchkinThangType = new ThangType(require 'test/app/fixtures/ogre-munchkin-m.thang.type')
ogreFangriderThangType = new ThangType(require 'test/app/fixtures/ogre-fangrider.thang.type')

describe 'SpriteBoss', ->
  spriteBoss = null
  canvas = null
  stage = null
  
  # This suite just creates and renders the stage once, and then has each of the tests
  # check the resulting data for the whole thing, without changing anything.
  
  init = (done) ->
    return done() if spriteBoss
    t = new Date()
    canvas = $('<canvas width="800" height="600"></canvas>')
    camera = new Camera(canvas)
    
    # Create an initial, simple world with just trees
    world = new World()
    world.thangs = [
      # Set trees side by side with different render strategies
      {id: 'Tree 1', spriteName: 'Tree 1', exists: true, pos: {x:10, y:-8}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
      {id: 'Tree 2', spriteName: 'Full Render Tree', exists: true, pos: {x:8, y:-8}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
      
      # Include a tree whose existence will change so we can test removing sprites
      {id: 'Tree Will Disappear', spriteName: 'Tree 1', exists: true, pos: {x:0, y:0}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
    ]
    world.thangMap = {}
    world.thangMap[thang.id] = thang for thang in world.thangs
    
    # Set up thang types. Mix renderStrategies.
    fullRenderOgreMunchkinThangType = ogreMunchkinThangType.clone()
    fullRenderOgreMunchkinThangType.set({name:'Full Render Ogre', slug:'full-render-ogre'})
    fullRenderTreeThangType = treeThangType.clone()
    fullRenderTreeThangType.set({name:'Full Render Tree', slug:'full-render-tree'})
    ogreMunchkinThangType.set('renderStrategy', 'container')
    ogreFangriderThangType.set('renderStrategy', 'container')
    treeThangType.set('renderStrategy', 'container')
    thangTypes = [treeThangType, ogreMunchkinThangType, ogreFangriderThangType, fullRenderOgreMunchkinThangType, fullRenderTreeThangType]
    
    # Build the Stage and SpriteBoss.
    window.stage = stage = new createjs.Stage(canvas[0])
    options = {
      camera: camera
      surfaceLayer: stage
      surfaceTextLayer: new createjs.Container()
      world: world
      thangTypes: thangTypes
    }
    
    window.spriteBoss = spriteBoss = new SpriteBoss(options)
    
    defaultLayer = spriteBoss.spriteLayers.Default
    defaultLayer.buildAsync = false # cause faster
    
    # Don't have the layer automatically draw for move_fore, instead have it notified from WebGLSprites that
    # this animation or its containers are needed.
#    defaultLayer.setDefaultActions(_.without defaultLayer.defaultActions, 'move_fore')
    
    # Render the simple world with just trees
    spriteBoss.update(true)
    defaultLayer.once 'new-spritesheet', ->
      
      # Now make the world a little more complicated.
      world.thangs = world.thangs.concat [
        # four cardinal ogres, to test movement rotation and placement around a center point.
        {id: 'Ogre N', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:0, y:8}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, scaleFactorX: 1.5 }
        {id: 'Ogre W', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:-8, y:0}, action: 'move', health: 5, maxHealth: 10, rotation: 0, acts: true, scaleFactorY: 1.5 }
        {id: 'Ogre E', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:8, y:0}, action: 'move', health: 5, maxHealth: 10, rotation: Math.PI, acts: true, alpha: 0.5 }
        {id: 'Ogre S', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:0, y:-8}, action: 'move', health: 5, maxHealth: 10, rotation: Math.PI/2, acts: true }

        # Set ogres side by side with different render strategies
        {id: 'FROgre', spriteName: 'Full Render Ogre', exists: true, pos: {x:-10, y:-8}, action: 'idle', health: 10, maxHealth: 10, rotation: 0, acts: true }
        {id: 'NotFROgre', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:-8, y:-8}, action: 'idle', health: 10, maxHealth: 10, rotation: 0, acts: true }

        # A line of ogres overlapping to test child ordering
        {id: 'Ogre 1', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:-14, y:0}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Ogre 2', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:-13.5, y:1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Ogre 3', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:-13, y:2}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Ogre 4', spriteName: 'Ogre Munchkin M', exists: true, pos: {x:-12.5, y:3}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        
        # Throw in a ThangType that contains nested MovieClips
        {id: 'Fangrider 1', spriteName: 'Ogre Fangrider', exists: true, pos: {x:8, y:8}, action: 'move', health: 20, maxHealth: 20, rotation: 0, acts: true }
      ]
      
      _.find(world.thangs, {id: 'Tree Will Disappear'}).exists = false      
      world.thangMap[thang.id] = thang for thang in world.thangs
      spriteBoss.update(true)
      defaultLayer.once 'new-spritesheet', ->
        done()
        
        showMe() # Uncomment to display this world when you run any of these tests.

  beforeEach (done) -> init(done)

  showMe = ->
    canvas.css('position', 'absolute').css('index', 1000).css('background', 'white')
    $('body').append(canvas)
    
    ticks = 0
    listener = {
      handleEvent: ->
        return if ticks >= 100
        ticks += 1
        console.log 'update'
        stage.update()
    }
    createjs.Ticker.addEventListener "tick", listener
    $('body').append($('<div style="position: absolute; top: 295px; left: 395px; height: 10px; width: 10px; background: red;"></div>'))

  it 'rotates and animates sprites according to thang rotation', ->
    expect(spriteBoss.sprites['Ogre N'].imageObject.currentAnimation).toBe('move_fore')
    expect(spriteBoss.sprites['Ogre E'].imageObject.currentAnimation).toBe('move_side')
    expect(spriteBoss.sprites['Ogre W'].imageObject.currentAnimation).toBe('move_side')
    expect(spriteBoss.sprites['Ogre S'].imageObject.currentAnimation).toBe('move_back')

    expect(spriteBoss.sprites['Ogre E'].imageObject.scaleX).toBeLessThan(0)
    expect(spriteBoss.sprites['Ogre W'].imageObject.scaleX).toBeGreaterThan(0)

  it 'positions sprites according to thang pos', ->
    expect(spriteBoss.sprites['Ogre N'].imageObject.x).toBe(0)
    expect(spriteBoss.sprites['Ogre N'].imageObject.y).toBeCloseTo(-60)
    expect(spriteBoss.sprites['Ogre E'].imageObject.x).toBeCloseTo(80)
    expect(spriteBoss.sprites['Ogre E'].imageObject.y).toBe(0)
    expect(spriteBoss.sprites['Ogre W'].imageObject.x).toBe(-80)
    expect(spriteBoss.sprites['Ogre W'].imageObject.y).toBeCloseTo(0)
    expect(spriteBoss.sprites['Ogre S'].imageObject.x).toBe(0)
    expect(spriteBoss.sprites['Ogre S'].imageObject.y).toBeCloseTo(60)
    
  it 'scales sprites according to thang scaleFactorX and scaleFactorY', ->
    expect(spriteBoss.sprites['Ogre N'].imageObject.scaleX).toBe(spriteBoss.sprites['Ogre N'].baseScaleX * 2)
    expect(spriteBoss.sprites['Ogre W'].imageObject.scaleY).toBe(spriteBoss.sprites['Ogre N'].baseScaleY * 2)

  it 'sets alpha based on thang alpha', ->
    expect(spriteBoss.sprites['Ogre E'].imageObject.alpha).toBe(0.5)
    
  it 'orders sprites in the layer based on thang pos.y\'s', ->
    container = spriteBoss.spriteLayers.Default.spriteContainer
    l = spriteBoss.spriteLayers.Default.spriteContainer.children
    i1 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Ogre 1'))
    i2 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Ogre 2'))
    i3 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Ogre 3'))
    i4 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Ogre 4'))
    expect(i1).toBeGreaterThan(i2)
    expect(i2).toBeGreaterThan(i3)
    expect(i3).toBeGreaterThan(i4)

  it 'only contains children Sprites and SpriteContainers whose spritesheet matches the Layer', ->
    defaultLayerContainer = spriteBoss.spriteLayers.Default.spriteContainer
    for c in defaultLayerContainer.children
      expect(c.spriteSheet).toBe(defaultLayerContainer.spriteSheet)
