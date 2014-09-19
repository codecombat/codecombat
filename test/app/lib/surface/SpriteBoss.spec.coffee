SpriteBoss = require 'lib/surface/SpriteBoss'
Camera = require 'lib/surface/Camera'
World = require 'lib/world/world'
ThangType = require 'models/ThangType'

treeData = require 'test/app/fixtures/tree1.thang.type'
munchkinData = require 'test/app/fixtures/ogre-munchkin-m.thang.type'
fangriderData = require 'test/app/fixtures/ogre-fangrider.thang.type'

describe 'SpriteBoss', ->
  spriteBoss = null
  canvas = null
  stage = null
  midRenderExpectations = [] # bit of a hack to move tests which happen mid-initialization into a separate test
  
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
      {id: 'Segmented Tree', spriteName: 'Segmented Tree', exists: true, pos: {x:10, y:-8}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
      {id: 'Singular Tree', spriteName: 'Singular Tree', exists: true, pos: {x:8, y:-8}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
      
      # Include a tree whose existence will change so we can test removing sprites
      {id: 'Disappearing Tree', spriteName: 'Singular Tree', exists: true, pos: {x:0, y:0}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
    ]
    world.thangMap = {}
    world.thangMap[thang.id] = thang for thang in world.thangs
    
    # Set up thang types. Mix renderStrategies.
    fangrider = new ThangType($.extend({}, fangriderData, {spriteType:'segmented', name:'Fangrider', slug:'fangrider'}))
    segmentedMunchkin = new ThangType($.extend({}, munchkinData, {spriteType:'segmented', name:'Segmented Munchkin', slug:'segmented-munchkin'}))
    singularMunchkin = new ThangType($.extend({}, munchkinData, {spriteType:'singular', name:'Singular Munchkin', slug:'singular-munchkin'}))
    segmentedTree = new ThangType($.extend({}, treeData, {spriteType:'segmented', name:'Segmented Tree', slug: 'segmented-tree'}))
    singularTree = new ThangType($.extend({}, treeData, {spriteType:'singular', name:'Singular Tree', slug: 'singular-tree'}))
    
    thangTypes = [fangrider, segmentedMunchkin, singularMunchkin, segmentedTree, singularTree]
    
    # Build the Stage and SpriteBoss.
    window.stage = stage = new createjs.SpriteStage(canvas[0])
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

    # Sort of an implicit test. By default, all the default actions are always rendered,
    # but I want to make sure the system can dynamically hear about actions it needs to render for
    # as they are used.
    defaultLayer.defaultActions = ['idle']
    
    # Render the simple world with just trees
    spriteBoss.update(true)
    
    # Test that the unrendered, static sprites aren't showing anything
    midRenderExpectations.push([spriteBoss.sprites['Segmented Tree'].imageObject.children.length,1,'static segmented action'])
    midRenderExpectations.push([spriteBoss.sprites['Segmented Tree'].imageObject.children[0].currentFrame,0,'static segmented action'])
    midRenderExpectations.push([spriteBoss.sprites['Segmented Tree'].imageObject.children[0].paused,true,'static segmented action'])
    midRenderExpectations.push([spriteBoss.sprites['Singular Tree'].imageObject.currentFrame,0,'static singular action'])
    midRenderExpectations.push([spriteBoss.sprites['Singular Tree'].imageObject.paused,true,'static singular action'])

    defaultLayer.once 'new-spritesheet', ->
      
      # Now make the world a little more complicated.
      world.thangs = world.thangs.concat [
        # four cardinal ogres, to test movement rotation and placement around a center point.
        {id: 'Ogre N', spriteName: 'Segmented Munchkin', exists: true, pos: {x:0, y:8}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, scaleFactorX: 1.5 }
        {id: 'Ogre W', spriteName: 'Segmented Munchkin', exists: true, pos: {x:-8, y:0}, action: 'move', health: 5, maxHealth: 10, rotation: 0, acts: true, scaleFactorY: 1.5 }
        {id: 'Ogre E', spriteName: 'Segmented Munchkin', exists: true, pos: {x:8, y:0}, action: 'move', health: 5, maxHealth: 10, rotation: Math.PI, acts: true, alpha: 0.5 }
        {id: 'Ogre S', spriteName: 'Segmented Munchkin', exists: true, pos: {x:0, y:-8}, action: 'move', health: 5, maxHealth: 10, rotation: Math.PI/2, acts: true }

        # Set ogres side by side with different render strategies
        {id: 'Singular Ogre', spriteName: 'Singular Munchkin', exists: true, pos: {x:-10, y:-8}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, alpha: 0.5 }
        {id: 'Segmented Ogre', spriteName: 'Segmented Munchkin', exists: true, pos: {x:-8, y:-8}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true }

        # A line of ogres overlapping to test child ordering
        {id: 'Dying Ogre 1', spriteName: 'Segmented Munchkin', exists: true, pos: {x:-14, y:0}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Dying Ogre 2', spriteName: 'Segmented Munchkin', exists: true, pos: {x:-13.5, y:1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Dying Ogre 3', spriteName: 'Segmented Munchkin', exists: true, pos: {x:-13, y:2}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Dying Ogre 4', spriteName: 'Segmented Munchkin', exists: true, pos: {x:-12.5, y:3}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        
        # Throw in a ThangType that contains nested MovieClips
        {id: 'Fangrider', spriteName: 'Fangrider', exists: true, pos: {x:8, y:8}, action: 'move', health: 20, maxHealth: 20, rotation: 0, acts: true }
      ]
      
      _.find(world.thangs, {id: 'Disappearing Tree'}).exists = false
      world.thangMap[thang.id] = thang for thang in world.thangs
      spriteBoss.update(true)

      # Test that the unrendered, animated sprites aren't showing anything
      midRenderExpectations.push([spriteBoss.sprites['Segmented Ogre'].imageObject.children.length,10,'animated segmented action'])
      for child in spriteBoss.sprites['Segmented Ogre'].imageObject.children
        midRenderExpectations.push([child.children[0].currentFrame, 0, 'animated segmented action'])
      midRenderExpectations.push([spriteBoss.sprites['Singular Ogre'].imageObject.currentFrame,0,'animated singular action'])
      midRenderExpectations.push([spriteBoss.sprites['Singular Ogre'].imageObject.paused,true,'animated singular action'])
      
      defaultLayer.once 'new-spritesheet', ->
#        showMe() # Uncomment to display this world when you run any of these tests.
        done()

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

  it 'does not display anything for sprites whose animations or containers have not been rendered yet', ->
    for expectation in midRenderExpectations
      if expectation[0] isnt expectation[1]
        console.error('This type of action display failed:', expectation[2])
      expect(expectation[0]).toBe(expectation[1])
    
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
    expect(spriteBoss.sprites['Ogre N'].imageObject.scaleX).toBe(spriteBoss.sprites['Ogre N'].baseScaleX * 1.5)
    expect(spriteBoss.sprites['Ogre W'].imageObject.scaleY).toBe(spriteBoss.sprites['Ogre N'].baseScaleY * 1.5)

  it 'sets alpha based on thang alpha', ->
    expect(spriteBoss.sprites['Ogre E'].imageObject.alpha).toBe(0.5)
    
  it 'orders sprites in the layer based on thang pos.y\'s', ->
    container = spriteBoss.spriteLayers.Default.container
    l = container.children
    i1 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Dying Ogre 1'))
    i2 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Dying Ogre 2'))
    i3 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Dying Ogre 3'))
    i4 = container.getChildIndex(_.find(container.children, (c) -> c.sprite.thang.id is 'Dying Ogre 4'))
    expect(i1).toBeGreaterThan(i2)
    expect(i2).toBeGreaterThan(i3)
    expect(i3).toBeGreaterThan(i4)

  it 'only contains children Sprites and SpriteContainers whose spritesheet matches the Layer', ->
    defaultLayerContainer = spriteBoss.spriteLayers.Default.container
    for c in defaultLayerContainer.children
      expect(c.spriteSheet).toBe(defaultLayerContainer.spriteSheet)
