import BaseTracker from './BaseTracker'

const SUBSCRIBE_EVENT = 'Subscribe'
const PURCHASE_EVENT = 'Purchase'
// Only send events to Facebook if they're in this list.
// If they are mapped as a string, then send that as the standard Facebook event name.
const facebookEventActions = {
  'Parents page CTA clicked': true,
  'Live classes CTA clicked': true,
  'Email for booking class': true,
  'Live classes welcome call scheduled': 'Schedule',
  'CodeCombat live class booked': 'Schedule',
  'Finished Signup': 'CompleteRegistration',
  'Sales chat opened': 'Contact',
  'Support chat opened': 'Contact',
  'Support email opened': 'Contact',
  'CreateAccountModal Teacher BasicInfoView Submit Success': 'Lead',
  'Teachers Request Demo Form Submitted': 'Lead',
  'Checkout initiated': 'InitiateCheckout',
  'Student licenses purchase success': PURCHASE_EVENT, // should include properties: { value: '0.00', currency: 'USD', predicted_ltv: '0.00' }
  'Online classes purchase success': SUBSCRIBE_EVENT, // should include properties: { value: '0.00', currency: 'USD', predicted_ltv: '0.00' }
  'Home subscription purchase success': SUBSCRIBE_EVENT, // should include properties: { value: '0.00', currency: 'USD', predicted_ltv: '0.00' }
  UniqueTeacherSignup: true,
  OzariaUniqueTeacherSignup: true
}

export default class FacebookPixelTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  async _initializeTracker () {
    this.watchForDisableAllTrackingChanges(this.store)

    // Facebook pixels are currently tracked via Segment, which is enabled for all teachers so do not
    // double enable it for teachers
    const isStudent = this.store.getters['me/isStudent']
    const isChina = (window.features || {}).china
    const isRegisteredHomeUser = this.store.getters['me/isHomePlayer'] // Includes anonymous: false check

    if (!this.disableAllTracking && !isStudent && !isChina && !isRegisteredHomeUser && window.fbq && !window.fbq.doNotTrack) {
      this.enabled = true
      // Moved this from layout.static, since we need to first know if we are using FB for these
      window.fbq('init', '514962702046652')
      window.fbq('track', 'PageView')
    } else {
      this.enabled = false
      const fbqTrackingScript = document.getElementById('analytics-fbq')
      if (fbqTrackingScript) {
        fbqTrackingScript.remove()
        if (window.fbq) {
          window.fbq.doNotTrack = true
        }
      }
    }

    this.onInitializeSuccess()
  }

  // Facebook JS automatically tracks pageviews using history API.  Their docs recommend letting
  // them manage the pageview tracking.
  async trackPageView () {}

  async trackEvent (action, properties = {}) {
    if (this.disableAllTracking || !window.fbq || window.fbq?.doNotTrack) {
      return
    }

    await this.initializationComplete

    if (!this.enabled) {
      return
    }

    const fbEvent = facebookEventActions[action]
    if (!fbEvent) {
      return
    }

    this.log('tracking event', fbEvent, this.mapToFbProperties(fbEvent, properties))
    if (fbEvent === true) {
      window.fbq('trackCustom', action, this.mapToFbProperties(fbEvent, properties))
    } else if (typeof fbEvent === 'string') {
      // Track as standard event name
      window.fbq('track', fbEvent, this.mapToFbProperties(fbEvent, properties))
    }
  }

  mapToFbProperties (fbEvent, properties) {
    if (!properties || Object.keys(properties).length === 0)
      return {}
    let result = {}
    if (fbEvent === SUBSCRIBE_EVENT) {
      const { purchaseAmount, predictedLtv, currency } = properties
      result['predicted_ltv'] = predictedLtv
      result.value = purchaseAmount
      result.currency = currency
    } else if (fbEvent === PURCHASE_EVENT) {
      const { purchaseAmount, currency } = properties
      result.value = purchaseAmount
      result.currency = currency
    } else {
      result = { ...properties }
      if (properties.category) result.content_category = properties.category
      if (properties.label) result.content_name = properties.label
      if (fbEvent === 'CompleteRegistration') result.status = true
    }
    return result
  }
}
