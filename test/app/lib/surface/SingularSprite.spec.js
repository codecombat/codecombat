/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LayerAdapter = require('lib/surface/LayerAdapter');
const SingularSprite = require('lib/surface/SingularSprite');
const Lank = require('lib/surface/Lank');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const ThangType = require('models/ThangType');
const ogreMunchkinThangType = new ThangType(require('test/app/fixtures/ogre-munchkin-m.thang.type'));
const treeThangType = new ThangType(require('test/app/fixtures/tree1.thang.type'));
const scaleTestUtils = require('./scale-testing-utils');
const createjs = require('lib/createjs-parts');

describe('SingularSprite', function() {
  let singularSprite = null;
  let stage = null;

  const showMe = function() {
    const canvas = $('<canvas width="600" height="400"></canvas>').css('position', 'absolute').css('index', 1000).css('background', 'white');
    $('body').append(canvas);
    stage = new createjs.Stage(canvas[0]);
    stage.addChild(singularSprite);
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
        return stage.update();
      }
    };
    return createjs.Ticker.addEventListener("tick", listener);
  };

  afterEach(function() {
    const g = new createjs.Graphics();
    g.beginFill(createjs.Graphics.getRGB(64,255,64,0.7));
    g.drawCircle(0, 0, 1);
    const s = new createjs.Shape(g);
    return stage.addChild(s);
  });

  describe('with Tree ThangType', function() {
    beforeEach(function() {
      const layer = new LayerAdapter({webGL:true, name:'Default'});
      layer.buildAutomatically = false;
      layer.buildAsync = false;
      treeThangType.markToRevert();
      treeThangType.set('spriteType', 'singular');
      const sprite = new Lank(treeThangType);
      layer.addLank(sprite);
      const sheet = layer.renderNewSpriteSheet();
      const prefix = layer.renderGroupingKey(treeThangType) + '.';
      window.singularSprite = (singularSprite = new SingularSprite(sheet, treeThangType, prefix));
      singularSprite.x = 0;
      return singularSprite.y = 0;
    });

    it('scales rendered containers to the size of the source container, taking into account ThangType scaling', function() {
      // build a movie clip, put it on top of the singular sprite and make sure
      // they both 'hit' at the same time.

      singularSprite.gotoAndStop('idle');
      const builder = new SpriteBuilder(treeThangType);
      const container = builder.buildContainerFromStore('Tree_4');
      container.regX = 59;
      container.regY = 100;
      container.scaleX = (container.scaleY = 0.3);
      showMe();
      stage.addChild(container);
      stage.update();
      const hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40));
      return expect(hitRate).toBeGreaterThan(0.92);
    });
//      $('canvas').remove()

    return it('scales placeholder containers to the size of the source container, taking into account ThangType scaling', function() {
      // build a movie clip, put it on top of the singular sprite and make sure
      // they both 'hit' at the same time.

      singularSprite.usePlaceholders = true;
      singularSprite.gotoAndStop('idle');
      const builder = new SpriteBuilder(treeThangType);
      const container = builder.buildContainerFromStore('Tree_4');
      container.regX = 59;
      container.regY = 100;
      container.scaleX = (container.scaleY = 0.3);
      showMe();
      stage.addChild(container);
      stage.update();
      const hitRate = scaleTestUtils.hitTest(stage, new createjs.Rectangle(-15, -30, 35, 40));
      return expect(hitRate).toBeGreaterThan(0.73);
    });
  });
//      $('canvas').remove()

  return describe('with Ogre Munchkin ThangType', function() {
    beforeEach(function() {
      const layer = new LayerAdapter({webGL:true, name:'Default'});
      layer.buildAutomatically = false;
      layer.buildAsync = false;
      ogreMunchkinThangType.markToRevert();
      ogreMunchkinThangType.set('spriteType', 'singular');
      const actions = ogreMunchkinThangType.getActions();

      const colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}};
      const sprite = new Lank(ogreMunchkinThangType, {colorConfig});
      layer.addLank(sprite);
      const sheet = layer.renderNewSpriteSheet();
      const prefix = layer.renderGroupingKey(ogreMunchkinThangType, null, colorConfig) + '.';
      return window.singularSprite = (singularSprite = new SingularSprite(sheet, ogreMunchkinThangType, prefix));
    });

    afterEach(() => ogreMunchkinThangType.revert());

    it('has the same interface as Sprite for animation', function() {
      singularSprite.gotoAndPlay('move_fore');
      return singularSprite.gotoAndStop('attack');
    });

    it('scales rendered animations like a MovieClip, taking into account ThangType scaling', function() {
      // build a movie clip, put it on top of the segmented sprite and make sure
      // they both 'hit' at the same time.

      singularSprite.gotoAndStop('idle');
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
      return $('canvas').remove();
    });

    return it('scales placeholder animations like a MovieClip, taking into account ThangType scaling', function() {
      // build a movie clip, put it on top of the segmented sprite and make sure
      // they both 'hit' at the same time.

      singularSprite.usePlaceholders = true;
      singularSprite.gotoAndStop('idle');
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
      expect(hitRate).toBeGreaterThan(0.71);
      return $('canvas').remove();
    });
  });
});
