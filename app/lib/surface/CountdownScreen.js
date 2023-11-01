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
let CountdownScreen;
const CocoClass = require('core/CocoClass');
const createjs = require('lib/createjs-parts');

module.exports = (CountdownScreen = (function() {
  CountdownScreen = class CountdownScreen extends CocoClass {
    static initClass() {
      this.prototype.subscriptions = {
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
      };
    }

    constructor(options) {
      super();
      this.decrementCountdown = this.decrementCountdown.bind(this);
      if (options == null) { options = {}; }
      this.camera = options.camera;
      this.layer = options.layer;
      this.showsCountdown = options.showsCountdown;
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      this.build();
    }

    destroy() {
      if (this.countdownInterval) { clearInterval(this.countdownInterval); }
      return super.destroy();
    }

    onCastingBegins(e) { if (!e.preload) { return this.show(); } }
    onCastingEnds(e) { return this.hide(); }

    toString() { return '<CountdownScreen>'; }

    build() {
      this.dimLayer = new createjs.Container();
      this.dimLayer.mouseEnabled = (this.dimLayer.mouseChildren = false);
      this.dimLayer.addChild(this.dimScreen = new createjs.Shape());
      this.dimScreen.graphics.beginFill('rgba(0,0,0,0.5)').rect(0, 0, this.camera.canvasWidth, this.camera.canvasHeight);
      this.dimLayer.alpha = 0;
      return this.dimLayer.addChild(this.makeCountdownText());
    }

    makeCountdownText() {
      const size = Math.ceil(this.camera.canvasHeight / 2);
      const text = new createjs.Text('3...', `${size}px Open Sans Condensed`, '#F7B42C');
      text.shadow = new createjs.Shadow('#000', Math.ceil(this.camera.canvasHeight / 300), Math.ceil(this.camera.canvasHeight / 300), Math.ceil(this.camera.canvasHeight / 120));
      text.textAlign = 'center';
      text.textBaseline = 'middle';
      text.x = this.camera.canvasWidth / 2;
      text.y = this.camera.canvasHeight / 2;
      this.text = text;
      return text;
    }

    show() {
      if (this.showing) { return; }
      createjs.Tween.removeTweens(this.dimLayer);
      if (this.showsCountdown) {
        this.dimLayer.alpha = 0;
        this.showing = true;
        createjs.Tween.get(this.dimLayer).to({alpha: 1}, 500);
        this.secondsRemaining = 3;
        this.countdownInterval = setInterval(this.decrementCountdown, 1000);
        this.updateText();
        return this.layer.addChild(this.dimLayer);
      } else {
        return this.endCountdown();
      }
    }

    hide(duration) {
      if (duration == null) { duration = 500; }
      if (!this.showing) { return; }
      this.showing = false;
      createjs.Tween.removeTweens(this.dimLayer);
      return createjs.Tween.get(this.dimLayer).to({alpha: 0}, duration).call(() => { if (!this.destroyed) { return this.layer.removeChild(this.dimLayer); } });
    }

    decrementCountdown() {
      if (this.destroyed) { return; }
      --this.secondsRemaining;
      this.updateText();
      if (!this.secondsRemaining) {
        return this.endCountdown();
      }
    }

    updateText() {
      return this.text.text = this.secondsRemaining ? `${this.secondsRemaining}...` : '0!';
    }

    endCountdown() {
      console.log('should actually start in 1s');
      if (this.countdownInterval) { clearInterval(this.countdownInterval); }
      this.countdownInterval = null;
      return this.hide();
    }

    onRealTimePlaybackStarted(e) {
      return this.show();
    }

    onRealTimePlaybackEnded(e) {
      if (this.countdownInterval) { clearInterval(this.countdownInterval); }
      this.countdownInterval = null;
      return this.hide(Math.max(500, 1000 * (this.secondsRemaining || 0)));
    }
  };
  CountdownScreen.initClass();
  return CountdownScreen;
})());
