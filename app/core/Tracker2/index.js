import SegmentTracker from './SegmentTracker'
import CookieConsentTracker from './CookieConsentTracker'
import InternalTracker from './InternalTracker'
import BaseTracker from './BaseTracker'
import GoogleAnalyticsTracker from './GoogleAnalyticsTracker'
import FullStoryTracker from './FullStoryTracker'
import FacebookPixelTracker from './FacebookPixelTracker'
import TwitterPixelTracker from './TwitterPixelTracker'
import ProfitWellTracker from './ProfitWellTracker'
import MakelogTracker from './MakelogTracker'
import ZendeskTracker from './ZendeskTracker'
import SuperflowTracker from './SuperflowTracker'

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
    this.internalTracker = new InternalTracker(this.store)
    this.segmentTracker = new SegmentTracker(this.store)
    this.googleAnalyticsTracker = new GoogleAnalyticsTracker(this.store)
    this.fullStoryTracker = new FullStoryTracker(this.store, this)
    this.facebookPixelTracker = new FacebookPixelTracker(this.store)
    this.profitWellTracker = new ProfitWellTracker(this.store)
    this.makelogTracker = new MakelogTracker(this.store)
    this.twitterPixelTracker = new TwitterPixelTracker(this.store)
    this.zendeskTracker = new ZendeskTracker(this.store)
    this.superflowTracker = new SuperflowTracker(this.store)

    this.trackers = [
      this.internalTracker,
      this.makelogTracker
    ]

    const isGlobal = !(window.features || {}).china
    if (isGlobal) {
      // add trackers we don't want china to enable here.
      this.trackers = [
        ...this.trackers,
        this.segmentTracker,
        this.googleAnalyticsTracker,
        this.fullStoryTracker,
        this.facebookPixelTracker,
        this.twitterPixelTracker,
        this.profitWellTracker,
        this.zendeskTracker,
        this.superflowTracker
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

  async trackPageView () {
    try {
      await this.initializationComplete

      await allSettled(
        this.trackers.map(t => t.trackPageView())
      )
    } catch (e) {
      this.log('trackPageView call failed', e)
    }
  }

  async trackEvent (action, properties = {}) {
    try {
      await this.initializationComplete
      const result = await allSettled(
        this.trackers.map(t => t.trackEvent(action, properties))
      )
      if (Array.isArray(result)) {
        result.forEach((r) => {
          if (r.status === 'rejected')
            console.error('trackEvent failed', r)
        })
      }
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

  identifyAfterNextPageLoad () {
    window.sessionStorage.setItem(SESSION_STORAGE_IDENTIFY_ON_NEXT_PAGE_LOAD, 'true')
  }
}
