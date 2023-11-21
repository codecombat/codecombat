/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LayerAdapter = require('lib/surface/LayerAdapter');
const Lank = require('lib/surface/Lank');
const ThangType = require('models/ThangType');
const treeThangType = new ThangType(require('test/app/fixtures/tree1.thang.type'));
const ogreMunchkinThangType = new ThangType(require('test/app/fixtures/ogre-munchkin-m.thang.type'));
const SpriteBuilder = require('lib/sprites/SpriteBuilder');

describe('LayerAdapter', function() {
  let layer = null;
  beforeEach(function() {
    layer = new LayerAdapter({webGL:true});
    layer.buildAutomatically = false;
    return layer.buildAsync = false;
  });

  it('creates containers for animated actions if set to spriteType=segmented', function() {
    let needle;
    ogreMunchkinThangType.set('spriteType', 'segmented');
    const colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}};
    const sprite = new Lank(ogreMunchkinThangType, {colorConfig});
    layer.addLank(sprite);
    const sheet = layer.renderNewSpriteSheet();
    const key = layer.renderGroupingKey(ogreMunchkinThangType, 'head', colorConfig);
    return expect((needle = key, Array.from(sheet.getAnimations()).includes(needle))).toBe(true);
  });

  it('creates the container for static actions if set to spriteType=segmented', function() {
    let needle;
    treeThangType.set('spriteType', 'segmented');
    const sprite = new Lank(treeThangType);
    layer.addLank(sprite);
    const sheet = layer.renderNewSpriteSheet();
    const key = layer.renderGroupingKey(treeThangType, 'Tree_4');
    return expect((needle = key, Array.from(sheet.getAnimations()).includes(needle))).toBe(true);
  });

  it('creates animations for animated actions if set to spriteType=singular', function() {
    let needle;
    ogreMunchkinThangType.set('spriteType', 'singular');
    const colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}};
    const sprite = new Lank(ogreMunchkinThangType, {colorConfig});
    layer.addLank(sprite);
    const sheet = layer.renderNewSpriteSheet();
    const key = layer.renderGroupingKey(ogreMunchkinThangType, 'idle', colorConfig);
    return expect((needle = key, Array.from(sheet.getAnimations()).includes(needle))).toBe(true);
  });

  it('creates animations for static actions if set to spriteType=singular', function() {
    let needle;
    treeThangType.set('spriteType', 'singular');
    const sprite = new Lank(treeThangType);
    layer.addLank(sprite);
    const sheet = layer.renderNewSpriteSheet();
    const key = layer.renderGroupingKey(treeThangType, 'idle');
    return expect((needle = key, Array.from(sheet.getAnimations()).includes(needle))).toBe(true);
  });

  it('only renders frames used by actions when spriteType=singular', function() {
    const oldDefaults = ThangType.defaultActions;
    ThangType.defaultActions = ['idle']; // uses the move side animation
    ogreMunchkinThangType.set('spriteType', 'singular');
    const colorConfig = {team: {hue: 0, saturation: 1, lightness: 0.5}};
    const sprite = new Lank(ogreMunchkinThangType, {colorConfig});
    layer.addLank(sprite);
    const sheet = layer.renderNewSpriteSheet();
    const key = layer.renderGroupingKey(ogreMunchkinThangType, 'idle', colorConfig);
    const animations = sheet.getAnimations();
    expect(animations.length).toBe(1);
    expect(animations[0]).toBe(key);
    expect(sheet.getNumFrames()).toBe(2); // one idle frame, and the emptiness frame
    return ThangType.defaultActions = oldDefaults;
  });

  it('renders a raster image onto a sheet', function(done) {
    const bootsThangType = new ThangType(require('test/app/fixtures/leather-boots.thang.type'));
    bootsThangType.loadRasterImage();
    bootsThangType.once('raster-image-loaded', function() {
      let needle;
      const sprite = new Lank(bootsThangType);
      layer.addLank(sprite);
      const sheet = layer.renderNewSpriteSheet();
      const key = layer.renderGroupingKey(bootsThangType);
      expect((needle = key, Array.from(sheet.getAnimations()).includes(needle))).toBe(true);
      return done();
      //$('body').attr('class', '').empty().css('background', 'white').append($(sheet._images))
    });
    return bootsThangType.once('raster-image-load-errored', () => // skip this test...
    done());
  });

  it('loads ThangTypes for Lanks that are added to it and need to be loaded', function() {
    const thangType = new ThangType({_id: 1});
    const sprite = new Lank(thangType);
    layer.addLank(sprite);
    expect(layer.numThingsLoading).toBe(1);
    return expect(jasmine.Ajax.requests.count()).toBe(1);
  });

  it('loads raster images for ThangType', function() {
    const bootsThangTypeData = require('test/app/fixtures/leather-boots.thang.type');
    const thangType = new ThangType({_id: 1});
    const sprite = new Lank(thangType);
    layer.addLank(sprite);
    expect(layer.numThingsLoading).toBe(1);
    spyOn(thangType, 'loadRasterImage');
    jasmine.Ajax.requests.sendResponses({'/db/thang.type/1': bootsThangTypeData});
    spyOn(layer, 'renderNewSpriteSheet');
    expect(layer.numThingsLoading).toBe(1);
    expect(thangType.loadRasterImage).toHaveBeenCalled();
    thangType.loadedRaster = true;
    thangType.trigger('raster-image-loaded', thangType);
    expect(layer.numThingsLoading).toBe(0);
    return expect(layer.renderNewSpriteSheet).toHaveBeenCalled();
  });

  it('renders a new SpriteSheet only once everything has loaded', function() {
    const bootsThangTypeData = require('test/app/fixtures/leather-boots.thang.type');
    const thangType1 = new ThangType({_id: 1});
    const thangType2 = new ThangType({_id: 2});
    layer.addLank(new Lank(thangType1));
    expect(layer.numThingsLoading).toBe(1);
    layer.addLank(new Lank(thangType2));
    expect(layer.numThingsLoading).toBe(2);
    spyOn(thangType2, 'loadRasterImage');
    spyOn(layer, '_renderNewSpriteSheet');
    jasmine.Ajax.requests.sendResponses({'/db/thang.type/1': ogreMunchkinThangType.attributes});
    expect(layer.numThingsLoading).toBe(1);
    jasmine.Ajax.requests.sendResponses({'/db/thang.type/2': bootsThangTypeData});
    expect(layer.numThingsLoading).toBe(1);
    expect(layer._renderNewSpriteSheet).not.toHaveBeenCalled();
    expect(thangType2.loadRasterImage).toHaveBeenCalled();
    thangType2.loadedRaster = true;
    thangType2.trigger('raster-image-loaded', thangType2);
    expect(layer.numThingsLoading).toBe(0);
    return expect(layer._renderNewSpriteSheet).toHaveBeenCalled();
  });

  it('recycles *containers* from previous sprite sheets, rather than building repeatedly from raw vector data', function() {
    treeThangType.set('spriteType', 'segmented');
    const sprite = new Lank(treeThangType);
    layer.addLank(sprite);
    spyOn(SpriteBuilder.prototype, 'buildContainerFromStore').and.callThrough();
    for (var i of Array.from(_.range(2))) {
      var sheet = layer.renderNewSpriteSheet();
    }
    return expect(SpriteBuilder.prototype.buildContainerFromStore.calls.count()).toBe(1);
  });

  it('*does not* recycle *containers* from previous sprite sheets when the resolutionFactor has changed', function() {
    treeThangType.set('spriteType', 'segmented');
    const sprite = new Lank(treeThangType);
    layer.addLank(sprite);
    spyOn(SpriteBuilder.prototype, 'buildContainerFromStore').and.callThrough();
    for (var i of Array.from(_.range(2))) {
      layer.resolutionFactor *= 1.1;
      var sheet = layer.renderNewSpriteSheet();
    }
    return expect(SpriteBuilder.prototype.buildContainerFromStore.calls.count()).toBe(2);
  });

  it('recycles *animations* from previous sprite sheets, rather than building repeatedly from raw vector data', function() {
    ogreMunchkinThangType.set('spriteType', 'singular');
    const sprite = new Lank(ogreMunchkinThangType);
    layer.addLank(sprite);
    const numFrameses = [];
    spyOn(SpriteBuilder.prototype, 'buildMovieClip').and.callThrough();
    for (var i of Array.from(_.range(2))) {
      var sheet = layer.renderNewSpriteSheet();
      numFrameses.push(sheet.getNumFrames());
    }

    // this process should not have created any new frames
    expect(numFrameses[0]).toBe(numFrameses[1]);

    // one movie clip made for each raw animation: move (3), attack, die
    return expect(SpriteBuilder.prototype.buildMovieClip.calls.count()).toBe(5);
  });

  return it('*does not* recycles *animations* from previous sprite sheets when the resolutionFactor has changed', function() {
    ogreMunchkinThangType.set('spriteType', 'singular');
    const sprite = new Lank(ogreMunchkinThangType);
    layer.addLank(sprite);
    spyOn(SpriteBuilder.prototype, 'buildMovieClip').and.callThrough();
    for (var i of Array.from(_.range(2))) {
      layer.resolutionFactor *= 1.1;
      var sheet = layer.renderNewSpriteSheet();
    }

    return expect(SpriteBuilder.prototype.buildMovieClip.calls.count()).toBe(10);
  });
});