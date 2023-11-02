/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
/*
  * SpriteStage (WebGL Canvas)
  ** Land texture
  ** Ground-based selection/target marks, range radii
  ** Walls/obstacles
  ** Paths and target pieces (and ghosts?)
  ** Normal Thangs, bots, wizards (z-indexing based on World-determined sprite.thang.pos.z/y, mainly, instead of sprite-map-determined sprite.z, which we rename to... something)
  ** Above-thang marks (blood, highlight) and health bars

  * Stage (Regular Canvas)
  ** Camera border
  ** surfaceTextLayer (speech, names)
  ** screenLayer
  *** Letterbox
  **** Letterbox top and bottom
  *** FPS display, maybe grid axis labels, coordinate hover

  ** Grid lines--somewhere--we will figure it out, do not really need it at first
*/

let LayerAdapter;
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const CocoClass = require('core/CocoClass');
const SegmentedSprite = require('./SegmentedSprite');
const SingularSprite = require('./SingularSprite');
const RasterAtlasSprite = require('ozaria/engine/surface/RasterAtlasSprite');
const ThangType = require('models/ThangType');
const createjs = require('lib/createjs-parts');
const utils = require('core/utils');
const { log, startTimer } = require('ozaria/site/common/logger');

const NEVER_RENDER_ANYTHING = false; // set to true to test placeholders

