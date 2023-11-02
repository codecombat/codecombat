// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const createjs = require('lib/createjs-parts');

var Dropper = (Dropper = (function() {
  Dropper = class Dropper {
    static initClass() {
      this.prototype.lostFrames = 0.0;
      this.prototype.dropCounter = 0;
    }

    constructor() {
      this.listener = e => this.tick(e);
    }

    tick() {
      if (!this.tickedOnce) {
        this.tickedOnce = true;  // Can't get measured FPS on the 0th frame.
        return;
      }

      if (this.dropCounter > 0) { --this.dropCounter; }

      // Track number of frames we've lost since the last tick.
      const fps = createjs.Ticker.framerate;
      const actual = createjs.Ticker.getMeasuredFPS(1);
      this.lostFrames += (fps - actual) / fps;

      // If lostFrames > 1, drop that number for the next tick.
      this.dropCounter += parseInt(this.lostFrames);
      return this.lostFrames = this.lostFrames % 1;
    }

    drop() {
      return this.dropCounter > 0;
    }
  };
  Dropper.initClass();
  return Dropper;
})());

module.exports = new Dropper();
