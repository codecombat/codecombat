import BaseTracker from './BaseTracker'

export default class GoogleOptimizeTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  async _initializeTracker () {
    this.watchForDisableAllTrackingChanges(this.store)

    if (!this.disableAllTracking) {
      const script = document.createElement('script')
      script.src = 'https://www.googleoptimize.com/optimize.js?id=OPT-PT28TD8'
      script.async = true
      document.head.appendChild(script);
      this.enabled = true
    }

    this.onInitializeSuccess()
  }
}
