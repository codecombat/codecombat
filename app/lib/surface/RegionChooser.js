// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RegionChooser;
const CocoClass = require('core/CocoClass');
const Camera = require('./Camera');
const createjs = require('lib/createjs-parts');

module.exports = (RegionChooser = class RegionChooser extends CocoClass {
  constructor(options) {
    super();
    this.onMouseDown = this.onMouseDown.bind(this);
    this.onMouseMove = this.onMouseMove.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);
    this.options = options;
    this.options.stage.addEventListener('stagemousedown', this.onMouseDown);
    this.options.stage.addEventListener('stagemousemove', this.onMouseMove);
    this.options.stage.addEventListener('stagemouseup', this.onMouseUp);
  }

  destroy() {
    this.options.stage.removeEventListener('stagemousedown', this.onMouseDown);
    this.options.stage.removeEventListener('stagemousemove', this.onMouseMove);
    this.options.stage.removeEventListener('stagemouseup', this.onMouseUp);
    return super.destroy();
  }

  onMouseDown(e) {
    if (!key.shift) { return; }
    this.firstPoint = this.options.camera.screenToWorld({x: e.stageX, y: e.stageY});
    return this.options.camera.dragDisabled = true;
  }

  onMouseMove(e) {
    if (!this.firstPoint) { return; }
    this.secondPoint = this.options.camera.screenToWorld({x: e.stageX, y: e.stageY});
    if (this.options.restrictRatio || key.alt) { this.restrictRegion(); }
    return this.updateShape();
  }

  onMouseUp(e) {
    if (!this.firstPoint) { return; }
    Backbone.Mediator.publish('surface:choose-region', {points: [this.firstPoint, this.secondPoint]});
    this.firstPoint = null;
    this.secondPoint = null;
    return this.options.camera.dragDisabled = false;
  }

  restrictRegion() {
    const RATIO = 1.56876;  // 924 / 589
    const rect = this.options.camera.normalizeBounds([this.firstPoint, this.secondPoint]);
    const currentRatio = rect.width / rect.height;
    if (currentRatio > RATIO) {
      // increase the height
      const targetSurfaceHeight = rect.width / RATIO;
      let targetWorldHeight = targetSurfaceHeight * Camera.MPP * this.options.camera.x2y;
      if (this.secondPoint.y < this.firstPoint.y) { targetWorldHeight *= -1; }
      return this.secondPoint.y = this.firstPoint.y + targetWorldHeight;
    } else {
      // increase the width
      const targetSurfaceWidth = rect.height * RATIO;
      let targetWorldWidth =  targetSurfaceWidth * Camera.MPP;
      if (this.secondPoint.x < this.firstPoint.x) { targetWorldWidth *= -1; }
      return this.secondPoint.x = this.firstPoint.x + targetWorldWidth;
    }
  }

  // Called from WorldSelectModal
  setRegion(worldPoints) {
    this.firstPoint = worldPoints[0];
    this.secondPoint = worldPoints[1];
    this.updateShape();
    this.firstPoint = null;
    return this.secondPoint = null;
  }

  updateShape() {
    const rect = this.options.camera.normalizeBounds([this.firstPoint, this.secondPoint]);
    if (this.shape) { this.options.surfaceLayer.removeChild(this.shape); }
    this.shape = new createjs.Shape();
    this.shape.alpha = 0.5;
    this.shape.mouseEnabled = false;
    this.shape.graphics.beginFill('#fedcba').drawRect(rect.x, rect.y, rect.width, rect.height);
    this.shape.graphics.endFill();
    this.shape.skipScaling = true;
    return this.options.surfaceLayer.addChild(this.shape);
  }
});
