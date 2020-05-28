import SegmentTracker from './SegmentTracker'
import CookieConsentTracker from './CookieConsentTracker'
import LegacyTracker from './LegacyTracker'
import BaseTracker from './BaseTracker'
import GoogleAnalyticsTracker from './GoogleAnalyticsTracker'
import DriftTracker from './DriftTracker'
import ProofTracker from './ProofTracker'
import FullStoryTracker from './FullStoryTracker'

const SESSION_STORAGE_IDENTIFIED_AT_SESSION_START_KEY = 'coco.tracker.identifiedAtSessionStart'
const SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD = 'coco.tracker.identifyOnNextPageLoad'

/**
 * Top level application tracker that handles sub tracker initialization and
 * event routing.
 */
export default class Tracker2 extends BaseTracker {
  constructor (store) {
    super()

    this.store = store

    this.cookieConsentTracker = new CookieConsentTracker(this.store)

    this.legacyTracker = new LegacyTracker(this.store, this.cookieConsentTracker)
    this.segmentTracker = new SegmentTracker(this.store)
    // this.googleAnalyticsTracker = new GoogleAnalyticsTracker()
    this.driftTracker = new DriftTracker(this.store)
    this.proofTracker = new ProofTracker(this.store)
    this.fullStoryTracker = new FullStoryTracker(this.store, this)

    this.trackers = [
      this.legacyTracker,
      // this.googleAnalyticsTracker,
      this.driftTracker,
      this.segmentTracker,
      this.proofTracker,
      this.fullStoryTracker
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

    await this.initializationComplete

    let callIdentify = false

    // Check initialize on page load
    const initializeOnNextPageLoad = window.sessionStorage.getItem(SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD)
    if (initializeOnNextPageLoad === 'true') {
      window.sessionStorage.removeItem(SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD)
      callIdentify = true
    }

    const identifiedThisSession = window.sessionStorage.getItem(SESSION_STORAGE_IDENTIFIED_AT_SESSION_START_KEY)
    if (identifiedThisSession !== 'true') {
      callIdentify = true
      window.sessionStorage.setItem(SESSION_STORAGE_IDENTIFIED_AT_SESSION_START_KEY, 'true')
    }

    if (callIdentify) {
      this.identify()
    }
  }


  async identify (traits = {}) {
    await this.initializationComplete

    await Promise.all(
      this.trackers.map(t => t.identify(traits))
    )
  }

  async resetIdentity () {
    await this.initializationComplete

    await Promise.all(
      this.trackers.map(t => t.resetIdentity())
    )

    window.sessionStorage.removeItem(SESSION_STORAGE_IDENTIFIED_AT_SESSION_START_KEY)
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

  identifyAfterNextPageLoad () {
    window.sessionStorage.setItem(SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD, 'true')
  }
}
