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
}

function loadFacebookPixel () {
  !function(f,b,e,v,n,t,s)
  {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
    n.callMethod.apply(n,arguments):n.queue.push(arguments)};
    if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
    n.queue=[];t=b.createElement(e);t.async=!0;
    t.src=v;s=b.getElementsByTagName(e)[0];
    s.parentNode.insertBefore(t,s)}(window, document,'script',
    'https://connect.facebook.net/en_US/fbevents.js');

  fbq('init', '514962702046652')
  fbq('track', 'PageView')
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
    const isTeacher = this.store.getters['me/isTeacher']

    const isStudent = this.store.getters['me/isStudent']
    const isChina = (window.features || {}).china

    if (!this.disableAllTracking && !isTeacher && !isStudent && !isChina) {
      loadFacebookPixel()
      this.enabled = true
    } else {
      this.enabled = false
    }

    this.onInitializeSuccess()
  }

  // Facebook JS automatically tracks pageviews using history API.  Their docs recommend letting
  // them manage the pageview tracking.
  async trackPageView () {}

  async trackEvent (action, properties = {}) {
    if (this.disableAllTracking) {
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
      fbq('trackCustom', action, properties)
    } else if (typeof fbEvent === 'string') {
      // Track as standard event name
      fbq('track', fbEvent, this.mapToFbProperties(fbEvent, properties))
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
      result = properties
    }
    return result
  }
}
