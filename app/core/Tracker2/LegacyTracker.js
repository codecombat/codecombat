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

    this.legacyTracker.cookies = this.store.state.tracker.cookieConsent
    this.store.watch(
      (state) => state.tracker.cookieConsent,
      (status) => this.legacyTracker.cookies = status
    )
    this.legacyTracker.finishInitialization()
    this.onInitializeSuccess()
  }

  async identify (traits = {}) {
    this.legacyTracker.identify(traits)
  }

  async trackPageView (includeIntegrations = []) {
    this.legacyTracker.trackPageView(includeIntegrations)
  }

  async trackEvent (action, properties = {}, includeIntegrations = {}) {
    this.legacyTracker.trackEvent(action, properties, includeIntegrations)
  }

  async trackTiming (duration, category, variable, label) {
    this.legacyTracker.trackTiming(duration, category, variable, label)
  }
}
