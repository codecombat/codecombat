// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoordinateDisplay;
const createjs = require('lib/createjs-parts');
const utils = require('core/utils');

const DEFAULT_DISPLAY_OPTIONS = {
  fontWeight: 'bold',
  fontSize: '16px',
  fontFamily: 'Arial',
  fontColor: '#FFFFFF',
  templateString: {
    ozaria: '<%= x %>, <%= y %>',
    codecombat: '{x: <%= x %>, y: <%= y %>}'
  }[utils.isOzaria ? 'ozaria' : 'codecombat'],  // utils.getProduct()
  backgroundFillColor: 'rgba(0,0,0,0.4)',
  backgroundStrokeColor: 'rgba(0,0,0,0.6)',
  backgroundStroke: 1,
  backgroundMargin: 3,
  pointMarkerColor: 'rgb(255, 255, 255)',
  pointMarkerLength: 8,
  pointMarkerStroke: 2
};

module.exports = (CoordinateDisplay = (function() {
  CoordinateDisplay = class CoordinateDisplay extends createjs.Container {
    static initClass() {
      this.prototype.layerPriority = -10;
      this.prototype.subscriptions = {
        'surface:mouse-moved': 'onMouseMove',
        'surface:mouse-out': 'onMouseOut',
        'surface:mouse-over': 'onMouseOver',
        'surface:stage-mouse-down': 'onMouseDown',
        'camera:zoom-updated': 'onZoomUpdated',
        'level:flag-color-selected': 'onFlagColorSelected',
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
      };
    }

    constructor(options) {
      super();
      this.show = this.show.bind(this);
      this.initialize();
      this.camera = options.camera;
      this.layer = options.layer;
      this.displayOptions = _.merge({}, DEFAULT_DISPLAY_OPTIONS, options.displayOptions || {});
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      this.build();
      this.disabled = false;
      this.performShow = this.show;
      this.show = _.debounce(this.show, 125);
      for (var channel in this.subscriptions) { var func = this.subscriptions[channel]; Backbone.Mediator.subscribe(channel, this[func], this); }
    }

    destroy() {
      for (var channel in this.subscriptions) { var func = this.subscriptions[channel]; Backbone.Mediator.unsubscribe(channel, this[func], this); }
      this.show = null;
      return this.destroyed = true;
    }

    toString() { return '<CoordinateDisplay>'; }

    build() {
      this.mouseEnabled = (this.mouseChildren = false);
      this.addChild(this.background = new createjs.Shape());
      this.addChild(this.label = new createjs.Text('', `${this.displayOptions.fontWeight} ${this.displayOptions.fontSize} ${this.displayOptions.fontFamily}`, this.displayOptions.fontColor));
      this.addChild(this.pointMarker = new createjs.Shape());
      this.label.name = 'Coordinate Display Text';
      this.label.shadow = new createjs.Shadow('#000000', 1, 1, 0);
      this.background.name = 'Coordinate Display Background';
      this.pointMarker.name = 'Point Marker';
      return this.layer.addChild(this);
    }

    onMouseOver(e) { return this.mouseInBounds = true; }
    onMouseOut(e) { return this.mouseInBounds = false; }

    onMouseMove(e) {
      if (this.disabled) { return; }
      const wop = this.camera.screenToWorld({x: e.x, y: e.y});
      if (key.alt) {
        wop.x = Math.round(wop.x * 1000) / 1000;
        wop.y = Math.round(wop.y * 1000) / 1000;
      } else {
        wop.x = Math.round(wop.x);
        wop.y = Math.round(wop.y);
      }
      if ((wop.x === (this.lastPos != null ? this.lastPos.x : undefined)) && (wop.y === (this.lastPos != null ? this.lastPos.y : undefined))) { return; }
      this.lastPos = wop;
      this.lastSurfacePos = this.camera.worldToSurface(this.lastPos);
      this.lastScreenPos = {x: e.x, y: e.y};
      if (key.alt) {
        return this.performShow();
      } else {
        this.hide();
        return this.show();  // debounced
      }
    }

    onMouseDown(e) {
      if (!key.shift) { return; }
      const wop = this.camera.screenToWorld({x: e.x, y: e.y});
      wop.x = Math.round(wop.x);
      wop.y = Math.round(wop.y);
      Backbone.Mediator.publish('tome:focus-editor', {});
      return Backbone.Mediator.publish('surface:coordinate-selected', wop);
    }

    onZoomUpdated(e) {
      if (!this.lastPos) { return; }
      const wop = this.camera.screenToWorld(this.lastScreenPos);
      this.lastPos.x = Math.round(wop.x);
      this.lastPos.y = Math.round(wop.y);
      if (this.label.parent) { return this.performShow(); }
    }

    onFlagColorSelected(e) {
      return this.placingFlag = Boolean(e.color);
    }

    onRealTimePlaybackStarted(e) {
      if (this.disabled) { return; }
      this.disabled = true;
      return this.hide();
    }

    onRealTimePlaybackEnded(e) {
      return this.disabled = false;
    }

    hide() {
      if (!this.label.parent) { return; }
      this.removeChild(this.label);
      this.removeChild(this.background);
      this.removeChild(this.pointMarker);
      return this.uncache();
    }

    updateSize() {
      let horizontalEdge, verticalEdge;
      const margin = this.displayOptions.backgroundMargin;
      const contentWidth = this.label.getMeasuredWidth() + (2 * margin);
      const contentHeight = this.label.getMeasuredHeight() + (2 * margin);

      // Shift pointmarker up so it centers at pointer (affects container cache position)
      this.pointMarker.regY = contentHeight;

      const {
        pointMarkerStroke
      } = this.displayOptions;
      const {
        pointMarkerLength
      } = this.displayOptions;
      const fullPointMarkerLength = pointMarkerLength + (pointMarkerStroke / 2);
      let contributionsToTotalSize = [];
      contributionsToTotalSize = contributionsToTotalSize.concat(this.updateCoordinates(contentWidth, contentHeight, fullPointMarkerLength));
      contributionsToTotalSize = contributionsToTotalSize.concat(this.updatePointMarker(0, contentHeight, pointMarkerLength, pointMarkerStroke));

      const totalWidth = contentWidth + contributionsToTotalSize.reduce((a, b) => a + b);
      const totalHeight = contentHeight + contributionsToTotalSize.reduce((a, b) => a + b);

      if (this.isNearTopEdge(totalHeight)) {
        verticalEdge = {
          startPos: -fullPointMarkerLength,
          posShift: -2 * fullPointMarkerLength
        };
      } else {
        verticalEdge = {
          startPos: -totalHeight + fullPointMarkerLength,
          posShift: contentHeight
        };
      }

      if (this.isNearRightEdge(totalWidth)) {
        horizontalEdge = {
          startPos: -totalWidth + fullPointMarkerLength,
          posShift: totalWidth
        };
      } else {
        horizontalEdge = {
          startPos: -fullPointMarkerLength,
          posShift: 0
        };
      }

      return this.orient(verticalEdge, horizontalEdge, totalHeight, totalWidth);
    }

    isNearTopEdge(height) {
      return (height - this.lastSurfacePos.y) > this.camera.surfaceViewport.height;
    }

    isNearRightEdge(width) {
      return (this.lastSurfacePos.x + width) > this.camera.surfaceViewport.width;
    }

    orient(verticalEdge, horizontalEdge, totalHeight, totalWidth) {
      this.label.regY = (this.background.regY = verticalEdge.posShift);
      this.label.regX = (this.background.regX = horizontalEdge.posShift);
      return this.cache(horizontalEdge.startPos, verticalEdge.startPos, totalWidth, totalHeight);
    }

    updateCoordinates(contentWidth, contentHeight, offset) {
      // Center label horizontally and vertically
      let backgroundStroke, contributionsToTotalSize, radius;
      this.label.x = ((contentWidth / 2) - (this.label.getMeasuredWidth() / 2)) + offset;
      this.label.y = (contentHeight / 2) - (this.label.getMeasuredHeight() / 2) - offset;

      this.background.graphics
        .clear()
        .beginFill(this.displayOptions.backgroundFillColor)
        .beginStroke(this.displayOptions.backgroundStrokeColor)
        .setStrokeStyle(backgroundStroke = this.displayOptions.backgroundStroke)
        .drawRoundRect(offset, -offset, contentWidth, contentHeight, (radius = 2.5))
        .endFill()
        .endStroke();
      return contributionsToTotalSize = [offset, backgroundStroke];
    }

    updatePointMarker(centerX, centerY, length, strokeSize) {
      let contributionsToTotalSize;
      const strokeStyle = 'square';
      this.pointMarker.graphics
        .beginStroke(this.displayOptions.pointMarkerColor)
        .setStrokeStyle(strokeSize, strokeStyle)
        .moveTo(centerX, centerY - length)
        .lineTo(centerX, centerY + length)
        .moveTo(centerX - length, centerY)
        .lineTo(centerX + length, centerY)
        .endStroke();
      return contributionsToTotalSize = [strokeSize, length];
    }

    show() {
      if (!this.mouseInBounds || !this.lastPos || !!this.destroyed) { return; }
      this.label.text = _.template(this.displayOptions.templateString, {x: this.lastPos.x, y: this.lastPos.y});
      this.updateSize();
      this.x = this.lastSurfacePos.x;
      this.y = this.lastSurfacePos.y;
      this.addChild(this.background);
      this.addChild(this.label);
      if (!this.placingFlag) { this.addChild(this.pointMarker); }
      this.updateCache();
      return Backbone.Mediator.publish('surface:coordinates-shown', {});
    }
  };
  CoordinateDisplay.initClass();
  return CoordinateDisplay;
})());
