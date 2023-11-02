/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LayerAdapter = require('lib/surface/LayerAdapter');
const SegmentedSprite = require('lib/surface/SegmentedSprite');
const Lank = require('lib/surface/Lank');
const ThangType = require('models/ThangType');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const ogreMunchkinThangType = new ThangType(require('test/app/fixtures/ogre-munchkin-m.thang.type'));
const ogreFangriderThangType = new ThangType(require('test/app/fixtures/ogre-fangrider.thang.type'));
const treeThangType = new ThangType(require('test/app/fixtures/tree1.thang.type'));
const scaleTestUtils = require('./scale-testing-utils');
const createjs = require('lib/createjs-parts');

describe('SegmentedSprite', function() {
  let segmentedSprite = null;
  let stage = null;

  const showMe = function() {
    const canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white');
    $('body').append(canvas);
    stage = new createjs.Stage(canvas[0]);
    stage.addChild(segmentedSprite);
    const scale = 3;
    stage.scaleX = (stage.scaleY = scale);
    stage.regX = -300 / scale;
    stage.regY = -200 / scale;
    window.stage = stage;

    let ticks = 0;
    const listener = {
      handleEvent() {
        if (ticks >= 100) { return; }
        ticks += 1;
        segmentedSprite.tick(arguments[0].delta);
        return stage.update();
      }
    };
    return createjs.Ticker.addEventListener("tick", listener);
  };

  describe('with Tree ThangType', function() {
    beforeEach(function() {
      const layer = new LayerAdapter({webGL:true, name:'Default'});
      layer.buildAutomatically = false;
      layer.buildAsync = false;
      treeThangType.markToRevert();
      treeThangType.set('spriteType', 'segmented');
      const sprite = new Lank(treeThangType);
      layer.addLank(sprite);
      const sheet = layer.renderNewSpriteSheet();
      const prefix = layer.renderGroupingKey(treeThangType) + '.';
      return window.segmentedSprite = (segmentedSprite = new SegmentedSprite(sheet, treeThangType, prefix));
    });

    it('scales rendered containers to the size of the source container', function() {
      // build a movie clip, put it on top of the segmented sprite and make sure
      // they both 'hit' at the same time.

      segmentedSprite.gotoAndStop('idle');
      const builder = new SpriteBuilder(treeThangType);
      const container = builder.buildContainerFromStore('Tree_4');
      container.scaleX = (container.scaleY = 0.3);
      container.regX = 59;
      container.regY = 100;
      showMe();
      stage.addChild(container);
      stage.update();
      const hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40));
      expect(hitRate).toBeGreaterThan(0.92);
      return $('canvas').remove();
    });

    return it('scales placeholder containers to the size of the source container', function() {
      // build a movie clip, put it on top of the segmented sprite and make sure
      // they both 'hit' at the same time.

      segmentedSprite.usePlaceholders = true;
      segmentedSprite.gotoAndStop('idle');
      const builder = new SpriteBuilder(treeThangType);
      const container = builder.buildContainerFromStore('Tree_4');
      container.scaleX = (container.scaleY = 0.3);
      container.regX = 59;
      container.regY = 100;
      showMe();
      stage.addChild(container);
      stage.update();
      const hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40));
      expect(hitRate).toBeGreaterThan(0.73);
      return $('canvas').remove();
    });
  });

  describe('with Ogre Munchkin ThangType', function() {
    beforeEach(function() {
      const layer = new LayerAdapter({webGL:true, name:'Default'});
      layer.buildAutomatically = false;
      layer.buildAsync = false;
      ogreMunchkinThangType.markToRevert();
      ogreMunchkinThangType.set('spriteType', 'segmented');
      const actions = ogreMunchkinThangType.getActions();

      // couple extra actions for doing some tests
      actions.littledance = {animation:'enemy_small_move_side',framerate:1, frames:'0,6,2,6,2,8,0', name: 'littledance'};
      actions.onestep = {animation:'enemy_small_move_side', loops: false, name:'onestep'};
      actions.head = {container:'head', name:'head'};

      const colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}};
      const sprite = new Lank(ogreMunchkinThangType, {colorConfig});
      layer.addLank(sprite);
      const sheet = layer.renderNewSpriteSheet();
      const prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.';
      return window.segmentedSprite = (segmentedSprite = new SegmentedSprite(sheet, ogreMunchkinThangType, prefix));
    });

    afterEach(() => ogreMunchkinThangType.revert());

    it('has gotoAndPlay, gotoAndStop, currentAnimation, and paused like a MovieClip or Sprite', function() {
      segmentedSprite.gotoAndPlay('move_fore');
      expect(segmentedSprite.baseMovieClip).toBeDefined();
      expect(segmentedSprite.paused).toBe(false);
      segmentedSprite.gotoAndStop('move_fore');
      expect(segmentedSprite.paused).toBe(true);
      return expect(segmentedSprite.currentAnimation).toBe('move_fore');
    });

    it('has a tick function which moves the animation forward', function() {
      segmentedSprite.gotoAndPlay('attack');
      segmentedSprite.tick(100); // one hundred milliseconds
      return expect(segmentedSprite.baseMovieClip.currentFrame).toBe((segmentedSprite.framerate*100)/1000);
    });

    it('will interpolate between frames of a custom frame set', function() {
      segmentedSprite.gotoAndPlay('littledance');
      segmentedSprite.tick(1000);
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(6);
      segmentedSprite.tick(1000);
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(2);
      segmentedSprite.tick(500);
      expect(segmentedSprite.baseMovieClip.currentFrame).toBe(4);
      segmentedSprite.tick(500);
      return expect(segmentedSprite.baseMovieClip.currentFrame).toBe(6);
    });

    it('emits animationend for animations where loops is false and there is no goesTo', function(done) {
      let fired = false;
      segmentedSprite.gotoAndPlay('onestep');
      segmentedSprite.on('animationend', () => fired = true);
      segmentedSprite.tick(1000);
      return _.defer(function() { // because the event is deferred
        expect(fired).toBe(true);
        return done();
      });
    });

    it('scales rendered animations like a MovieClip', function() {
      // build a movie clip, put it on top of the segmented sprite and make sure
      // they both 'hit' at the same time.

      segmentedSprite.gotoAndStop('idle');
      const builder = new SpriteBuilder(ogreMunchkinThangType);
      const movieClip = builder.buildMovieClip('enemy_small_move_side');
      movieClip.scaleX = (movieClip.scaleY = 0.3);
      movieClip.regX = 285;
      movieClip.regY = 300;
      movieClip.stop();
      showMe();
      stage.addChild(movieClip);

      stage.update();
      const hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-10, -30, 25, 35));
      expect(hitRate).toBeGreaterThan(0.91);
      expect(segmentedSprite.baseScaleX).toBe(0.3);
      expect(segmentedSprite.baseScaleY).toBe(0.3);
      return $('canvas').remove();
    });

    return it('scales placeholder animations like a MovieClip', function() {
      segmentedSprite.usePlaceholders = true;
      segmentedSprite.gotoAndStop('idle');
      const builder = new SpriteBuilder(ogreMunchkinThangType);
      const movieClip = builder.buildMovieClip('enemy_small_move_side');
      movieClip.scaleX = (movieClip.scaleY = 0.3);
      movieClip.regX = 285;
      movieClip.regY = 300;
      movieClip.stop();
      showMe();
      stage.addChild(movieClip);
      stage.update();
      const hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-10, -30, 25, 35));
      expect(hitRate).toBeGreaterThan(0.96);
      return $('canvas').remove();
    });
  });

  return describe('with Ogre Fangrider ThangType', function() {
    beforeEach(function() {
      const layer = new LayerAdapter({webGL:true});
      layer.buildAutomatically = false;
      layer.buildAsync = false;
      ogreFangriderThangType.markToRevert();
      ogreFangriderThangType.set('spriteType', 'segmented');
      const colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}};
      const sprite = new Lank(ogreFangriderThangType, {colorConfig});
      layer.addLank(sprite);
      const sheet = layer.renderNewSpriteSheet();
      const prefix = layer.renderGroupingKey(ogreFangriderThangType, null, colorConfig) + '.';
      return window.segmentedSprite = (segmentedSprite = new SegmentedSprite(sheet, ogreFangriderThangType, prefix));
    });

    afterEach(() => ogreFangriderThangType.revert());

    it('synchronizes animations with child movie clips properly', function() {
      segmentedSprite.gotoAndPlay('die');
      segmentedSprite.tick(100); // one hundred milliseconds
      const expectedFrame = (segmentedSprite.framerate*100)/1000;
      expect(segmentedSprite.currentFrame).toBe(expectedFrame);
      return Array.from(segmentedSprite.childMovieClips).map((movieClip) =>
        expect(movieClip.currentFrame).toBe(expectedFrame));
    });

    it('does not include shapes from the original animation', function() {
      segmentedSprite.gotoAndPlay('attack');
      segmentedSprite.tick(230);
      return Array.from(segmentedSprite.children).map((child) =>
        expect(_.isString(child)).toBe(false));
    });

    return it('maintains the right number of shapes', function() {
      segmentedSprite.gotoAndPlay('idle');
      const lengths = [];
      return (() => {
        const result = [];
        for (var i of Array.from(_.range(10))) {
          segmentedSprite.tick(10);
          result.push(expect(segmentedSprite.children.length).toBe(20));
        }
        return result;
      })();
    });
  });
});
