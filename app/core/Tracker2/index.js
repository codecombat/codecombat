import SegmentTracker from './SegmentTracker'
import CookieConsentTracker from './CookieConsentTracker'
import LegacyTracker from './LegacyTracker'
import BaseTracker from './BaseTracker'
import GoogleAnalyticsTracker from './GoogleAnalyticsTracker'
import DriftTracker from './DriftTracker'
import FullStoryTracker from './FullStoryTracker'
import GoogleOptimizeTracker from './GoogleOptimizeTracker'
import FacebookPixelTracker from './FacebookPixelTracker'

const SESSION_STORAGE_IDENTIFIED_AT_SESSION_START_KEY = 'coco.tracker.identifiedAtSessionStart'
const SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD = 'coco.tracker.identifyOnNextPageLoad'

// Promise.all rejects as soon as the first promise rejects, becomes tracker inits can fail intermittently
// we want to ensure that we give all tracker promise calls time to finish (even if some fail) before we
// resolve the promise representing the combined tracking call.  We use Promise.allSettled when available
// and fall back to Promise.all to achieve this
const allSettled = (Promise.allSettled || Promise.all).bind(Promise)

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
    this.fullStoryTracker = new FullStoryTracker(this.store, this)
    this.googleOptimizeTracker = new GoogleOptimizeTracker();
    this.facebookPixelTracker = new FacebookPixelTracker(this.store)

    this.trackers = [
      this.legacyTracker,
    ]

    const isGlobal = !(window.features || {}).china
    if (isGlobal) {
      // add trackers we don't want china to enable here.
      this.trackers = [
        ...this.trackers,
        this.segmentTracker,
        // this.googleAnalyticsTracker,
        this.driftTracker,
        this.fullStoryTracker,
        this.googleOptimizeTracker,
        this.facebookPixelTracker
      ]
    }
  }

  async _initializeTracker () {
    try {
      const allTrackers = [
        this.cookieConsentTracker,
        ...this.trackers
      ]

      await allSettled(allTrackers.map(t => t.initialize()))
    } catch (e) {
      console.error('Tracker init failed', e)
    } finally {
      // We always allow the master tracker to continue because some sub trackers may have initialized correctly
      this.onInitializeSuccess()
    }

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
    try {
      await this.initializationComplete

      await allSettled(
        this.trackers.map(t => t.identify(traits))
      )
    } catch (e) {
      this.log('identify call failed', e)
    }
  }

  async resetIdentity () {
    try  {
      await this.initializationComplete

      await allSettled(
        this.trackers.map(t => t.resetIdentity())
      )
    } catch (e) {
      this.log('resetIdentity call failed', e)
    }

    window.sessionStorage.removeItem(SESSION_STORAGE_IDENTIFIED_AT_SESSION_START_KEY)
  }

  async trackPageView (includeIntegrations = {}) {
    try {
      await this.initializationComplete

      await allSettled(
        this.trackers.map(t => t.trackPageView(includeIntegrations))
      )
    } catch (e) {
      this.log('trackPageView call failed', e)
    }
  }

  async trackEvent (action, properties = {}, includeIntegrations = {}) {
    try {
      await this.initializationComplete

      await allSettled(
        this.trackers.map(t => t.trackEvent(action, properties, includeIntegrations))
      )
    } catch (e) {
      this.log('trackEvent call failed', e)
    }
  }

  async trackTiming (duration, category, variable, label) {
    try {
      await this.initializationComplete

      await allSettled(
        this.trackers.map(t => t.trackTiming(duration, category, variable, label))
      )
    } catch (e) {
      this.log('trackTiming call failed', e)
    }
  }

  get drift () {
    return this.driftTracker.drift
  }

  identifyAfterNextPageLoad () {
    window.sessionStorage.setItem(SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD, 'true')
  }
}
