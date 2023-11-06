// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PointChooser;
const CocoClass = require('core/CocoClass');
const createjs = require('lib/createjs-parts');

module.exports = (PointChooser = class PointChooser extends CocoClass {
  constructor(options) {
    super();
    this.onMouseDown = this.onMouseDown.bind(this);
    this.options = options;
    this.buildShape();
    this.options.stage.addEventListener('stagemousedown', this.onMouseDown);
    this.options.camera.dragDisabled = true;
  }

  destroy() {
    this.options.stage.removeEventListener('stagemousedown', this.onMouseDown);
    return super.destroy();
  }

  // Called also from WorldSelectModal
  setPoint(point) {
    this.point = point;
    return this.updateShape();
  }

  buildShape() {
    this.shape = new createjs.Shape();
    this.shape.alpha = 0.9;
    this.shape.mouseEnabled = false;
    this.shape.graphics.setStrokeStyle(1, 'round').beginStroke('#000000').beginFill('#fedcba');
    return this.shape.graphics.drawCircle(0, 0, 4).endFill();
  }

  onMouseDown(e) {
    if (!key.shift) { return; }
    this.setPoint(this.options.camera.screenToWorld({x: e.stageX, y: e.stageY}));
    return Backbone.Mediator.publish('surface:choose-point', {point: this.point});
  }

  updateShape() {
    const sup = this.options.camera.worldToSurface(this.point);
    if (!this.shape.parent) { this.options.surfaceLayer.addChild(this.shape); }
    this.shape.x = sup.x;
    return this.shape.y = sup.y;
  }
});