module.exports = (LayerAdapter = (LayerAdapter = (function() {
  LayerAdapter = class LayerAdapter extends CocoClass {
    static initClass() {
  
      // Intermediary between a Surface Stage and a top-level static normal Container (used to also do hot-swapped WebGL SpriteContainer).
      // It handles zooming in different ways and, if webGL, creating and assigning spriteSheets.
  
      this.TRANSFORM_SURFACE = 'surface';  // Layer moves/scales/zooms with the Surface of the World
      this.TRANSFORM_SURFACE_TEXT = 'surface_text';  // Layer moves with the Surface but is size-independent
      this.TRANSFORM_SCREEN = 'screen';  // Layer stays fixed to the screen
  
      // WebGL properties
      this.prototype.actionRenderState = null;
      this.prototype.needToRerender = false;
      this.prototype.toRenderBundles = null;
      this.prototype.willRender = false;
      this.prototype.buildAutomatically = true;
      this.prototype.buildAsync = true;
      this.prototype.resolutionFactor = SPRITE_RESOLUTION_FACTOR;
      this.prototype.numThingsLoading = 0;
      this.prototype.lanks = null;
      this.prototype.labels = null;
      this.prototype.spriteSheet = null;
      this.prototype.container = null;
      this.prototype.customGraphics = null;
  
      this.prototype.subscriptions =
        {'camera:zoom-updated': 'onZoomUpdated'};
    }

    constructor(options) {
      super();
      if (options == null) { options = {}; }
      this.name = options.name != null ? options.name : 'Unnamed';
      this.defaultSpriteType = this.name === 'Default' ? 'segmented' : 'singular';
      this.customGraphics = {};
      this.layerPriority = options.layerPriority != null ? options.layerPriority : 0;
      this.transformStyle = options.transform != null ? options.transform : LayerAdapter.TRANSFORM_SURFACE;
      this.camera = options.camera;
      this.updateLayerOrder = _.throttle(this.updateLayerOrder, 1000 / 30);  // Don't call multiple times in one frame; 30 FPS is probably good enough
      this.lanks = [];
      this.labels = [];

      if (utils.isOzaria) {
        this.totalTimeSpentRendering = 0;

        // Explicitly setting class as non reactive for performance benefit.
        Vue.nonreactive(this);

        this.reportRenderTime = _.debounce(
          () => {
            if ((this.totalTimeSpentRendering !== 0) && (Math.random() < 0.01)) {
              return log(
                'LayerAdapter Render Time', {
                  totalTimeSpentRendering: this.totalTimeSpentRendering,
                  name: this.name
                }
              );
            }
          },
          500
        );
      }

      this.webGL = !!options.webGL;
      if (this.webGL) {
        this.initializing = true;
        this.spriteSheet = this._renderNewSpriteSheet(false); // builds an empty spritesheet
        this.container = new createjs.Container(this.spriteSheet);
        this.actionRenderState = {};
        this.toRenderBundles = [];
        this.initializing = false;

      } else {
        this.container = new createjs.Container();
      }

      if (utils.isOzaria) {
        // Explicitly setting class as non reactive for performance benefit.
        Vue.nonreactive(this.container);
      }
    }

    toString() { return `<Layer ${this.layerPriority}: ${this.name}>`; }

    //- Layer ordering

    updateLayerOrder() {
      if (this.destroyed) { return; }
      return this.container.sortChildren(this.layerOrderComparator);
    }

    layerOrderComparator(a, b) {
      // Optimize
      let aLank, aPos, bLank, bPos;
      const alp = a.layerPriority || 0;
      const blp = b.layerPriority || 0;
      if (alp !== blp) { return alp - blp; }
      // TODO: remove this z stuff
      let az = a.z || 1000;
      let bz = b.z || 1000;
      if (aLank = a.lank) {
        let aThang;
        if (aThang = aLank.thang) {
          aPos = aThang.pos;
          if (utils.isCodeCombat && (aThang.health < 0) && (aThang.pos.z <= (aThang.depth / 2))) {
            // Nice for not being knee deep in the dead, just not nice for ogres flying behind trees when exploded
            --az;
          }
        }
      }
      if (bLank = b.lank) {
        let bThang;
        if (bThang = bLank.thang) {
          bPos = bThang.pos;
          if ((bThang.health < 0) && (bThang.pos.z <= (bThang.depth / 2))) {
            --bz;
          }
        }
      }
      if (az === bz) {
        if (!aPos || !bPos) { return 0; }
        return (bPos.y - aPos.y) || (bPos.x - aPos.x);
      }
      return az - bz;
    }

    //- Zoom updating

    onZoomUpdated(e) {
      if (e.camera !== this.camera) { return; }
      if ([LayerAdapter.TRANSFORM_SURFACE, LayerAdapter.TRANSFORM_SURFACE_TEXT].includes(this.transformStyle)) {
        const change = this.container.scaleX / e.zoom;
        this.container.scaleX = (this.container.scaleY = e.zoom);
        if (this.webGL) {
          this.container.scaleX *= this.camera.canvasScaleFactorX;
          this.container.scaleY *= this.camera.canvasScaleFactorY;
        }
        this.container.regX = e.surfaceViewport.x;
        this.container.regY = e.surfaceViewport.y;
        if (this.transformStyle === LayerAdapter.TRANSFORM_SURFACE_TEXT) {
          return (() => {
            const result = [];
            for (var child of Array.from(this.container.children)) {
              if (child.skipScaling) { continue; }
              child.scaleX *= change;
              result.push(child.scaleY *= change);
            }
            return result;
          })();
        }
      }
    }

    //- Container-like child functions

    addChild(...children) {
      this.container.addChild(...Array.from(children || []));
      if (this.transformStyle === LayerAdapter.TRANSFORM_SURFACE_TEXT) {
        return (() => {
          const result = [];
          for (var child of Array.from(children)) {
            if (child.skipScaling) { continue; }
            child.scaleX /= this.container.scaleX;
            result.push(child.scaleY /= this.container.scaleY);
          }
          return result;
        })();
      }
    }

    removeChild(...children) {
      this.container.removeChild(...Array.from(children || []));
      // TODO: Do we actually need to scale children that were removed?
      if (this.transformStyle === LayerAdapter.TRANSFORM_SURFACE_TEXT) {
        return (() => {
          const result = [];
          for (var child of Array.from(children)) {
            child.scaleX *= this.container.scaleX;
            result.push(child.scaleY *= this.container.scaleY);
          }
          return result;
        })();
      }
    }

    //- Adding, removing children for WebGL layers.

    addLank(lank) {
      lank.options.resolutionFactor = this.resolutionFactor;
      lank.layer = this;
      this.listenTo(lank, 'action-needs-render', this.onActionNeedsRender);
      this.lanks.push(lank);
      if (!utils.getQueryVariable('jitSpritesheets')) { lank.thangType.initPrerenderedSpriteSheets(); }
      const prerenderedSpriteSheet = lank.thangType.getPrerenderedSpriteSheet(lank.options.colorConfig, this.defaultSpriteType);
      if (prerenderedSpriteSheet != null) {
        prerenderedSpriteSheet.markToLoad();
      }
      this.loadThangType(lank.thangType);
      this.addDefaultActionsToRender(lank);
      this.setSpriteToLank(lank);
      this.updateLayerOrder();
      return lank.addHealthBar();
    }

    removeLank(lank) {
      this.stopListening(lank);
      lank.layer = null;
      this.container.removeChild(lank.sprite);
      return this.lanks = _.without(this.lanks, lank);
    }

    addLabel(label) {
      if (!Array.from(this.labels).includes(label)) { this.labels.push(label); }
      this.addChild(label.label);
      this.addChild(label.background);
      return this.updateLayerOrder();
    }

    removeLabel(label) {
      if (label.label) { this.removeChild(label.label); }
      if (label.background) { this.removeChild(label.background); }
      return this.labels = _.without(this.labels, label);
    }

    //- Loading network resources dynamically

    loadThangType(thangType) {
      let prerenderedSpriteSheet;
      if (!thangType.isFullyLoaded()) {
        thangType.setProjection(null);
        if (!thangType.loading) { thangType.fetch(); }
        this.numThingsLoading++;
        this.listenToOnce(thangType, 'sync', this.somethingLoaded);
        if ((Math.random() < 0.01) && utils.isOzaria) {
          return this.listenToOnce(thangType, 'sync', ((loadingTimer => () => log('ThangType Loaded', {
            loadTimeMS: loadingTimer(),
            original: thangType.get('original'),
            name: thangType.get('name')
          })))(startTimer()));
        }
      } else if (thangType.get('raster') && !thangType.loadedRaster) {
        thangType.loadRasterImage();
        this.listenToOnce(thangType, 'raster-image-loaded', this.somethingLoaded);
        this.numThingsLoading++;
        if ((Math.random() < 0.01) && utils.isOzaria) {
          return this.listenToOnce(thangType, 'raster-image-loaded', ((loadingTimer => () => log('ThangType Loaded', {
            loadTimeMS: loadingTimer(),
            original: thangType.get('original'),
            name: thangType.get('name')
          })))(startTimer()));
        }
      } else if ((thangType.get('spriteType') === 'rasterAtlas') && utils.isOzaria) {
        if (thangType.loadingRasterAtlas || thangType.loadedRasterAtlas) { return; }
        thangType.loadAllRasterTextureAtlases();
        this.listenToOnce(thangType, 'texture-atlas-loaded', function() { return this.somethingLoaded(thangType); });
        return this.numThingsLoading++;
      } else if (prerenderedSpriteSheet = thangType.getPrerenderedSpriteSheetToLoad()) {
        const startedLoading = prerenderedSpriteSheet.loadImage();
        if (!startedLoading) { return; }
        this.listenToOnce(prerenderedSpriteSheet, 'image-loaded', function() { return this.somethingLoaded(thangType); });
        return this.numThingsLoading++;
      }
    }

    somethingLoaded(thangType) {
      this.numThingsLoading--;
      this.loadThangType(thangType); // might need to load the raster image object
      for (var lank of Array.from(this.lanks)) {
        if (lank.thangType === thangType) {
          this.addDefaultActionsToRender(lank);
        }
      }
      return this.renderNewSpriteSheet();
    }

    //- Adding to the list of things we need to render

    onActionNeedsRender(lank, action) {
      return this.upsertActionToRender(lank.thangType, action.name, lank.options.colorConfig);
    }

    addDefaultActionsToRender(lank) {
      const needToRender = false;
      if (lank.thangType.get('raster')) {
        return this.upsertActionToRender(lank.thangType);
      } else {
        let defaultActions, defaultRenderableActions;
        if (utils.isOzaria) {
          // Cinematic lanks preload all their own animations and don't use the default action list.
          defaultActions = (lank != null ? lank.isCinematicLank : undefined) ? [] : ThangType.defaultActions;
          defaultRenderableActions = defaultActions.concat(lank.thangType.get('preLoadActions') || []);
        } else {
          defaultRenderableActions = ThangType.defaultActions.concat(lank.thangType.get('preLoadActions') || []);
        }
        return (() => {
          const result = [];
          for (var action of Array.from(_.values(lank.thangType.getActions()))) {
            if (!_.any(defaultRenderableActions, prefix => _.string.startsWith(action.name, prefix))) { continue; }
            result.push(this.upsertActionToRender(lank.thangType, action.name, lank.options.colorConfig));
          }
          return result;
        })();
      }
    }

    upsertActionToRender(thangType, actionName, colorConfig) {
      const groupKey = this.renderGroupingKey(thangType, actionName, colorConfig);
      if (this.actionRenderState[groupKey] !== undefined) { return false; }
      this.actionRenderState[groupKey] = 'need-to-render';
      this.toRenderBundles.push({thangType, actionName, colorConfig});
      if (this.willRender || !this.buildAutomatically) { return true; }
      this.willRender = _.defer(() => this.renderNewSpriteSheet());
      return true;
    }

    addCustomGraphic(key, graphic, bounds) {
      if (this.customGraphics[key]) { return false; }
      this.customGraphics[key] = { graphic, bounds: new createjs.Rectangle(...Array.from(bounds || [])) };
      if (this.willRender || !this.buildAutomatically) { return true; }
      return this._renderNewSpriteSheet(false);
    }

    //- Rendering sprite sheets

    renderNewSpriteSheet() {
      this.willRender = false;
      if (this.numThingsLoading) { return; }
      return this._renderNewSpriteSheet();
    }

    _renderNewSpriteSheet(async) {
      let e;
      let bundle;
      if (this.destroyed) { return; }
      if (utils.isOzaria) {
        this.renderNewSpriteSheetStartedTime = typeof performance !== 'undefined' && performance !== null ? performance.now() : undefined;
      }
      if (this.asyncBuilder) { this.asyncBuilder.stopAsync(); }
      this.asyncBuilder = null;

      if (async == null) { async = this.buildAsync; }
      const builder = new createjs.SpriteSheetBuilder();
      let groups = _.groupBy(this.toRenderBundles, (function(bundle) { return this.renderGroupingKey(bundle.thangType, '', bundle.colorConfig); }), this);

      // The first frame is always the 'loading', ie placeholder, image.
      const placeholder = this.createPlaceholder();
      const dimension = this.resolutionFactor * SPRITE_PLACEHOLDER_WIDTH;
      placeholder.setBounds(0, 0, dimension, dimension);
      builder.addFrame(placeholder);

      // Add custom graphics
      const extantGraphics = (this.spriteSheet != null ? this.spriteSheet.resolutionFactor : undefined) === this.resolutionFactor ? this.spriteSheet.animations : [];
      for (var key in this.customGraphics) {
        var frame;
        var graphic = this.customGraphics[key];
        if (Array.from(extantGraphics).includes(key)) {
          graphic = new createjs.Sprite(this.spriteSheet);
          graphic.gotoAndStop(key);
          frame = builder.addFrame(graphic);
        } else {
          frame = builder.addFrame(graphic.graphic, graphic.bounds, this.resolutionFactor);
        }
        builder.addAnimation(key, [frame], false);
      }

      // Render ThangTypes
      if (NEVER_RENDER_ANYTHING) { groups = {}; }
      for (var bundleGrouping of Array.from(_.values(groups))) {
        var {
          thangType
        } = bundleGrouping[0];
        var {
          colorConfig
        } = bundleGrouping[0];
        var actionNames = ((() => {
          const result = [];
          for (bundle of Array.from(bundleGrouping)) {             result.push(bundle.actionName);
          }
          return result;
        })());
        var args = [thangType, colorConfig, actionNames, builder];
        if (thangType.get('raw') || thangType.get('prerenderedSpriteSheetData')) {
          if ((thangType.get('spriteType') || this.defaultSpriteType) === 'segmented') {
            this.renderSegmentedThangType(...Array.from(args || []));
          } else {
            this.renderSingularThangType(...Array.from(args || []));
          }
        } else if ((thangType.get('spriteType') === 'rasterAtlas') && utils.isOzaria) {
          this.buildRasterAtlasSpriteSheet(thangType, actionNames);
        } else {
          this.renderRasterThangType(thangType, builder);
        }
      }

      if (async) {
        try {
          builder.buildAsync(); // will build empty spritesheet for rasterAtlas since not attaching anything to it, but its still required because of its coupling with the lank
        } catch (error) {
          e = error;
          this.resolutionFactor *= 0.9;
          console.log('Failed to build sprite sheet async:', e);
          return this._renderNewSpriteSheet(async);
        }
        builder.on('complete', this.onBuildSpriteSheetComplete, this, true, builder);
        return this.asyncBuilder = builder;
      } else {
        let sheet;
        try {
          sheet = builder.build();
        } catch (error1) {
          e = error1;
          this.resolutionFactor *= 0.9;
          console.log('Failed to build sprite sheet sync:', e);
          return this._renderNewSpriteSheet(async);
        }
        this.onBuildSpriteSheetComplete({async}, builder);
        return sheet;
      }
    }

    onBuildSpriteSheetComplete(e, builder) {
      let lank, parent;
      if (this.initializing || this.destroyed) { return; }
      if (performance && utils.isOzaria) {
        this.totalTimeSpentRendering += (typeof performance !== 'undefined' && performance !== null ? performance.now() : undefined) - this.renderNewSpriteSheetStartedTime;
        this.reportRenderTime();
      }
      this.asyncBuilder = null;
      if (builder != null) {
        builder.removeAllEventListeners();
      }

      if (this.spriteSheet) {
        // This is required for old canvas to be garbage collected.
        this.destroySpriteSheet();
      }

      this.spriteSheet = builder.spriteSheet;
      builder = null;
      this.spriteSheet.resolutionFactor = this.resolutionFactor;
      const oldLayer = this.container;
      if (oldLayer != null) {
        oldLayer.removeAllEventListeners();
      }

      this.container = new createjs.Container(this.spriteSheet);

      // Explicitly setting object as non reactive for performance benefit.
      if (utils.isOzaria) {
        Vue.nonreactive(this.container);
      }

      for (lank of Array.from(this.lanks)) {
        if (lank.destroyed) { console.log('zombie sprite found on layer', this.name); }
        if (lank.destroyed) { continue; }
        this.setSpriteToLank(lank);
      }
      for (var label of Array.from(this.labels)) {
        if (label.label) {
          this.container.addChild(label.label);
          this.container.addChild(label.background);
        }
      }
      for (var prop of ['scaleX', 'scaleY', 'regX', 'regY']) {
        this.container[prop] = oldLayer[prop];
      }
      if (parent = oldLayer.parent) {
        const index = parent.getChildIndex(oldLayer);
        parent.removeChildAt(index);
        parent.addChildAt(this.container, index);
      }
      if (this.camera != null) {
        this.camera.updateZoom(true);
      }
      this.updateLayerOrder();
      for (lank of Array.from(this.lanks)) {
        lank.options.resolutionFactor = this.resolutionFactor;
        lank.updateScale();
        lank.updateRotation();
      }
      return this.trigger('new-spritesheet');
    }

    resetSpriteSheet() {
      for (var lank of Array.from(this.lanks.slice(0))) { this.removeLank(lank); }
      this.toRenderBundles = [];
      this.actionRenderState = {};
      this.initializing = true;
      this.destroySpriteSheet();
      this.spriteSheet = this._renderNewSpriteSheet(false); // builds an empty spritesheet
      return this.initializing = false;
    }

    //- Placeholder

    createPlaceholder() {
      // TODO: Experiment with this. Perhaps have rectangles if default layer is obstacle or floor,
      // and different colors for different layers.
      const g = new createjs.Graphics();
      g.setStrokeStyle(1);
      const color = {
        'Land': [0, 50, 0],
        'Ground': [230, 230, 230],
        'Obstacle': [20, 70, 20],
        'Path': [200, 100, 200],
        'Default': [64, 64, 64],
        'Floating': [100, 100, 200]
      }[this.name] || [0, 0, 0];
      g.beginStroke(createjs.Graphics.getRGB(...Array.from(color || [])));
      color.push(0.7);
      g.beginFill(createjs.Graphics.getRGB(...Array.from(color || [])));
      const width = this.resolutionFactor * SPRITE_PLACEHOLDER_WIDTH;
      const bounds = [1, 1, width - 2, width - 2];
      if (['Default', 'Ground', 'Floating', 'Path'].includes(this.name)) {
        g.drawEllipse(...Array.from(bounds || []));
      } else {
        g.drawRect(...Array.from(bounds || []));
      }
      return new createjs.Shape(g);
    }

    //- Rendering containers for segmented thang types

    renderSegmentedThangType(thangType, colorConfig, actionNames, spriteSheetBuilder) {
      let animations, renderedActions;
      const prerenderedSpriteSheet = thangType.getPrerenderedSpriteSheet(colorConfig, 'segmented');
      if (prerenderedSpriteSheet && !prerenderedSpriteSheet.loadedImage) {
        return;
      } else if (prerenderedSpriteSheet) {
        animations = prerenderedSpriteSheet.spriteSheet._animations;
        renderedActions = _.zipObject(animations, _.times(animations.length, () => true));
      }
      const containersToRender = thangType.getContainersForActions(actionNames);
      //console.log 'render segmented', thangType.get('name'), actionNames, colorConfig, 'because we do not have prerendered sprite sheet?', prerenderedSpriteSheet
      const spriteBuilder = new SpriteBuilder(thangType, {colorConfig});
      return (() => {
        const result = [];
        for (var containerGlobalName of Array.from(containersToRender)) {
          var container, frame;
          var containerKey = this.renderGroupingKey(thangType, containerGlobalName, colorConfig);
          if (((this.spriteSheet != null ? this.spriteSheet.resolutionFactor : undefined) === this.resolutionFactor) && Array.from(this.spriteSheet.animations).includes(containerKey)) {
            container = new createjs.Sprite(this.spriteSheet);
            container.gotoAndStop(containerKey);
            frame = spriteSheetBuilder.addFrame(container);
          } else if (prerenderedSpriteSheet && renderedActions[containerGlobalName]) {
            container = new createjs.Sprite(prerenderedSpriteSheet.spriteSheet);
            container.gotoAndStop(containerGlobalName);
            var scale = this.resolutionFactor / (prerenderedSpriteSheet.get('resolutionFactor') || 1);
            frame = spriteSheetBuilder.addFrame(container, null, scale);
          } else {
            container = spriteBuilder.buildContainerFromStore(containerGlobalName);
            frame = spriteSheetBuilder.addFrame(container, null, this.resolutionFactor * (thangType.get('scale') || 1));
          }
          result.push(spriteSheetBuilder.addAnimation(containerKey, [frame], false));
        }
        return result;
      })();
    }


    //- Rendering sprite sheets for singular thang types

    renderSingularThangType(thangType, colorConfig, actionNames, spriteSheetBuilder) {
      let actions, frames, name, prerenderedFrames, scale, sprite;
      let action, key, f, frame, a;
      const prerenderedSpriteSheet = thangType.getPrerenderedSpriteSheet(colorConfig, 'singular');
      const prerenderedFramesMap = {};
      if (prerenderedSpriteSheet) {
        if (!prerenderedSpriteSheet.loadedImage) {
          return;
        }
        scale = this.resolutionFactor / (prerenderedSpriteSheet.get('resolutionFactor') || 1);
        for (let i = 0; i < prerenderedSpriteSheet.spriteSheet._frames.length; i++) {
          frame = prerenderedSpriteSheet.spriteSheet._frames[i];
          sprite = new createjs.Sprite(prerenderedSpriteSheet.spriteSheet);
          sprite.gotoAndStop(i);
          prerenderedFramesMap[i] = spriteSheetBuilder.addFrame(sprite, null, scale);
        }
      }
      //else
      //  console.log '    Rerendering singular thang type', thangType.get('name'), thangType.get('spriteType'), colorConfig, actionNames

      const actionObjects = _.values(thangType.getActions());
      const animationActions = [];
      for (a of Array.from(actionObjects)) {
        if (!a.animation) { continue; }
        if (!Array.from(actionNames).includes(a.name)) { continue; }
        animationActions.push(a);
      }

      const spriteBuilder = new SpriteBuilder(thangType, {colorConfig});

      const animationGroups = _.groupBy(animationActions, action => action.animation);
      for (var animationName in animationGroups) {
        var framesMap, next;
        actions = animationGroups[animationName];
        var renderAll = _.any(actions, action => action.frames === undefined);
        scale = actions[0].scale || thangType.get('scale') || 1;

        var actionKeys = ((() => {
          const result = [];
          for (action of Array.from(actions)) {             result.push(this.renderGroupingKey(thangType, action.name, colorConfig));
          }
          return result;
        })());
        if (((this.spriteSheet != null ? this.spriteSheet.resolutionFactor : undefined) === this.resolutionFactor) && _.all(actionKeys, key => Array.from(this.spriteSheet.animations).includes(key))) {
          var framesNeeded = _.uniq(_.flatten((() => {
            const result1 = [];
            for (key of Array.from(actionKeys)) {               result1.push((this.spriteSheet.getAnimation(key)).frames);
            }
            return result1;
          })()));
          framesMap = {};
          for (frame of Array.from(framesNeeded)) {
            sprite = new createjs.Sprite(this.spriteSheet);
            sprite.gotoAndStop(frame);
            framesMap[frame] = spriteSheetBuilder.addFrame(sprite);
          }
          for (var index = 0; index < actionKeys.length; index++) {
            key = actionKeys[index];
            action = actions[index];
            frames = ((() => {
              const result2 = [];
              for (f of Array.from(this.spriteSheet.getAnimation(key).frames)) {                 result2.push(framesMap[f]);
              }
              return result2;
            })());
            next = thangType.nextForAction(action);
            spriteSheetBuilder.addAnimation(key, frames, next);
          }
          continue;
        }

        if (prerenderedSpriteSheet) {
          for (action of Array.from(actions)) {
            name = this.renderGroupingKey(thangType, action.name, colorConfig);
            prerenderedFrames = __guard__(__guard__(prerenderedSpriteSheet.get('animations'), x1 => x1[action.name]), x => x.frames);
            if (!prerenderedFrames) { continue; }
            frames = ((() => {
              const result3 = [];
              for (frame of Array.from(prerenderedFrames)) {                 result3.push(prerenderedFramesMap[frame]);
              }
              return result3;
            })());
            next = thangType.nextForAction(action);
            spriteSheetBuilder.addAnimation(name, frames, next);
          }
          continue;
        }

        var mc = spriteBuilder.buildMovieClip(animationName, null, null, null, {'temp':0});

        if (renderAll) {
          var res = spriteSheetBuilder.addMovieClip(mc, null, scale * this.resolutionFactor);
          ({
            frames
          } = spriteSheetBuilder._animations['temp']);
          framesMap = _.zipObject(_.range(frames.length), frames);
        } else {
          framesMap = {};
          var framesToRender = _.uniq(_.flatten(((() => {
            const result4 = [];
            for (a of Array.from(actions)) {               result4.push(a.frames.split(','));
            }
            return result4;
          })())));
          for (frame of Array.from(framesToRender)) {
            frame = parseInt(frame);
            f = _.bind(mc.gotoAndStop, mc, frame);
            framesMap[frame] = spriteSheetBuilder.addFrame(mc, null, scale * this.resolutionFactor, f);
          }
        }

        for (action of Array.from(actions)) {
          name = this.renderGroupingKey(thangType, action.name, colorConfig);

          if (action.frames) {
            frames = ((() => {
              const result5 = [];
              for (frame of Array.from(action.frames.split(','))) {                 result5.push(framesMap[parseInt(frame)]);
              }
              return result5;
            })());
          } else {
            frames = _.sortBy(_.values(framesMap));
          }
          next = thangType.nextForAction(action);
          spriteSheetBuilder.addAnimation(name, frames, next);
        }
      }

      const containerActions = [];
      for (a of Array.from(actionObjects)) {
        if (!a.container) { continue; }
        if (!Array.from(actionNames).includes(a.name)) { continue; }
        containerActions.push(a);
      }

      const containerGroups = _.groupBy(containerActions, action => action.container);
      return (() => {
        const result6 = [];
        for (var containerName in containerGroups) {
          actions = containerGroups[containerName];
          if (prerenderedSpriteSheet) {
            for (action of Array.from(actions)) {
              name = this.renderGroupingKey(thangType, action.name, colorConfig);
              prerenderedFrames = __guard__(__guard__(prerenderedSpriteSheet.get('animations'), x3 => x3[action.name]), x2 => x2.frames);
              if (!prerenderedFrames) { continue; }
              frame = prerenderedFramesMap[prerenderedFrames[0]];
              spriteSheetBuilder.addAnimation(name, [frame], false);
            }
            continue;
          }
          var container = spriteBuilder.buildContainerFromStore(containerName);
          scale = actions[0].scale || thangType.get('scale') || 1;
          frame = spriteSheetBuilder.addFrame(container, null, scale * this.resolutionFactor);
          result6.push((() => {
            const result7 = [];
            for (action of Array.from(actions)) {
              name = this.renderGroupingKey(thangType, action.name, colorConfig);
              result7.push(spriteSheetBuilder.addAnimation(name, [frame], false));
            }
            return result7;
          })());
        }
        return result6;
      })();
    }

    //- Build the spritesheet for rasterAtlas sprite type

    buildRasterAtlasSpriteSheet(thangType, actionNames) {
      const spriteBuilder = new SpriteBuilder(thangType);
      return spriteBuilder.buildSpriteSheetFromTextureAtlas(actionNames); // builds and attaches the spritesheet to the movie clip file
    }

    //- Rendering frames for raster thang types

    renderRasterThangType(thangType, spriteSheetBuilder) {
      if (!thangType.rasterImage) {
        console.error(`Cannot render the LayerAdapter SpriteSheet until the raster image for <${thangType.get('name')}> is loaded.`);
      }

      const bm = new createjs.Bitmap(thangType.rasterImage[0]);
      const scale = thangType.get('scale') || 1;
      const frame = spriteSheetBuilder.addFrame(bm, null, scale);
      return spriteSheetBuilder.addAnimation(this.renderGroupingKey(thangType), [frame], false);
    }

    //- Distributing new Segmented/Singular/RasterSprites to Lanks

    setSpriteToLank(lank) {
      let sprite;
      if (!lank.thangType.isFullyLoaded()) {
        // just give a placeholder
        sprite = new createjs.Sprite(this.spriteSheet);
        sprite.gotoAndStop(0);
        sprite.placeholder = true;
        sprite.regX = (this.resolutionFactor * SPRITE_PLACEHOLDER_WIDTH) / 2;
        sprite.regY = this.resolutionFactor * SPRITE_PLACEHOLDER_WIDTH;
        sprite.baseScaleX = (sprite.baseScaleY = (sprite.scaleX = (sprite.scaleY = 10 / (this.resolutionFactor * SPRITE_PLACEHOLDER_WIDTH))));

      } else if (lank.thangType.get('raster')) {
        sprite = new createjs.Sprite(this.spriteSheet);
        const scale = lank.thangType.get('scale') || 1;
        const reg = lank.getOffset('registration');
        sprite.regX = -reg.x * scale;
        sprite.regY = -reg.y * scale;
        sprite.gotoAndStop(this.renderGroupingKey(lank.thangType));
        sprite.baseScaleX = (sprite.baseScaleY = 1);

      } else if ((lank.thangType.get('spriteType') === 'rasterAtlas') && utils.isOzaria) {
        sprite = new RasterAtlasSprite(lank.thangType);

      } else {
        const SpriteClass = (lank.thangType.get('spriteType') || this.defaultSpriteType) === 'segmented' ? SegmentedSprite : SingularSprite;
        const prefix = this.renderGroupingKey(lank.thangType, null, lank.options.colorConfig) + '.';
        sprite = new SpriteClass(this.spriteSheet, lank.thangType, prefix, this.resolutionFactor);
      }

      sprite.lank = lank;
      sprite.camera = this.camera;
      sprite.layerPriority = (lank.thang != null ? lank.thang.layerPriority : undefined) != null ? (lank.thang != null ? lank.thang.layerPriority : undefined) : lank.thangType.get('layerPriority');
      sprite.name = (lank.thang != null ? lank.thang.spriteName : undefined) || lank.thangType.get('name');
      lank.setSprite(sprite);
      lank.update(true);
      this.container.addChild(sprite);
      if (lank.thangType.get('matchWorldDimensions')) { return lank.updateScale(true); }  // Otherwise it's at the wrong scale for some reason.
    }

    renderGroupingKey(thangType, grouping, colorConfig) {
      let key = thangType.get('slug');
      const object = colorConfig != null ? colorConfig : {};
      for (var colorKey in object) {
        var colorValue = object[colorKey];
        key += `(${colorKey}:${colorValue.hue},${colorValue.saturation},${colorValue.lightness})`;
      }
      if (grouping) { key += '.'+grouping; }
      return key;
    }

    destroySpriteSheet() {
      if (!this.spriteSheet) { return; }
      return (() => {
        const result = [];
        for (let i = 0; i < this.spriteSheet._images.length; i++) {
          var image = this.spriteSheet._images[i];
          if (image) {
            image.width = (image.height = 0);
            result.push(this.spriteSheet._images[i] = null);
          }
        }
        return result;
      })();
    }

    destroy() {
      for (var child of Array.from(this.container.children)) { if (typeof child.destroy === 'function') {
        child.destroy();
      } }
      if (this.asyncBuilder) { this.asyncBuilder.stopAsync(); }
      this.destroySpriteSheet();
      return super.destroy();
    }
  };
  LayerAdapter.initClass();
  return LayerAdapter;
})()));

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}