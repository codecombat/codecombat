// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PlaybackOverScreen;
import CocoClass from 'core/CocoClass';
import createjs from 'lib/createjs-parts';

export default PlaybackOverScreen = (function() {
  PlaybackOverScreen = class PlaybackOverScreen extends CocoClass {
    static initClass() {
      this.prototype.subscriptions =
        {'goal-manager:new-goal-states': 'onNewGoalStates'};
    }

    constructor(options) {
      super();
      if (options == null) { options = {}; }
      this.camera = options.camera;
      this.layer = options.layer;
      this.playerNames = options.playerNames;
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      this.build();
    }

    toString() { return '<PlaybackOverScreen>'; }

    build() {
      this.dimLayer = new createjs.Container();
      this.dimLayer.mouseEnabled = (this.dimLayer.mouseChildren = false);
      this.dimLayer.addChild(this.dimScreen = new createjs.Shape());
      this.dimLayer.alpha = 0;
      return this.layer.addChild(this.dimLayer);
    }

    makeVictoryText() {
      const s = '';
      const size = Math.ceil(this.camera.canvasHeight / 6);
      const text = new createjs.Text(s, `${size}px Open Sans Condensed`, '#F7B42C');
      text.shadow = new createjs.Shadow('#000', Math.ceil(this.camera.canvasHeight / 300), Math.ceil(this.camera.canvasHeight / 300), Math.ceil(this.camera.canvasHeight / 120));
      text.textAlign = 'center';
      text.textBaseline = 'middle';
      text.x = 0.5 * this.camera.canvasWidth;
      text.y = 0.75 * this.camera.canvasHeight;
      this.dimLayer.addChild(text);
      return this.text = text;
    }

    show() {
      if (this.showing) { return; }
      this.showing = true;
      if (!this.color) { this.updateColor('rgba(212, 212, 212, 0.4)'); }  // If we haven't caught the goal state for the first run, just do something neutral.
      this.dimLayer.alpha = 0;
      createjs.Tween.removeTweens(this.dimLayer);
      return createjs.Tween.get(this.dimLayer).to({alpha: 1}, 500);
    }

    hide() {
      if (!this.showing) { return; }
      this.showing = false;
      createjs.Tween.removeTweens(this.dimLayer);
      return createjs.Tween.get(this.dimLayer).to({alpha: 0}, 500);
    }

    onNewGoalStates(e) {
      const success = e.overallStatus === 'success';
      const failure = e.overallStatus === 'failure';
      const {
        timedOut
      } = e;
      const incomplete = !success && !failure && !timedOut;
      const color = failure ? 'rgba(255, 128, 128, 0.4)' : 'rgba(255, 255, 255, 0.4)';
      this.updateColor(color);
      return this.updateText(e);
    }

    updateColor(color) {
      if (color === this.color) { return; }
      this.dimScreen.graphics.clear().beginFill(color).rect(0, 0, this.camera.canvasWidth, this.camera.canvasHeight);
      if (this.color) {
        this.dimLayer.updateCache();
      } else {
        this.dimLayer.cache(0, 0, this.camera.canvasWidth, this.camera.canvasHeight);
      }
      return this.color = color;
    }

    updateText(goalEvent) {
      let g;
      if (!_.size(this.playerNames)) { return; }  // Only on multiplayer levels
      const teamOverallStatuses = {};

      let goals = goalEvent.goalStates ? _.values(goalEvent.goalStates) : [];
      goals = ((() => {
        const result = [];
        for (g of Array.from(goals)) {           if (!g.optional) {
            result.push(g);
          }
        }
        return result;
      })());
      for (var team of ['humans', 'ogres']) {
        var overallStatus;
        var teamGoals = ((() => {
          const result1 = [];
          for (g of Array.from(goals)) {             if ([undefined, team].includes(g.team)) {
              result1.push(g);
            }
          }
          return result1;
        })());
        var statuses = (Array.from(teamGoals).map((goal) => goal.status));
        if ((statuses.length > 0) && _.every(statuses, s => s === 'success')) { overallStatus = 'success'; }
        if ((statuses.length > 0) && Array.from(statuses).includes('failure')) { overallStatus = 'failure'; }
        teamOverallStatuses[team] = overallStatus;
      }

      if (!this.text) { this.makeVictoryText(); }
      if (teamOverallStatuses.humans === 'success') {
        this.text.color = '#E62B1E';
        this.text.text = ((this.playerNames.humans != null ? this.playerNames.humans : $.i18n.t('ladder.red_ai')) + ' ' + $.i18n.t('ladder.wins')).toLocaleUpperCase();
      } else if (teamOverallStatuses.ogres === 'success') {
        this.text.color = '#0597FF';
        this.text.text = ((this.playerNames.ogres != null ? this.playerNames.ogres : $.i18n.t('ladder.blue_ai')) + ' ' + $.i18n.t('ladder.wins')).toLocaleUpperCase();
      } else {
        this.text.color = '#F7B42C';
        if (goalEvent.timedOut) {
          this.text.text = 'TIMED OUT';
        } else {
          this.text.text = 'INCOMPLETE';
        }
      }
      const defaultSize = Math.ceil(this.camera.canvasHeight / 6);
      const textScaleFactor = Math.min(1, Math.max(0.5, "PLAYERNAME WINS".length / this.text.text.length));
      this.text.scaleX = (this.text.scaleY = textScaleFactor);
      return this.dimLayer.updateCache();
    }
  };
  PlaybackOverScreen.initClass();
  return PlaybackOverScreen;
})();
