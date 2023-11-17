LankBoss = require 'lib/surface/LankBoss'
Camera = require 'lib/surface/Camera'
World = require 'lib/world/world'
ThangType = require 'models/ThangType'
GameUIState = require 'models/GameUIState'
createjs = require 'lib/createjs-parts'

treeData = require 'test/app/fixtures/tree1.thang.type'
munchkinData = require 'test/app/fixtures/ogre-munchkin-m.thang.type'
fangriderData = require 'test/app/fixtures/ogre-fangrider.thang.type'
curseData = require 'test/app/fixtures/curse.thang.type'

describe 'LankBoss', ->
  lankBoss = null
  canvas = null
  stage = null
  midRenderExpectations = [] # bit of a hack to move tests which happen mid-initialization into a separate test

  # This suite just creates and renders the stage once, and then has each of the tests
  # check the resulting data for the whole thing, without changing anything.

  init = (done) ->
    return done() if lankBoss
    t = new Date()
    canvas = $('<canvas width="800" height="600"></canvas>')
    camera = new Camera(canvas)

    # Create an initial, simple world with just trees
    world = new World()
    world.thangs = [
      # Set trees side by side with different render strategies
      {id: 'Segmented Tree', spriteName: 'Segmented Tree', exists: true, shape: 'disc', depth: 2, pos: {x:10, y:-8, z: 1}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
      {id: 'Singular Tree', spriteName: 'Singular Tree', exists: true, shape: 'disc', depth: 2, pos: {x:8, y:-8, z: 1}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }

      # Include a tree whose existence will change so we can test removing sprites
      {id: 'Disappearing Tree', spriteName: 'Singular Tree', exists: true, shape: 'disc', depth: 2, pos: {x:0, y:0, z: 1}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
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

    # Build the Stage and LankBoss.
    window.stage = stage = new createjs.StageGL(canvas[0])
    options = {
      camera: camera
      webGLStage: stage
      surfaceTextLayer: new createjs.Container()
      world: world
      thangTypes: thangTypes
      gameUIState: new GameUIState()
    }

    window.lankBoss = lankBoss = new LankBoss(options)

    defaultLayer = lankBoss.layerAdapters.Default
    defaultLayer.buildAsync = false # cause faster

    # Sort of an implicit test. By default, all the default actions are always rendered,
    # but I want to make sure the system can dynamically hear about actions it needs to render for
    # as they are used.
    defaultLayer.defaultActions = ['idle']

    # Render the simple world with just trees
    lankBoss.update(true)

    # Test that the unrendered, static sprites aren't showing anything
    midRenderExpectations.push([lankBoss.lanks['Segmented Tree'].sprite.children.length,1,'static segmented action'])
    midRenderExpectations.push([lankBoss.lanks['Segmented Tree'].sprite.children[0].currentFrame,0,'static segmented action'])
    midRenderExpectations.push([lankBoss.lanks['Segmented Tree'].sprite.children[0].paused,true,'static segmented action'])
    midRenderExpectations.push([lankBoss.lanks['Singular Tree'].sprite.currentFrame,0,'static singular action'])
    midRenderExpectations.push([lankBoss.lanks['Singular Tree'].sprite.paused,true,'static singular action'])

    defaultLayer.once 'new-spritesheet', ->

      # Now make the world a little more complicated.
      world.thangs = world.thangs.concat [
        # four cardinal ogres, to test movement rotation and placement around a center point.
        {id: 'Ogre N', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:0, y:8, z: 1}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, scaleFactorX: 1.5, hudProperties: ['health'] }
        {id: 'Ogre W', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-8, y:0, z: 1}, action: 'move', health: 8, maxHealth: 10, rotation: 0, acts: true, scaleFactorY: 1.5, hudProperties: ['health'] }
        {id: 'Ogre E', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:8, y:0, z: 1}, action: 'move', health: 5, maxHealth: 10, rotation: Math.PI, acts: true, alpha: 0.5, hudProperties: ['health'] }
        {id: 'Ogre S', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:0, y:-8, z: 1}, action: 'move', health: 2, maxHealth: 10, rotation: Math.PI/2, acts: true, hudProperties: ['health'], effectNames: ['curse'] }

        # Set ogres side by side with different render strategies
        {id: 'Singular Ogre', spriteName: 'Singular Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-10, y:-8, z: 1}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, alpha: 0.5 }
        {id: 'Segmented Ogre', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-8, y:-8, z: 1}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true }

        # A line of ogres overlapping to test child ordering
        {id: 'Dying Ogre 1', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-14, y:0, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Dying Ogre 2', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-13.5, y:1, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Dying Ogre 3', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-13, y:2, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }
        {id: 'Dying Ogre 4', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-12.5, y:3, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true }

        # Throw in a ThangType that contains nested MovieClips
        {id: 'Fangrider', spriteName: 'Fangrider', exists: true, shape: 'disc', depth: 2, pos: {x:8, y:8, z: 1}, action: 'move', health: 20, maxHealth: 20, rotation: 0, acts: true, currentEvents: ['aoe-' + JSON.stringify([0, 0, 8, '#00F'])] }
      ]

      _.find(world.thangs, {id: 'Disappearing Tree'}).exists = false
      world.thangMap[thang.id] = thang for thang in world.thangs
      lankBoss.update(true)
      jasmine.Ajax.requests.sendResponses({'/db/thang.type/curse': curseData})

      # Test that the unrendered, animated sprites aren't showing anything
      midRenderExpectations.push([lankBoss.lanks['Segmented Ogre'].sprite.children.length,10,'animated segmented action'])
      for child in lankBoss.lanks['Segmented Ogre'].sprite.children
        midRenderExpectations.push([child.children[0].currentFrame, 0, 'animated segmented action'])
      midRenderExpectations.push([lankBoss.lanks['Singular Ogre'].sprite.currentFrame,0,'animated singular action'])
      midRenderExpectations.push([lankBoss.lanks['Singular Ogre'].sprite.paused,true,'animated singular action'])

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
        if ticks % 20 is 0
          lankBoss.update(true)
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
    expect(lankBoss.lanks['Ogre N'].sprite.currentAnimation).toBe('move_fore')
    expect(lankBoss.lanks['Ogre E'].sprite.currentAnimation).toBe('move_side')
    expect(lankBoss.lanks['Ogre W'].sprite.currentAnimation).toBe('move_side')
    expect(lankBoss.lanks['Ogre S'].sprite.currentAnimation).toBe('move_back')

    expect(lankBoss.lanks['Ogre E'].sprite.scaleX).toBeLessThan(0)
    expect(lankBoss.lanks['Ogre W'].sprite.scaleX).toBeGreaterThan(0)

  it 'positions sprites according to thang pos', ->
    expect(lankBoss.lanks['Ogre N'].sprite.x).toBe(0)
    expect(lankBoss.lanks['Ogre N'].sprite.y).toBeCloseTo(-60)
    expect(lankBoss.lanks['Ogre E'].sprite.x).toBeCloseTo(80)
    expect(lankBoss.lanks['Ogre E'].sprite.y).toBe(0)
    expect(lankBoss.lanks['Ogre W'].sprite.x).toBe(-80)
    expect(lankBoss.lanks['Ogre W'].sprite.y).toBeCloseTo(0)
    expect(lankBoss.lanks['Ogre S'].sprite.x).toBe(0)
    expect(lankBoss.lanks['Ogre S'].sprite.y).toBeCloseTo(60)

  it 'scales sprites according to thang scaleFactorX and scaleFactorY', ->
    expect(lankBoss.lanks['Ogre N'].sprite.scaleX).toBe(lankBoss.lanks['Ogre N'].sprite.baseScaleX * 1.5)
    expect(lankBoss.lanks['Ogre W'].sprite.scaleY).toBe(lankBoss.lanks['Ogre N'].sprite.baseScaleY * 1.5)

  it 'sets alpha based on thang alpha', ->
    expect(lankBoss.lanks['Ogre E'].sprite.alpha).toBe(0.5)

  it 'orders sprites in the layer based on thang pos.y\'s', ->
    container = lankBoss.layerAdapters.Default.container
    l = container.children
    i1 = container.getChildIndex(_.find(container.children, (c) -> c.lank.thang.id is 'Dying Ogre 1'))
    i2 = container.getChildIndex(_.find(container.children, (c) -> c.lank.thang.id is 'Dying Ogre 2'))
    i3 = container.getChildIndex(_.find(container.children, (c) -> c.lank.thang.id is 'Dying Ogre 3'))
    i4 = container.getChildIndex(_.find(container.children, (c) -> c.lank.thang.id is 'Dying Ogre 4'))
    expect(i1).toBeGreaterThan(i2)
    expect(i2).toBeGreaterThan(i3)
    expect(i3).toBeGreaterThan(i4)
