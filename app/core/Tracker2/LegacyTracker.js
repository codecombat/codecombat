import CocoLegacyTracker from '../Tracker'
import BaseTracker from './BaseTracker'

/**
 * Acts as a proxy between our new tracker and our legacy Tracker.coffee
 * which still handles segment.io and GA tracking.  This tracker also binds
 * application events to the legacy tracker and exposes legacy tracker methods
 * externally as necessary.
 *
 * TODO remove this tracker when tracker refactor is complete.
 */
export default class LegacyTracker extends BaseTracker {
  constructor (store, cookieConsent) {
    super()

    this.store = store
    this.cookieConsent = cookieConsent
  }

  async _initializeTracker () {
    this.legacyTracker = new CocoLegacyTracker()

    this.cookieConsent.on('change', () => {
      this.legacyTracker.cookies = this.cookieConsent.getStatus()
    })

    this.legacyTracker.finishInitialization()

    this.onInitializeSuccess()
  }

  async identify (traits = {}) {
    // The Tracker.coffee implementation of identify seems to assume that it is called through
    // other internal methods like updateRole and updateTrialRequestAttributes (or at least
    // that these other internal methods are called first).  The implementation of updateRole
    // does some simple filtering, calls segment and then simply calls identify internally
    // so instead of refactoring the tracker to load segment in identify, we just use this
    // method in place of identify.
    this.legacyTracker.updateRole(traits)
  }

  async trackPageView (includeIntegrations = {}) {
    this.legacyTracker.trackPageView(includeIntegrations)
  }

  async trackEvent (action, properties = {}, includeIntegrations = {}) {
    this.legacyTracker.trackEvent(action, properties, includeIntegrations)
  }

  async trackTiming (duration, category, variable, label) {
    this.legacyTracker.trackTiming(duration, category, variable, label)
  }
}
