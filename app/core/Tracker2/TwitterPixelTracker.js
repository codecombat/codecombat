import BaseTracker from './BaseTracker'

const SUBSCRIBE_EVENTS = { online: 'tw-obu6l-ock8c', home: 'tw-obu6l-ock8d' }
const PURCHASE_EVENT = 'tw-obu6l-ock8a'

// Only send events to Twitter if they're in this list.
const twitterEventActions = {
  'Parents page CTA clicked': 'tw-obu6l-ock7m',
  'Live classes CTA clicked': 'tw-obu6l-ock7o',
  'Email for booking class': 'tw-obu6l-ock7p',
  'Live classes welcome call scheduled': 'tw-obu6l-ock7r',
  'CodeCombat live class booked': 'tw-obu6l-ock7u',
  'Finished Signup': 'tw-obu6l-ockv5',
  'Sales chat opened': 'tw-obu6l-ock7w',
  'Support chat opened': 'tw-obu6l-ock81',
  'Support email opened': 'tw-obu6l-ock83',
  'CreateAccountModal Teacher BasicInfoView Submit Success': 'tw-obu6l-ock85',
  'Teachers Request Demo Form Submitted': 'tw-obu6l-ock88',
  'Checkout initiated': 'tw-obu6l-ock89', // optioins
  'Student licenses purchase success': PURCHASE_EVENT, // options
  'Online classes purchase success': SUBSCRIBE_EVENTS.online, // options
  'Home subscription purchase success': SUBSCRIBE_EVENTS.home, // should include properties: { value: '0.00', currency: 'USD', predicted_ltv: '0.00' }
  UniqueTeacherSignup: 'tw-obu6l-ock8e',
  OzariaUniqueTeacherSignup: 'tw-obu6l-ock8f',
  'Page View': 'tw-obu6l-ocku4'
}

export default class TwitterPixelTracker extends BaseTracker {
  constructor (store) {
    super()
    this.store = store
  }

  async _initializeTracker () {
    this.watchForDisableAllTrackingChanges(this.store)

    !(function (e, t, n, s, u, a) { // eslint-disable-line
      e.twq || (s = e.twq = function () { // eslint-disable-line
        s.exe ? s.exe.apply(s, arguments) : s.queue.push(arguments)
      }, s.version = '1.1', s.queue = [], u = t.createElement(n), u.async = !0, u.src = 'https://static.ads-twitter.com/uwt.js',
      a = t.getElementsByTagName(n)[0], a.parentNode.insertBefore(u, a))
    }(window, document, 'script'))
    twq('config', 'obu6l') // eslint-disable-line no-undef

    const isStudent = this.store.getters['me/isStudent']
    const isChina = (window.features || {}).china

    if (!this.disableAllTracking && !isStudent && !isChina) {
      this.enabled = true
    } else {
      this.enabled = false
    }

    this.onInitializeSuccess()
  }

  async trackPageView () {
    // Site visits and Landing page view events are automatically tracked:
    // https://business.twitter.com/en/help/campaign-measurement-and-analytics/conversion-tracking-for-websites.html
  }

  async trackEvent (action, properties = {}) {
    if (this.disableAllTracking || !window.twq) {
      return
    }

    await this.initializationComplete

    if (!this.enabled) {
      return
    }

    const twitterEvent = twitterEventActions[action]
    if (!twitterEvent) {
      return
    }

    window.twq('event', action, this.mapToTwitterProperties(twitterEvent, properties))
  }

  mapToTwitterProperties (twitterEvent, properties) {
    if (!properties || Object.keys(properties).length === 0) { return {} }
    const result = {}
    if (Object.values(SUBSCRIBE_EVENTS).includes(twitterEvent)) {
      const { purchaseAmount, currency } = properties
      result.value = purchaseAmount
      result.currency = currency
    } else if (twitterEvent === PURCHASE_EVENT) {
      const { purchaseAmount, currency } = properties
      result.value = purchaseAmount
      result.currency = currency
    }
    return result
  }
}
