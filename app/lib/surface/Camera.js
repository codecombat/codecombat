// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Camera;
const CocoClass = require('core/CocoClass');
const GameUIState = require('models/GameUIState');
const createjs = require('lib/createjs-parts');
const utils = require('core/utils');

// If I were the kind of math major who remembered his math, this would all be done with matrix transforms.

const r2d = radians => (radians * 180) / Math.PI;
const d2r = degrees => (degrees / 180) * Math.PI;

const MAX_ZOOM = 8;
const MIN_ZOOM = 0.25;
const DEFAULT_ZOOM = 2.0;
const DEFAULT_TARGET = {x: 0, y: 0};
const DEFAULT_TIME = 1000;
const STANDARD_ZOOM_WIDTH = 924;
const STANDARD_ZOOM_HEIGHT = 589;

// You can't mutate any of the constructor parameters after construction.
// You can only call zoomTo to change the zoom target and zoom level.
module.exports = (Camera = (function() {
  Camera = class Camera extends CocoClass {
    static initClass() {
      this.PPM = 10;   // pixels per meter
      this.MPP = 0.1;  // meters per pixel; should match @PPM

      this.prototype.bounds = null;  // list of two surface points defining the viewable rectangle in the world
                    // or null if there are no bounds

      // what the camera is pointed at right now
      this.prototype.target = DEFAULT_TARGET;
      this.prototype.zoom = DEFAULT_ZOOM;
      this.prototype.canvasScaleFactorX = 1;
      this.prototype.canvasScaleFactorY = 1;

      // properties for tracking going between targets
      this.prototype.oldZoom = null;
      this.prototype.newZoom = null;
      this.prototype.oldTarget = null;
      this.prototype.newTarget = null;
      this.prototype.tweenProgress = 0.0;

      this.prototype.instant = false;

      // INIT

      this.prototype.subscriptions =
        Object.assign(
          {
            'camera:zoom-to': 'onZoomTo',
            'level:restarted': 'onLevelRestarted'
          },
          utils.isCodeCombat ? {
            'camera:zoom-out': 'onZoomOut',
            'camera:zoom-in': 'onZoomIn'
          } : {}
        );
    }

    constructor(canvas, options) {
      if (options == null) { options = {}; }
      super();
      this.finishTween = this.finishTween.bind(this);
      this.canvas = canvas;
      this.options = options;
      const angle=Math.asin(0.75);
      const hFOV=d2r(30);
      this.gameUIState = this.options.gameUIState || new GameUIState();
      this.listenTo(this.gameUIState, 'surface:stage-mouse-move', this.onMouseMove);
      this.listenTo(this.gameUIState, 'surface:stage-mouse-down', this.onMouseDown);
      this.listenTo(this.gameUIState, 'surface:stage-mouse-up', this.onMouseUp);
      this.listenTo(this.gameUIState, 'surface:mouse-scrolled', this.onMouseScrolled);
      this.handleEvents = this.options.handleEvents != null ? this.options.handleEvents : true;
      this.canvasWidth = parseInt(this.canvas.attr('width'), 10);
      this.canvasHeight = parseInt(this.canvas.attr('height'), 10);
      this.offset = {x: 0, y: 0};
      this.calculateViewingAngle(angle);
      this.calculateFieldOfView(hFOV);
      this.calculateAxisConversionFactors();
      this.calculateMinMaxZoom();
      this.updateViewports();
    }

    onResize(newCanvasWidth, newCanvasHeight) {
      this.canvasScaleFactorX = newCanvasWidth / this.canvasWidth;
      this.canvasScaleFactorY = newCanvasHeight / this.canvasHeight;
      return Backbone.Mediator.publish('camera:zoom-updated', {camera: this, zoom: this.zoom, surfaceViewport: this.surfaceViewport});
    }

    calculateViewingAngle(angle) {
      // Operate on open interval between 0 - 90 degrees to make the math easier
      const epsilon = 0.000001;  // Too small and numerical instability will get us.
      this.angle = Math.max(Math.min((Math.PI / 2) - epsilon, angle), epsilon);
      if ((this.angle !== angle) && (angle !== 0) && (angle !== (Math.PI / 2))) {
        return console.log(`Restricted given camera angle of ${r2d(angle)} to ${r2d(this.angle)}.`);
      }
    }

    calculateFieldOfView(hFOV) {
      // http://en.wikipedia.org/wiki/Field_of_view_in_video_games
      const epsilon = 0.000001;  // Too small and numerical instability will get us.
      this.hFOV = Math.max(Math.min(Math.PI - epsilon, hFOV), epsilon);
      if ((this.hFOV !== hFOV) && (hFOV !== 0) && (hFOV !== Math.PI)) {
        console.log(`Restricted given horizontal field of view to ${r2d(hFOV)} to ${r2d(this.hFOV)}.`);
      }
      this.vFOV = 2 * Math.atan((Math.tan(this.hFOV / 2) * this.canvasHeight) / this.canvasWidth);
      if (this.vFOV > Math.PI) {
        console.log('Vertical field of view problem: expected canvas not to be taller than it is wide with high field of view.');
        return this.vFOV = Math.PI - epsilon;
      }
    }

    calculateAxisConversionFactors() {
      this.y2x = Math.sin(this.angle);      // 1 unit along y is equivalent to y2x units along x
      this.z2x = Math.cos(this.angle);      // 1 unit along z is equivalent to z2x units along x
      this.z2y = this.z2x / this.y2x;          // 1 unit along z is equivalent to z2y units along y
      this.x2y = 1 / this.y2x;             // 1 unit along x is equivalent to x2y units along y
      this.x2z = 1 / this.z2x;             // 1 unit along x is equivalent to x2z units along z
      return this.y2z = 1 / this.z2y;             // 1 unit along y is equivalent to y2z units along z
    }

    // CONVERSIONS AND CALCULATIONS

    worldToSurface(pos) {
      const x = pos.x * Camera.PPM;
      let y = -pos.y * this.y2x * Camera.PPM;
      if (pos.z) {
        y -= this.z2y * this.y2x * pos.z * Camera.PPM;
      }
      return {x, y};
    }

    surfaceToCanvas(pos) {
      return {x: (pos.x - this.surfaceViewport.x) * this.zoom, y: (pos.y - this.surfaceViewport.y) * this.zoom};
    }

    canvasToScreen(pos) {
      return {x: pos.x * this.canvasScaleFactorX, y: pos.y * this.canvasScaleFactorY};
    }

    screenToCanvas(pos) {
      return {x: pos.x / this.canvasScaleFactorX, y: pos.y / this.canvasScaleFactorY};
    }

    canvasToSurface(pos) {
      return {x: (pos.x / this.zoom) + this.surfaceViewport.x, y: (pos.y / this.zoom) + this.surfaceViewport.y};
    }

    surfaceToWorld(pos) {
      return {x: pos.x * Camera.MPP, y: -pos.y * Camera.MPP * this.x2y, z: 0};
    }

    canvasToWorld(pos) { return this.surfaceToWorld(this.canvasToSurface(pos)); }
    worldToCanvas(pos) { return this.surfaceToCanvas(this.worldToSurface(pos)); }
    worldToScreen(pos) { return this.canvasToScreen(this.worldToCanvas(pos)); }
    surfaceToScreen(pos) { return this.canvasToScreen(this.surfaceToCanvas(pos)); }
    screenToSurface(pos) { return this.canvasToSurface(this.screenToCanvas(pos)); }
    screenToWorld(pos) { return this.surfaceToWorld(this.screenToSurface(pos)); }

    cameraWorldPos() {
      // I tried to figure out the math for how much of @vFOV is below the midpoint (botFOV) and how much is above (topFOV), but I failed.
      // So I'm just making something up. This would give botFOV 20deg, topFOV 10deg at @vFOV 30deg and @angle 45deg, or an even 15/15 at @angle 90deg.
      const botFOV = (this.x2y * this.vFOV) / (this.y2x + this.x2y);
      const topFOV = (this.y2x * this.vFOV) / (this.y2x + this.x2y);
      const botDist = ((this.worldViewport.height / 2) * Math.sin(this.angle)) / Math.sin(botFOV);
      const z = botDist * Math.sin(this.angle + botFOV);
      return {x: this.worldViewport.cx, y: this.worldViewport.cy - (z * this.z2y), z};
    }

    distanceTo(pos) {
      // Get the physical distance in meters from the camera to the given world pos.
      const cpos = this.cameraWorldPos();
      const dx = pos.x - cpos.x;
      const dy = pos.y - cpos.y;
      const dz = (pos.z || 0) - cpos.z;
      return Math.sqrt((dx * dx) + (dy * dy) + (dz * dz));
    }

    distanceRatioTo(pos) {
      // Get the ratio of the distance to the given world pos over the distance to the center of the camera view.
      const cpos = this.cameraWorldPos();
      const dy = this.worldViewport.cy - cpos.y;
      const camDist = Math.sqrt((dy * dy) + (cpos.z * cpos.z));
      return this.distanceTo(pos) / camDist;
    }

      // Old method for flying things below; could re-integrate this
      //# Because none of our maps are designed to get smaller with distance along the y-axis, we'll only use z, as if we were looking straight down, until we get high enough. Based on worldPos.z, we gradually shift over to the more-realistic scale. This is pretty hacky.
      //ratioWithoutY = dz * dz / (cPos.z * cPos.z)
      //zv = Math.min(Math.max(0, worldPos.z - 5), cPos.z - 5) / (cPos.z - 5)
      //zv * ratioWithY + (1 - zv) * ratioWithoutY

    // SUBSCRIPTIONS

    onZoomIn(e) { return this.zoomTo(this.target, this.zoom * 1.15, 300); }
    onZoomOut(e) { return this.zoomTo(this.target, this.zoom / 1.15, 300); }

    onMouseDown(e) {
      if (this.dragDisabled) { return; }
      this.lastPos = {x: e.originalEvent.rawX, y: e.originalEvent.rawY};
      return this.mousePressed = true;
    }

    onMouseMove(e) {
      if (!this.mousePressed || !this.gameUIState.get('canDragCamera')) { return; }
      if (this.dragDisabled) { return; }
      const target = this.boundTarget(this.target, this.zoom);
      const newPos = {
        x: target.x + ((this.lastPos.x - e.originalEvent.rawX) / this.zoom),
        y: target.y + ((this.lastPos.y - e.originalEvent.rawY) / this.zoom)
      };
      this.zoomTo(newPos, this.zoom, 0);
      this.lastPos = {x: e.originalEvent.rawX, y: e.originalEvent.rawY};
      return Backbone.Mediator.publish('camera:dragged', {});
    }

    onMouseUp(e) {
      return this.mousePressed = false;
    }

    onMouseScrolled(e) {
      let target;
      let ratio = 1 + (0.05 * Math.sqrt(Math.abs(e.deltaY)));
      if (e.deltaY > 0) { ratio = 1 / ratio; }
      const newZoom = this.zoom * ratio;
      if (e.screenPos && !this.focusedOnSprite()) {
        // zoom based on mouse position, adjusting the target so the point under the mouse stays the same
        const mousePoint = this.screenToSurface(e.screenPos);
        const ratioPosX = (mousePoint.x - this.surfaceViewport.x) / this.surfaceViewport.width;
        const ratioPosY = (mousePoint.y - this.surfaceViewport.y) / this.surfaceViewport.height;
        const newWidth = this.canvasWidth / newZoom;
        const newHeight = this.canvasHeight / newZoom;
        const newTargetX = (mousePoint.x - (newWidth * ratioPosX)) + (newWidth / 2);
        const newTargetY = (mousePoint.y - (newHeight * ratioPosY)) + (newHeight / 2);
        target = {x: newTargetX, y: newTargetY};
      } else {
        ({
          target
        } = this);
      }
      return this.zoomTo(target, newZoom, 0);
    }

    onLevelRestarted() {
      return this.setBounds(this.firstBounds, false);
    }

    // COMMANDS

    setBounds(worldBounds, updateZoom) {
      // receives an array of two world points. Normalize and apply them
      if (updateZoom == null) { updateZoom = true; }
      if (!this.firstBounds) { this.firstBounds = worldBounds; }
      this.bounds = this.normalizeBounds(worldBounds);
      this.calculateMinMaxZoom();
      if (updateZoom) { this.updateZoom(true); }
      if (!this.focusedOnSprite()) { return this.target = this.currentTarget; }
    }

    normalizeBounds(worldBounds) {
      if (!worldBounds) { return null; }
      const top = Math.max(worldBounds[0].y, worldBounds[1].y);
      const left = Math.min(worldBounds[0].x, worldBounds[1].x);
      let bottom = Math.min(worldBounds[0].y, worldBounds[1].y);
      let right = Math.max(worldBounds[0].x, worldBounds[1].x);
      if (top === bottom) { bottom -= 1; }
      if (left === right) { right += 1; }
      const p1 = this.worldToSurface({x: left, y: top});
      const p2 = this.worldToSurface({x: right, y: bottom});
      return {x: p1.x, y: p1.y, width: p2.x-p1.x, height: p2.y-p1.y};
    }

    calculateMinMaxZoom() {
      // Zoom targets are always done in Surface coordinates.
      this.maxZoom = MAX_ZOOM;
      if (!this.bounds) { return this.minZoom = MIN_ZOOM; }
      this.minZoom = Math.max(this.canvasWidth / this.bounds.width, this.canvasHeight / this.bounds.height);
      if (this.zoom) {
        this.zoom = Math.max(this.minZoom, this.zoom);
        return this.zoom = Math.min(this.maxZoom, this.zoom);
      }
    }

    zoomTo(newTarget=null, newZoom, time) {
      // Target is either just a {x, y} pos or a display object with {x, y} that might change; surface coordinates.
      if (newZoom == null) { newZoom = 1.0; }
      if (time == null) { time = 1500; }
      if (this.instant) { time = 0; }
      if (newTarget == null) { newTarget = {x: 0, y: 0}; }
      if (this.locked) { newTarget = (this.newTarget || this.target); }
      newZoom = Math.max(newZoom, this.minZoom);
      newZoom = Math.min(newZoom, this.maxZoom);

      const thangType = __guard__(this.target != null ? this.target.sprite : undefined, x => x.thangType);
      if (thangType) {
        this.offset = _.clone(__guard__(thangType.get('positions'), x1 => x1.torso) || {x: 0, y: 0});
        const scale = thangType.get('scale') || 1;
        this.offset.x *= scale;
        this.offset.y *= scale;
      } else {
        this.offset = {x: 0, y: 0};
      }

      if ((this.zoom === newZoom) && (newTarget === newTarget.x) && (newTarget.y === newTarget.y)) { return; }

      this.finishTween(true);
      if (time) {
        this.newTarget = newTarget;
        this.oldTarget = this.boundTarget(this.target, this.zoom);
        this.oldZoom = this.zoom;
        this.newZoom = newZoom;
        this.tweenProgress = 0.01;
        return createjs.Tween.get(this)
          .to({tweenProgress: 1.0}, time, createjs.Ease.getPowOut(4))
          .call(this.finishTween);

      } else {
        this.target = newTarget;
        this.zoom = newZoom;
        return this.updateZoom(true);
      }
    }

    focusedOnSprite() {
      return (this.target != null ? this.target.name : undefined);
    }

    finishTween(abort) {
      if (abort == null) { abort = false; }
      createjs.Tween.removeTweens(this);
      if (!this.newTarget) { return; }
      if (abort !== true) {
        this.target = this.newTarget;
        this.zoom = this.newZoom;
      }
      this.newZoom = (this.oldZoom = (this.newTarget = (this.newTarget = (this.tweenProgress = null))));
      return this.updateZoom(true);
    }

    updateZoom(force) {
      // Update when we're focusing on a Thang, tweening, or forcing it, unless we're locked
      let target;
      if (force == null) { force = false; }
      if ((!force) && (this.locked || (!this.newTarget && !this.focusedOnSprite()))) { return; }
      if (this.newTarget) {
        const t = this.tweenProgress;
        this.zoom = this.oldZoom + (t * (this.newZoom - this.oldZoom));
        const [p1, p2] = Array.from([this.oldTarget, this.boundTarget(this.newTarget, this.newZoom)]);
        target = (this.target = {x: p1.x + (t * (p2.x - p1.x)), y: p1.y + (t * (p2.y - p1.y))});
      } else {
        target = this.boundTarget(this.target, this.zoom);
        if (!force && _.isEqual(target, this.currentTarget)) { return; }
      }
      this.currentTarget = target;
      const viewportDifference = this.updateViewports(target);
      if (viewportDifference > 0.1) {  // Roughly 0.1 pixel difference in what we can see
        return Backbone.Mediator.publish('camera:zoom-updated', {camera: this, zoom: this.zoom, surfaceViewport: this.surfaceViewport, minZoom: this.minZoom});
      }
    }

    boundTarget(pos, zoom) {
      // Given an {x, y} in Surface coordinates, return one that will keep our viewport on the Surface.
      let thang;
      if (!this.bounds) { return pos; }
      let {
        y
      } = pos;
      if (thang = pos.sprite != null ? pos.sprite.thang : undefined) {
        ({
          y
        } = this.worldToSurface({x: thang.pos.x, y: thang.pos.y}));  // ignore z
      }
      const marginX = (this.canvasWidth / zoom / 2);
      const marginY = (this.canvasHeight / zoom / 2);
      const x = Math.min(Math.max(marginX + this.bounds.x, pos.x + this.offset.x), (this.bounds.x + this.bounds.width) - marginX);
      y = Math.min(Math.max(marginY + this.bounds.y, y + this.offset.y), (this.bounds.y + this.bounds.height) - marginY);
      return {x, y};
    }

    updateViewports(target) {
      let viewportDifference;
      if (target == null) { ({
        target
      } = this); }
      const sv = {width: this.canvasWidth / this.zoom, height: this.canvasHeight / this.zoom, cx: target.x, cy: target.y};
      sv.x = sv.cx - (sv.width / 2);
      sv.y = sv.cy - (sv.height / 2);
      if (this.surfaceViewport) {
        // Calculate how different this viewport is. (If it's basically not different, we can avoid visualizing the update.)
        viewportDifference = Math.abs(this.surfaceViewport.x - sv.x) + (1.01 * Math.abs(this.surfaceViewport.y - sv.y)) + (1.02 * Math.abs(this.surfaceViewport.width - sv.width));
      } else {
        viewportDifference = 9001;
      }
      this.surfaceViewport = sv;

      const wv = this.surfaceToWorld(sv);  // get x and y
      wv.width = sv.width * Camera.MPP;
      wv.height = sv.height * Camera.MPP * this.x2y;
      wv.cx = wv.x + (wv.width / 2);
      wv.cy = wv.y + (wv.height / 2);
      this.worldViewport = wv;

      return viewportDifference;
    }

    lock() {
      this.target = this.currentTarget;
      return this.locked = true;
    }

    unlock() {
      return this.locked = false;
    }

    destroy() {
      createjs.Tween.removeTweens(this);
      return super.destroy();
    }

    onZoomTo(e) {
      return this.zoomTo(this.worldToSurface(e.pos), this.zoom, e.duration);
    }
  };
  Camera.initClass();
  return Camera;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}