import BaseTracker from './BaseTracker'

/**
 * Tracks events to Google Analytics.
 */
export default class GoogleAnalyticsTracker extends BaseTracker {
  constructor (store) {
    super()
    this.store = store
  }

  async _initializeTracker () {
    this.onInitializeSuccess()
  }

  async trackPageView () {
    if (this.disableAllTracking) return
    if (this.store.state.me.isAdmin) return
    if (!ga) return
    const name = Backbone.history.getFragment()
    const url = `/${name}`
    this.log('tracking page view', url)
    // https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
    ga('send', 'pageview', url)
  }

  async trackEvent (action, properties = {}) {
    await this.initializationComplete
    if (this.disableAllTracking) return
    if (this.store.state.me.isAdmin) return
    if (!ga) return
    if (['View Load', 'Script Started', 'Script Ended', 'Heard Sprite'].indexOf(action) !== -1) return
    this.log('tracking event', action, properties)
    // https://developers.google.com/analytics/devguides/collection/analyticsjs/events
    const gaFieldObject = {
      hitType: 'event',
      eventCategory: properties.category || 'All',
      eventAction: action
    }
    if (properties.label) {
      gaFieldObject.eventLabel = properties.label
    }
    if (properties.value || properties.predictedLtv || properties.purchaseAmount) {
      gaFieldObject.eventValue = properties.value || properties.predictedLtv || properties.purchaseAmount
    }
    ga('send', gaFieldObject)
  }

  async trackTiming (duration, category, variable, label) {
    await this.initializationComplete
    if (this.disableAllTracking) return
    if (this.store.state.me.isAdmin) return
    if (!ga) return
    if (!(duration >= 0 && duration < 60 * 60 * 1000)) {
      this.log('not tracking timing--duration too long', duration, category, variable, label)
      return
    }
    this.log('tracking timing', duration, category, variable, label)
    // https://developers.google.com/analytics/devguides/collection/analyticsjs/user-timings
    ga('send', 'timing', category, variable, duration, label)
  }
}
