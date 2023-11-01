/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DebugDisplay;
const createjs = require('lib/createjs-parts');

module.exports = (DebugDisplay = (function() {
  DebugDisplay = class DebugDisplay extends createjs.Container {
    static initClass() {
      this.prototype.layerPriority = 20;
      this.prototype.subscriptions =
        {'level:set-debug': 'onSetDebug'};
    }

    constructor(options) {
      super();
      this.initialize();
      this.canvasWidth = options.canvasWidth;
      this.canvasHeight = options.canvasHeight;
      if (!this.canvasWidth || !this.canvasHeight) { console.error('DebugDisplay needs canvasWidth/Height.'); }
      this.build();
      this.onSetDebug({debug: true});
      for (var channel in this.subscriptions) { var func = this.subscriptions[channel]; Backbone.Mediator.subscribe(channel, this[func], this); }
    }

    destroy() {
      return (() => {
        const result = [];
        for (var channel in this.subscriptions) {
          var func = this.subscriptions[channel];
          result.push(Backbone.Mediator.unsubscribe(channel, this[func], this));
        }
        return result;
      })();
    }

    onSetDebug(e) {
      if (e.debug === this.on) { return; }
      this.visible = (this.on = e.debug);
      this.fps = null;
      this.framesRenderedThisSecond = 0;
      return this.lastFrameSecondStart = Date.now();
    }

    build() {
      this.mouseEnabled = (this.mouseChildren = false);
      this.addChild(this.frameText = new createjs.Text('...', '20px Arial', '#FFF'));
      this.frameText.name = 'frame text';
      this.frameText.x = this.canvasWidth - 50;
      this.frameText.y = this.canvasHeight - 25;
      return this.frameText.alpha = 0.5;
    }

    updateFrame(currentFrame) {
      if (!this.on) { return; }
      ++this.framesRenderedThisSecond;
      const time = Date.now();
      const diff = (time - this.lastFrameSecondStart) / 1000;
      if (diff > 1) {
        this.fps = Math.round(this.framesRenderedThisSecond / diff);
        this.lastFrameSecondStart = time;
        this.framesRenderedThisSecond = 0;
      }

      this.frameText.text = Math.round(currentFrame) + ((this.fps != null) ? ' - ' + this.fps + ' fps' : '');
      return this.frameText.x = this.canvasWidth - this.frameText.getMeasuredWidth() - 10;
    }
  };
  DebugDisplay.initClass();
  return DebugDisplay;
})());
