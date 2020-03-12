import SegmentTracker from './SegmentTracker'
import CookieConsentTracker from './CookieConsentTracker'
import LegacyTracker from './LegacyTracker'
import BaseTracker from './BaseTracker'
import GoogleAnalyticsTracker from './GoogleAnalyticsTracker'
import DriftTracker from './DriftTracker'

/**
 * Top level application tracker that handles sub tracker initialization and
 * event routing.
 */
export default class Tracker2 extends BaseTracker {
  constructor (store) {
    super()

    this.store = store

    // TODO consent status needs to be propagated to other trackers
    this.cookieConsentTracker = new CookieConsentTracker(this.store)

    this.legacyTracker = new LegacyTracker(this.store, this.cookieConsentTracker)
    this.segmentTracker = new SegmentTracker()
    this.googleAnalyticsTracker = new GoogleAnalyticsTracker()
    this.driftTracker = new DriftTracker(this.store)

    this.trackers = [
      this.legacyTracker,
      this.googleAnalyticsTracker,
      this.driftTracker,

      // Segment tracking is currently handled by the legacy tracker
      // this.segmentTracker,
    ]
  }

  async _initializeTracker () {
    try {
      await Promise.all([
        this.cookieConsentTracker.initialize(),

        ...this.trackers.map(t => t.initialize())
      ])

      this.onInitializeSuccess()
    } catch (e) {
      this.onInitializeFail(e)
    }
  }

  async identify (traits = {}) {
    await this.initializationComplete

    await Promise.all(
      this.trackers.map(t => t.identify(traits))
    )
  }

  async trackPageView (includeIntegrations = {}) {
    await this.initializationComplete

    await Promise.all(
      this.trackers.map(t => t.trackPageView(includeIntegrations))
    )
  }

  async trackEvent (action, properties = {}, includeIntegrations = {}) {
    await this.initializationComplete

    await Promise.all(
      this.trackers.map(t => t.trackEvent(action, properties, includeIntegrations))
    )
  }

  async trackTiming (duration, category, variable, label) {
    await this.initializationComplete

    await Promise.all(
      this.trackers.map(t => t.trackTiming(duration, category, variable, label))
    )
  }

  get drift () {
    return this.driftTracker.drift
  }
}
