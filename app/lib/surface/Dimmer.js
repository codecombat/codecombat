// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Dimmer;
const CocoClass = require('core/CocoClass');
const createjs = require('lib/createjs-parts');

module.exports = (Dimmer = (function() {
  Dimmer = class Dimmer extends CocoClass {
    static initClass() {
      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'sprite:highlight-sprites': 'onHighlightSprites',
        'sprite:speech-updated': 'onSpriteSpeechUpdated',
        'surface:frame-changed': 'onFrameChanged',
        'camera:zoom-updated': 'onZoomUpdated'
      };
    }

    constructor(options) {
      super();
      this.updateDimMask = this.updateDimMask.bind(this);
      if (options == null) { options = {}; }
      this.camera = options.camera;
      this.layer = options.layer;
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      this.build();
      this.updateDimMask = _.throttle(this.updateDimMask, 10);
      this.highlightedThangIDs = [];
      this.sprites = {};
    }

    toString() { return '<Dimmer>'; }

    build() {
      this.dimLayer = new createjs.Container();
      this.dimLayer.mouseEnabled = (this.dimLayer.mouseChildren = false);
      this.dimLayer.addChild(this.dimScreen = new createjs.Shape());
      this.dimLayer.addChild(this.dimMask = new createjs.Shape());
      this.dimScreen.graphics.beginFill('rgba(0,0,0,0.5)').rect(0, 0, this.camera.canvasWidth, this.camera.canvasHeight);
      this.dimMask.compositeOperation = 'destination-out';
      return this.dimLayer.cache(0, 0, this.camera.canvasWidth, this.camera.canvasHeight);
    }

    onDisableControls(e) {
      if (this.on || (e.controls && !(Array.from(e.controls).includes('surface')))) { return; }
      return this.dim();
    }

    onEnableControls(e) {
      if (!this.on || (e.controls && !(Array.from(e.controls).includes('surface')))) { return; }
      return this.undim();
    }

    onSpriteSpeechUpdated(e) { if (this.on) { return this.updateDimMask(); } }
    onFrameChanged(e) { if (this.on) { return this.updateDimMask(); } }
    onZoomUpdated(e) { if (this.on) { return this.updateDimMask(); } }
    onHighlightSprites(e) {
      this.highlightedThangIDs = e.thangIDs != null ? e.thangIDs : [];
      if (this.on) { return this.updateDimMask(); }
    }

    setSprites(sprites) {
      this.sprites = sprites;
    }

    dim() {
      this.on = true;
      this.layer.addChild(this.dimLayer);
      this.layer.updateLayerOrder();
      for (var thangID in this.sprites) { var sprite = this.sprites[thangID]; sprite.setDimmed(true); }
      return this.updateDimMask();
    }

    undim() {
      this.on = false;
      this.layer.removeChild(this.dimLayer);
      return (() => {
        const result = [];
        for (var thangID in this.sprites) {
          var sprite = this.sprites[thangID];
          result.push(sprite.setDimmed(false));
        }
        return result;
      })();
    }

    updateDimMask() {
      this.dimMask.graphics.clear();
      for (var thangID in this.sprites) {
        var sprite = this.sprites[thangID];
        if (!Array.from(this.highlightedThangIDs).includes(thangID)) { continue; }
        var sup = {x: sprite.sprite.x, y: sprite.sprite.y};
        var cap = this.camera.surfaceToCanvas(sup);
        var r = 50 * this.camera.zoom;  // TODO: find better way to get the radius based on the sprite's size
        this.dimMask.graphics.beginRadialGradientFill(['rgba(0,0,0,1)', 'rgba(0,0,0,0)'], [0.5, 1], cap.x, cap.y, 0, cap.x, cap.y, r).drawCircle(cap.x, cap.y, r);
      }

      return this.dimLayer.updateCache(0, 0, this.camera.canvasWidth, this.camera.canvasHeight);
    }
  };
  Dimmer.initClass();
  return Dimmer;
})());
