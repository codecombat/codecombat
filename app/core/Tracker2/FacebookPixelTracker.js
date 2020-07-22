import BaseTracker from './BaseTracker'

function loadFacebookPixel () {
  !function(f,b,e,v,n,t,s)
  {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
    n.callMethod.apply(n,arguments):n.queue.push(arguments)};
    if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
    n.queue=[];t=b.createElement(e);t.async=!0;
    t.src=v;s=b.getElementsByTagName(e)[0];
    s.parentNode.insertBefore(t,s)}(window, document,'script',
    'https://connect.facebook.net/en_US/fbevents.js');

  fbq('init', '514962702046652');
  fbq('track', 'PageView')
}

export default class FacebookPixelTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  async _initializeTracker () {
    this.watchForDisableAllTrackingChanges(this.store)

    if (!this.disableAllTracking) {
      loadFacebookPixel()
    }

    this.onInitializeSuccess()
  }

  // Facebook JS automatically tracks pageviews using history API.  Their docs recommend letting
  // them manage the pageview tracking.
  async trackPageView (includeIntegrations = []) {}

  async trackEvent (action, properties = {}, includeIntegrations = []) {
    if (this.disableAllTracking) {
      return
    }

    await this.initializationComplete

    if (!includeIntegrations.includes('facebook')) {
      return
    }

    fbq('trackCustom', action, properties)
  }
}
