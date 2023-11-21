// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TrailMaster;
const PAST_PATH_ALPHA = 0.75;
const PAST_PATH_WIDTH = 5;
const FUTURE_PATH_ALPHA = 0.75;
const FUTURE_PATH_WIDTH = 4;
const TARGET_ALPHA = 1;
const TARGET_WIDTH = 10;
const FUTURE_PATH_INTERVAL_DIVISOR = 4;
const PAST_PATH_INTERVAL_DIVISOR = 2;

const Camera = require('./Camera');
const CocoClass = require('core/CocoClass');
const createjs = require('lib/createjs-parts');
const utils = require('core/utils');

module.exports = (TrailMaster = (function() {
  TrailMaster = class TrailMaster extends CocoClass {
    static initClass() {
      this.prototype.world = null;
    }

    constructor(camera, layerAdapter) {
      super();
      this.camera = camera;
      this.layerAdapter = layerAdapter;
      this.tweenedSprites = [];
      this.tweens = [];
    }

    generatePaths(world, thang) {
      this.world = world;
      this.thang = thang;
      if (this.generatingPaths) { return; }
      this.generatingPaths = true;
      this.createGraphics();
      const pathDisplayObject = new createjs.Container(this.layerAdapter.spriteSheet);
      pathDisplayObject.mouseEnabled = (pathDisplayObject.mouseChildren = false);
      pathDisplayObject.addChild(this.createFuturePath());
  //    pathDisplayObject.addChild @createPastPath() # Just made the animated path the full path... do we want to have past and future look different again?
      pathDisplayObject.addChild(this.createTargets());
      this.generatingPaths = false;
      return pathDisplayObject;
    }

    cleanUp() {
      for (var sprite of Array.from(this.tweenedSprites)) { createjs.Tween.removeTweens(sprite); }
      this.tweenedSprites = [];
      return this.tweens = [];
    }

    createGraphics() {
      this.targetDotKey = this.cachePathDot(TARGET_WIDTH, this.colorForThang(this.thang.team, TARGET_ALPHA), [0, 0, 0, 1]);
      this.pastDotKey = this.cachePathDot(PAST_PATH_WIDTH, this.colorForThang(this.thang.team, PAST_PATH_ALPHA), [0, 0, 0, 1]);
      return this.futureDotKey = this.cachePathDot(FUTURE_PATH_WIDTH, [255, 255, 255, FUTURE_PATH_ALPHA], this.colorForThang(this.thang.team, 1));
    }

    cachePathDot(width, fillColor, strokeColor) {
      const key = `path-dot-${width}-${fillColor}-${strokeColor}`;
      fillColor = createjs.Graphics.getRGB(...Array.from(fillColor || []));
      strokeColor = createjs.Graphics.getRGB(...Array.from(strokeColor || []));
      if (!Array.from(this.layerAdapter.spriteSheet.animations).includes(key)) {
        const circle = new createjs.Shape();
        const radius = width/2;
        circle.graphics.setStrokeStyle(width/5).beginFill(fillColor).beginStroke(strokeColor).drawCircle(0, 0, radius);
        this.layerAdapter.addCustomGraphic(key, circle, [-radius*1.5, -radius*1.5, radius*3, radius*3]);
      }
      return key;
    }

    colorForThang(team, alpha) {
      let rgb;
      if (alpha == null) { alpha = 1.0; }
      if (utils.isCodeCombat) {
        rgb = [0, 255, 0];
        if (team === 'humans') { rgb = [255, 0, 0]; }
        if (team === 'ogres') { rgb = [0, 0, 255]; }
      } else {
        rgb = [79, 202, 82];
        if (team === 'humans') { rgb = [69, 170, 255]; }
        if (team === 'ogres') { rgb = [255, 0, 0]; }
      }
      rgb.push(alpha);
      return rgb;
    }

    createPastPath() {
      let points;
      if (!(points = this.world.pointsForThang(this.thang.id, this.camera))) { return; }
      const interval = Math.max(1, parseInt(this.world.frameRate / PAST_PATH_INTERVAL_DIVISOR));
      const params = { interval, frameKey: this.pastDotKey };
      return this.createPath(points, params);
    }

    createFuturePath() {
      let points;
      if (!(points = this.world.pointsForThang(this.thang.id, this.camera))) { return; }
      const interval = Math.max(1, parseInt(this.world.frameRate / FUTURE_PATH_INTERVAL_DIVISOR));
      const params = { interval, animate: true, frameKey: this.futureDotKey };
      return this.createPath(points, params);
    }

    createTargets() {
      if (!this.thang.allTargets) { return; }
      const container = new createjs.Container(this.layerAdapter.spriteSheet);
      for (let i = 0; i < this.thang.allTargets.length; i += 2) {
        var x = this.thang.allTargets[i];
        var y = this.thang.allTargets[i + 1];
        var sup = this.camera.worldToSurface({x, y});
        var sprite = new createjs.Sprite(this.layerAdapter.spriteSheet);
        sprite.scaleX = (sprite.scaleY = 1 / this.layerAdapter.resolutionFactor);
        sprite.scaleY *= this.camera.y2x;
        sprite.gotoAndStop(this.targetDotKey);
        sprite.x = sup.x;
        sprite.y = sup.y;
        container.addChild(sprite);
      }
      return container;
    }

    createPath(points, options) {
      if (options == null) { options = {}; }
      options = options || {};
      const interval = options.interval || 8;
      const key = options.frameKey || this.pastDotKey;
      const container = new createjs.Container(this.layerAdapter.spriteSheet);

      for (let step = interval * 2, asc = step > 0, i = asc ? 0 : points.length - 1; asc ? i < points.length : i >= 0; i += step) {
        var x = points[i];
        var y = points[i + 1];
        var sprite = new createjs.Sprite(this.layerAdapter.spriteSheet);
        sprite.scaleX = (sprite.scaleY = 1 / this.layerAdapter.resolutionFactor);
        sprite.scaleY *= this.camera.y2x;
        sprite.gotoAndStop(key);
        sprite.x = x;
        sprite.y = y;
        container.addChild(sprite);
        if (lastSprite && options.animate) {
          var tween = createjs.Tween.get(lastSprite, {loop: true}).to({x, y}, 1000);
          this.tweenedSprites.push(lastSprite);
          this.tweens.push(tween);
        }
        var lastSprite = sprite;
      }

      this.logged = true;
      return container;
    }

    play() {
      return Array.from(this.tweens).map((tween) => (tween.paused = false));
    }

    stop() {
      return Array.from(this.tweens).map((tween) => (tween.paused = true));
    }

    destroy() {
      this.cleanUp();
      return super.destroy();
    }
  };
  TrailMaster.initClass();
  return TrailMaster;
})());
