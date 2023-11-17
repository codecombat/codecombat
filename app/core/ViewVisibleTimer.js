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
const CocoClass = require('core/CocoClass');

const idleTracker = new Idle({
  onAway() {
    return Backbone.Mediator.publish('view-visibility:away', {});
  },
  onAwayBack() {
    return Backbone.Mediator.publish('view-visibility:away-back', {});
  },
  onHidden() {
    return Backbone.Mediator.publish('view-visibility:hidden', {});
  },
  onVisible() {
    return Backbone.Mediator.publish('view-visibility:visible', {});
  },
  awayTimeout: 1000
});

idleTracker.start();

/*
This adds analytics events for when premium features are viewed.

Notes about the structure:

CocoView will trigger an update to the timer, if it exists, any time the view
is hidden/reappears/is inserted.

Any view inheriting from CocoView can call @trackTimeVisible(), which creates
the viewVisibleTimer which CocoView will manage automatically.

Calling @trackTimeVisible({ trackViewLifecycle: true }) will treat the view
being open as the only feature being tracked for that view.

If trackViewLifecycle is not set, the view must implement currentVisiblePremiumFeature
which should return an object describing the premium feature currently in view, or null if none are visible.
CocoView's updateViewVisibleTimer will call this function and update the timer if necessary.

The view should also call updateViewVisibleTimer after any time the visible premium feature may have changed. This function is idempotent.
*/
class ViewVisibleTimer extends CocoClass {
  static initClass() {
    this.prototype.subscriptions = {
      'view-visibility:away': 'onAway',
      'view-visibility:away-back': 'onAwayBack',
      'view-visibility:hidden': 'onHidden',
      'view-visibility:visible': 'onVisible'
    };
  }

  constructor() {
    super();
    this.running = false;
    // If the user is inactive for this many seconds, stop the timer and
    //   record the time they were active (NOT including this timeout)
    // If they come back before this timeout, include the time they were "away"
    //   in the timer
    this.awayTimeoutLimit = 5 * 1000;
    this.awayTimeoutId = null;
    this.throttleRate = 50;
  }

  startTimer(featureData) {
    this.featureData = featureData;
    const { viewName, featureName, premiumThang } = this.featureData;
    if (!viewName) {
      throw new Error('No view name!');
    }
    if (this.running && ((window.performance.now() - this.startTime) > this.throttleRate)) {
      throw(new Error('Starting a timer over another one!'));
    }
    if (!this.running && (!this.startTime || ((window.performance.now() - this.startTime) > this.throttleRate))) {
      this.running = true;
      return this.startTime = window.performance.now();
    }
  }

  stopTimer(param){
    if (param == null) { param = { }; }
    let { subtractTimeout, clearName } = param;
    if (subtractTimeout == null) { subtractTimeout = false; }
    if (clearName == null) { clearName = false; }
    clearTimeout(this.awayTimeoutId);
    if (this.running) {
      this.running = false;
      this.endTime = subtractTimeout ? this.lastActive : window.performance.now();
      const timeViewed = this.endTime - this.startTime;
      if (timeViewed > this.throttleRate) { // Prevent event spam when triggered in rapid succession
        window.tracker.trackEvent('Premium Feature Viewed', { featureData: this.featureData, timeViewed });
      }
    }
    if (clearName) { return this.featureData = null; }
  }

  markLastActive() {
    return this.lastActive = window.performance.now();
  }

  onAway() {
    this.markLastActive();
    const e = new Error();
    if (this.running) {
      return this.awayTimeoutId = setTimeout(( () => {
        return this.stopTimer({ subtractTimeout: true });
      }
      ), this.awayTimeoutLimit);
    }
  }

  onAwayBack() {
    clearTimeout(this.awayTimeoutId);
    if (!this.running && this.featureData) { return this.startTimer(this.featureData); }
  }

  onHidden() {
    return this.stopTimer({ subtractTimeout: false });
  }

  onVisible() {
    if (this.featureData) { return this.startTimer(this.featureData); }
  }

  destroy() {
    this.stopTimer();
    return super.destroy();
  }
}
ViewVisibleTimer.initClass();

module.exports = ViewVisibleTimer;
