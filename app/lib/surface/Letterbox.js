// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Letterbox;
const createjs = require('lib/createjs-parts');

module.exports = (Letterbox = (function() {
  Letterbox = class Letterbox extends createjs.Container {
    static initClass() {
      this.prototype.subscriptions =
        {'level:set-letterbox': 'onSetLetterbox'};
    }

    constructor(options) {
      super();
      this.initialize();
      this.canvasWidth = options.canvasWidth;
      this.canvasHeight = options.canvasHeight;
      if (!this.canvasWidth || !this.canvasHeight) { console.error('Letterbox needs canvasWidth/Height.'); }
      this.build();
      for (var channel in this.subscriptions) { var func = this.subscriptions[channel]; Backbone.Mediator.subscribe(channel, this[func], this); }
    }

    build() {
      this.mouseEnabled = (this.mouseChildren = false);
      this.matteHeight = 0.10 * this.canvasHeight;
      this.upperMatte = new createjs.Shape();
      this.upperMatte.graphics.beginFill('black').rect(0, 0, this.canvasWidth, this.matteHeight);
      this.lowerMatte = this.upperMatte.clone();
      this.upperMatte.x = (this.lowerMatte.x = 0);
      this.upperMatte.y = -this.matteHeight;
      this.lowerMatte.y = this.canvasHeight;
      return this.addChild(this.upperMatte, this.lowerMatte);
    }

    onSetLetterbox(e) {
      const T = createjs.Tween;
      T.removeTweens(this.upperMatte);
      T.removeTweens(this.lowerMatte);
      const upperY = e.on ? 0 : -this.matteHeight;
      const lowerY = e.on ? this.canvasHeight - this.matteHeight : this.canvasHeight;
      const interval = 700;
      const ease = createjs.Ease.cubicOut;
      T.get(this.upperMatte).to({y: upperY}, interval, ease);
      return T.get(this.lowerMatte).to({y: lowerY}, interval, ease);
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
  };
  Letterbox.initClass();
  return Letterbox;
})());
