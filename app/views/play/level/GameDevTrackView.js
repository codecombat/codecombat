/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GameDevTrackView;
require('app/styles/play/level/game_dev_track_view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/game_dev_track_view');

module.exports = (GameDevTrackView = (function() {
  GameDevTrackView = class GameDevTrackView extends CocoView {
    static initClass() {
      this.prototype.id = 'game-dev-track-view';
      this.prototype.template = template;
  
      this.prototype.subscriptions = {
        'surface:frame-changed': 'onFrameChanged',
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
      };
    }

    constructor(options) {
      super(options);
      this.listings = {};
    }

    onFrameChanged(e) {
      let name;
      this.listings = {};
      // Can be set by a user via `ui.setText("scoreLabel", "overrideLabel")`
      const overrideLabel = e.world.uiText != null ? e.world.uiText.scoreLabel : undefined;
      if (e.world.synchronous) {
        let hero;
        for (var thang of Array.from(e.world.thangs)) {
          var trackedProperties;
          if (thang.id === 'Hero Placeholder') {
            hero = thang;
          }
          if (trackedProperties = thang.uiTrackedProperties) {
            for (name of Array.from(trackedProperties)) {
              this.listings[overrideLabel != null ? overrideLabel : name] = thang[name];
            }
          }
        }
        if (hero && hero.objTrackedProperties) {
          for (name of Array.from(hero.objTrackedProperties)) {
            this.listings[overrideLabel != null ? overrideLabel : name] = hero['__' + name];
          }
        }
      } else {
        const thangStateMap = e.world.frames[e.frame] != null ? e.world.frames[e.frame].thangStateMap : undefined;
        for (var key in thangStateMap) {
          var propIndex;
          var thangState = thangStateMap[key];
          if (!thangState.trackedPropertyKeys) { continue; }
          var trackedPropNamesIndex = thangState.trackedPropertyKeys.indexOf('uiTrackedProperties');
          if (trackedPropNamesIndex !== -1) {
            var trackedPropNames = thangState.props[trackedPropNamesIndex];
            if (trackedPropNames) {
              for (name of Array.from(trackedPropNames)) {
                propIndex = thangState.trackedPropertyKeys.indexOf(name);
                if (propIndex === -1) { continue; }
                this.listings[overrideLabel != null ? overrideLabel : name] = thangState.props[propIndex];
              }
            }
          }
          if (key !== 'Hero Placeholder') { continue; }
          var trackedObjNamesIndex = thangState.trackedPropertyKeys.indexOf('objTrackedProperties');
          if (trackedObjNamesIndex === -1) { continue; }
          var trackedObjNames = thangState.props[trackedObjNamesIndex];
          for (name of Array.from(trackedObjNames)) {
            propIndex = thangState.trackedPropertyKeys.indexOf('__' + name);
            if (propIndex === -1) { continue; }
            this.listings[overrideLabel != null ? overrideLabel : name] = thangState.props[propIndex];
          }
        }
      }
      if (!_.isEqual(this.listings, {})) {
        this.$el.show();
        return this.renderSelectors('#listings');
      } else {
        return this.$el.hide();
      }
    }

    onRealTimePlaybackStarted(e) {
      return this.$el.addClass('playback-float-right');
    }

    onRealTimePlaybackEnded(e) {
      return this.$el.removeClass('playback-float-right');
    }

    titleize(name) {
      return _.string.titleize(_.string.humanize(name));
    }

    beautify(name, val) {
      if ((typeof val === 'object') && (val.x != null) && (val.y != null) && (val.z != null)) {
        return `x: ${Math.round(val.x)}\ny: ${Math.round(val.y)}`;
      }
      if (typeof val === 'number') {
        const round = Math.round(val);
        return round;
      }
      return val != null ? val : '';
    }
  };
  GameDevTrackView.initClass();
  return GameDevTrackView;
})());
