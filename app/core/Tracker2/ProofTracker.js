import CocoLegacyTracker from '../Tracker'
import BaseTracker from './BaseTracker'

export default class ProofTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
    this.enabled = (new URL(window.location.href)).startsWith('next.');
  }

  async _initializeTracker () {
    if (!this.enabled) {
      return this.onInitializeSuccess();
    }

    // TODO Proof recommends this is loaded directly into the page head.  It's loaded here
    //      so that we can test on next.  Load properly for production release.
    const proofScript = document.createElement('script')
    proofScript.src = 'https://cdn.proof-x.com/proofx.js?px_wid=-M-RGUfR3QToJiCIwXw7';
    proofScript.onload = this.onInitializeSuccess
    proofScript.onerror = this.onInitializeFail

    document.head.appendChild(proofScript);
  }

  async identify (traits = {}) {
    if (!this.enabled) {
      return
    }

    const { me } = this.store.state

    // TODO determine what traits we want to send for all user types
    proofx.identify(me._id)
  }

  async trackPageView (includeIntegrations = []) {
    proofx.page()
  }

  async trackEvent (action, properties = {}) {
    proofx.track(action, properties)
  }
}
