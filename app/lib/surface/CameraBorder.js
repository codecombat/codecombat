/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CameraBorder;
const createjs = require('lib/createjs-parts');

module.exports = (CameraBorder = (function() {
  CameraBorder = class CameraBorder extends createjs.Container {
    static initClass() {
      this.prototype.layerPriority = 100;
  
      this.prototype.subscriptions = {};
    }

    constructor(options) {
      super();
      this.initialize();
      this.mouseEnabled = (this.mouseChildren = false);
      this.updateBounds(options.bounds);
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

    updateBounds(bounds) {
      if (_.isEqual(bounds, this.bounds)) { return; }
      this.bounds = bounds;
      if (this.border) {
        this.removeChild(this.border);
        this.border = null;
      }
      if (!this.bounds) { return; }
      this.addChild(this.border = new createjs.Shape());
      const width = 20;
      let i = width;
      while (i) {
        var opacity = (3 * (1 - (i/width))) / width;
        this.border.graphics.setStrokeStyle(i, 'round').beginStroke(`rgba(0,0,0,${opacity})`).drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
        i -= 1;
      }
      return this.border.cache(bounds.x, bounds.y, bounds.width, bounds.height);
    }
  };
  CameraBorder.initClass();
  return CameraBorder;
})());
