// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoordinateGrid;
const CocoClass = require('core/CocoClass');
const createjs = require('lib/createjs-parts');

module.exports = (CoordinateGrid = (function() {
  CoordinateGrid = class CoordinateGrid extends CocoClass {
    static initClass() {
      this.prototype.subscriptions =
        {'level:toggle-grid': 'onToggleGrid'};

      this.prototype.shortcuts =
        {'ctrl+g, ⌘+g': 'onToggleGrid'};
    }

    constructor(options, worldSize) {
      if (options == null) { options = {}; }
      super();
      this.camera = options.camera;
      this.layer = options.layer;
      this.textLayer = options.textLayer;
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      if (!this.textLayer) { console.error(this.toString(), 'needs a textLayer.'); }
      this.build(worldSize);
    }

    destroy() {
      return super.destroy();
    }

    toString() { return '<CoordinateGrid>'; }

    build(worldSize) {
      let sup, t;
      const worldWidth = worldSize[0] || 80;
      const worldHeight = worldSize[1] || 68;
      this.gridContainer = new createjs.Container();
      this.gridShape = new createjs.Shape();
      this.gridContainer.addChild(this.gridShape);
      this.gridContainer.mouseEnabled = false;
      this.gridShape.alpha = 0.125;
      this.gridShape.graphics.setStrokeStyle(1);
      this.gridShape.graphics.beginStroke('blue');
      const gridSize = Math.round(worldWidth / 20);
      const wopStart = {x: 0, y: 0};
      const wopEnd = {x: worldWidth, y: worldHeight};
      const supStart = this.camera.worldToSurface(wopStart);
      const supEnd = this.camera.worldToSurface(wopEnd);
      const wop = {x: wopStart.x, y: wopStart.y};
      this.labels = [];
      let linesDrawn = 0;
      while (wop.x <= wopEnd.x) {
        sup = this.camera.worldToSurface(wop);
        this.gridShape.graphics.mt(sup.x, supStart.y).lt(sup.x, supEnd.y);
        if (++linesDrawn % 2) {
          t = new createjs.Text(wop.x.toFixed(0), '16px Arial', 'blue');
          t.textAlign = 'center';
          t.textBaseline = 'bottom';
          t.x = sup.x;
          t.y = supStart.y;
          t.alpha = 0.75;
          this.labels.push(t);
        }
        wop.x += gridSize;
        if (wopEnd.x < wop.x && wop.x <= wopEnd.x - (gridSize / 2)) {
          wop.x = wopEnd.x;
        }
      }
      linesDrawn = 0;
      while (wop.y <= wopEnd.y) {
        sup = this.camera.worldToSurface(wop);
        this.gridShape.graphics.mt(supStart.x, sup.y).lt(supEnd.x, sup.y);
        if (++linesDrawn % 2) {
          t = new createjs.Text(wop.y.toFixed(0), '16px Arial', 'blue');
          t.textAlign = 'left';
          t.textBaseline = 'middle';
          t.x = 0;
          t.y = sup.y;
          t.alpha = 0.75;
          this.labels.push(t);
        }
        wop.y += gridSize;
        if (wopEnd.y < wop.y && wop.y <= wopEnd.y - (gridSize / 2)) {
          wop.y = wopEnd.y;
        }
      }
      this.gridShape.graphics.endStroke();
      const bounds = {x: supStart.x, y: supEnd.y, width: supEnd.x - supStart.x, height: supStart.y - supEnd.y};
      if (!(bounds != null ? bounds.width : undefined) || !bounds.height) { return; }
      return this.gridContainer.cache(bounds.x, bounds.y, bounds.width, bounds.height);
    }

    showGrid() {
      if (this.gridShowing()) { return; }
      this.layer.addChild(this.gridContainer);
      return Array.from(this.labels).map((label) => this.textLayer.addChild(label));
    }

    hideGrid() {
      if (!this.gridShowing()) { return; }
      this.layer.removeChild(this.gridContainer);
      return Array.from(this.labels).map((label) => this.textLayer.removeChild(label));
    }

    gridShowing() {
      return ((this.gridContainer != null ? this.gridContainer.parent : undefined) != null);
    }

    onToggleGrid(e) {
      __guardMethod__(e, 'preventDefault', o => o.preventDefault());
      if (this.gridShowing()) { return this.hideGrid(); } else { return this.showGrid(); }
    }
  };
  CoordinateGrid.initClass();
  return CoordinateGrid;
})());


function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}