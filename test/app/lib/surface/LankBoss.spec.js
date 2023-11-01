/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LankBoss = require('lib/surface/LankBoss');
const Camera = require('lib/surface/Camera');
const World = require('lib/world/world');
const ThangType = require('models/ThangType');
const GameUIState = require('models/GameUIState');
const createjs = require('lib/createjs-parts');

const treeData = require('test/app/fixtures/tree1.thang.type');
const munchkinData = require('test/app/fixtures/ogre-munchkin-m.thang.type');
const fangriderData = require('test/app/fixtures/ogre-fangrider.thang.type');
const curseData = require('test/app/fixtures/curse.thang.type');

describe('LankBoss', function() {
  let lankBoss = null;
  let canvas = null;
  let stage = null;
  const midRenderExpectations = []; // bit of a hack to move tests which happen mid-initialization into a separate test

  // This suite just creates and renders the stage once, and then has each of the tests
  // check the resulting data for the whole thing, without changing anything.

  const init = function(done) {
    let thang;
    if (lankBoss) { return done(); }
    const t = new Date();
    canvas = $('<canvas width="800" height="600"></canvas>');
    const camera = new Camera(canvas);

    // Create an initial, simple world with just trees
    const world = new World();
    world.thangs = [
      // Set trees side by side with different render strategies
      {id: 'Segmented Tree', spriteName: 'Segmented Tree', exists: true, shape: 'disc', depth: 2, pos: {x:10, y:-8, z: 1}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true },
      {id: 'Singular Tree', spriteName: 'Singular Tree', exists: true, shape: 'disc', depth: 2, pos: {x:8, y:-8, z: 1}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true },

      // Include a tree whose existence will change so we can test removing sprites
      {id: 'Disappearing Tree', spriteName: 'Singular Tree', exists: true, shape: 'disc', depth: 2, pos: {x:0, y:0, z: 1}, action: 'idle', health: 20, maxHealth: 20, rotation: Math.PI/2, acts: true }
    ];
    world.thangMap = {};
    for (thang of Array.from(world.thangs)) { world.thangMap[thang.id] = thang; }

    // Set up thang types. Mix renderStrategies.
    const fangrider = new ThangType($.extend({}, fangriderData, {spriteType:'segmented', name:'Fangrider', slug:'fangrider'}));
    const segmentedMunchkin = new ThangType($.extend({}, munchkinData, {spriteType:'segmented', name:'Segmented Munchkin', slug:'segmented-munchkin'}));
    const singularMunchkin = new ThangType($.extend({}, munchkinData, {spriteType:'singular', name:'Singular Munchkin', slug:'singular-munchkin'}));
    const segmentedTree = new ThangType($.extend({}, treeData, {spriteType:'segmented', name:'Segmented Tree', slug: 'segmented-tree'}));
    const singularTree = new ThangType($.extend({}, treeData, {spriteType:'singular', name:'Singular Tree', slug: 'singular-tree'}));

    const thangTypes = [fangrider, segmentedMunchkin, singularMunchkin, segmentedTree, singularTree];

    // Build the Stage and LankBoss.
    window.stage = (stage = new createjs.StageGL(canvas[0]));
    const options = {
      camera,
      webGLStage: stage,
      surfaceTextLayer: new createjs.Container(),
      world,
      thangTypes,
      gameUIState: new GameUIState()
    };

    window.lankBoss = (lankBoss = new LankBoss(options));

    const defaultLayer = lankBoss.layerAdapters.Default;
    defaultLayer.buildAsync = false; // cause faster

    // Sort of an implicit test. By default, all the default actions are always rendered,
    // but I want to make sure the system can dynamically hear about actions it needs to render for
    // as they are used.
    defaultLayer.defaultActions = ['idle'];

    // Render the simple world with just trees
    lankBoss.update(true);

    // Test that the unrendered, static sprites aren't showing anything
    midRenderExpectations.push([lankBoss.lanks['Segmented Tree'].sprite.children.length,1,'static segmented action']);
    midRenderExpectations.push([lankBoss.lanks['Segmented Tree'].sprite.children[0].currentFrame,0,'static segmented action']);
    midRenderExpectations.push([lankBoss.lanks['Segmented Tree'].sprite.children[0].paused,true,'static segmented action']);
    midRenderExpectations.push([lankBoss.lanks['Singular Tree'].sprite.currentFrame,0,'static singular action']);
    midRenderExpectations.push([lankBoss.lanks['Singular Tree'].sprite.paused,true,'static singular action']);

    return defaultLayer.once('new-spritesheet', function() {

      // Now make the world a little more complicated.
      world.thangs = world.thangs.concat([
        // four cardinal ogres, to test movement rotation and placement around a center point.
        {id: 'Ogre N', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:0, y:8, z: 1}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, scaleFactorX: 1.5, hudProperties: ['health'] },
        {id: 'Ogre W', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-8, y:0, z: 1}, action: 'move', health: 8, maxHealth: 10, rotation: 0, acts: true, scaleFactorY: 1.5, hudProperties: ['health'] },
        {id: 'Ogre E', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:8, y:0, z: 1}, action: 'move', health: 5, maxHealth: 10, rotation: Math.PI, acts: true, alpha: 0.5, hudProperties: ['health'] },
        {id: 'Ogre S', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:0, y:-8, z: 1}, action: 'move', health: 2, maxHealth: 10, rotation: Math.PI/2, acts: true, hudProperties: ['health'], effectNames: ['curse'] },

        // Set ogres side by side with different render strategies
        {id: 'Singular Ogre', spriteName: 'Singular Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-10, y:-8, z: 1}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true, alpha: 0.5 },
        {id: 'Segmented Ogre', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-8, y:-8, z: 1}, action: 'move', health: 10, maxHealth: 10, rotation: -Math.PI/2, acts: true },

        // A line of ogres overlapping to test child ordering
        {id: 'Dying Ogre 1', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-14, y:0, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true },
        {id: 'Dying Ogre 2', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-13.5, y:1, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true },
        {id: 'Dying Ogre 3', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-13, y:2, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true },
        {id: 'Dying Ogre 4', spriteName: 'Segmented Munchkin', exists: true, shape: 'disc', depth: 2, pos: {x:-12.5, y:3, z: 1}, action: 'die', health: 5, maxHealth: 10, rotation: 0, acts: true },

        // Throw in a ThangType that contains nested MovieClips
        {id: 'Fangrider', spriteName: 'Fangrider', exists: true, shape: 'disc', depth: 2, pos: {x:8, y:8, z: 1}, action: 'move', health: 20, maxHealth: 20, rotation: 0, acts: true, currentEvents: ['aoe-' + JSON.stringify([0, 0, 8, '#00F'])] }
      ]);

      _.find(world.thangs, {id: 'Disappearing Tree'}).exists = false;
      for (thang of Array.from(world.thangs)) { world.thangMap[thang.id] = thang; }
      lankBoss.update(true);
      jasmine.Ajax.requests.sendResponses({'/db/thang.type/curse': curseData});

      // Test that the unrendered, animated sprites aren't showing anything
      midRenderExpectations.push([lankBoss.lanks['Segmented Ogre'].sprite.children.length,10,'animated segmented action']);
      for (var child of Array.from(lankBoss.lanks['Segmented Ogre'].sprite.children)) {
        midRenderExpectations.push([child.children[0].currentFrame, 0, 'animated segmented action']);
      }
      midRenderExpectations.push([lankBoss.lanks['Singular Ogre'].sprite.currentFrame,0,'animated singular action']);
      midRenderExpectations.push([lankBoss.lanks['Singular Ogre'].sprite.paused,true,'animated singular action']);

      return defaultLayer.once('new-spritesheet', () => //        showMe() # Uncomment to display this world when you run any of these tests.
      done());
    });
  };

  beforeEach(done => init(done));

  const showMe = function() {
    canvas.css('position', 'absolute').css('index', 1000).css('background', 'white');
    $('body').append(canvas);

    let ticks = 0;
    const listener = {
      handleEvent() {
        if (ticks >= 100) { return; }
        ticks += 1;
        if ((ticks % 20) === 0) {
          lankBoss.update(true);
        }
        return stage.update();
      }
    };
    createjs.Ticker.addEventListener("tick", listener);
    return $('body').append($('<div style="position: absolute; top: 295px; left: 395px; height: 10px; width: 10px; background: red;"></div>'));
  };

  it('does not display anything for sprites whose animations or containers have not been rendered yet', () => (() => {
    const result = [];
    for (var expectation of Array.from(midRenderExpectations)) {
      if (expectation[0] !== expectation[1]) {
        console.error('This type of action display failed:', expectation[2]);
      }
      result.push(expect(expectation[0]).toBe(expectation[1]));
    }
    return result;
  })());

  it('rotates and animates sprites according to thang rotation', function() {
    expect(lankBoss.lanks['Ogre N'].sprite.currentAnimation).toBe('move_fore');
    expect(lankBoss.lanks['Ogre E'].sprite.currentAnimation).toBe('move_side');
    expect(lankBoss.lanks['Ogre W'].sprite.currentAnimation).toBe('move_side');
    expect(lankBoss.lanks['Ogre S'].sprite.currentAnimation).toBe('move_back');

    expect(lankBoss.lanks['Ogre E'].sprite.scaleX).toBeLessThan(0);
    return expect(lankBoss.lanks['Ogre W'].sprite.scaleX).toBeGreaterThan(0);
  });

  it('positions sprites according to thang pos', function() {
    expect(lankBoss.lanks['Ogre N'].sprite.x).toBe(0);
    expect(lankBoss.lanks['Ogre N'].sprite.y).toBeCloseTo(-60);
    expect(lankBoss.lanks['Ogre E'].sprite.x).toBeCloseTo(80);
    expect(lankBoss.lanks['Ogre E'].sprite.y).toBe(0);
    expect(lankBoss.lanks['Ogre W'].sprite.x).toBe(-80);
    expect(lankBoss.lanks['Ogre W'].sprite.y).toBeCloseTo(0);
    expect(lankBoss.lanks['Ogre S'].sprite.x).toBe(0);
    return expect(lankBoss.lanks['Ogre S'].sprite.y).toBeCloseTo(60);
  });

  it('scales sprites according to thang scaleFactorX and scaleFactorY', function() {
    expect(lankBoss.lanks['Ogre N'].sprite.scaleX).toBe(lankBoss.lanks['Ogre N'].sprite.baseScaleX * 1.5);
    return expect(lankBoss.lanks['Ogre W'].sprite.scaleY).toBe(lankBoss.lanks['Ogre N'].sprite.baseScaleY * 1.5);
  });

  it('sets alpha based on thang alpha', () => expect(lankBoss.lanks['Ogre E'].sprite.alpha).toBe(0.5));

  return it('orders sprites in the layer based on thang pos.y\'s', function() {
    const {
      container
    } = lankBoss.layerAdapters.Default;
    const l = container.children;
    const i1 = container.getChildIndex(_.find(container.children, c => c.lank.thang.id === 'Dying Ogre 1'));
    const i2 = container.getChildIndex(_.find(container.children, c => c.lank.thang.id === 'Dying Ogre 2'));
    const i3 = container.getChildIndex(_.find(container.children, c => c.lank.thang.id === 'Dying Ogre 3'));
    const i4 = container.getChildIndex(_.find(container.children, c => c.lank.thang.id === 'Dying Ogre 4'));
    expect(i1).toBeGreaterThan(i2);
    expect(i2).toBeGreaterThan(i3);
    return expect(i3).toBeGreaterThan(i4);
  });
});
