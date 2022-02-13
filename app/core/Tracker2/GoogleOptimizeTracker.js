import BaseTracker from './BaseTracker'

import { isOzaria } from 'app/core/utils'

export default class GoogleOptimizeTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  async _initializeTracker () {
    this.watchForDisableAllTrackingChanges(this.store)

    if (!this.disableAllTracking) {
      const script = document.createElement('script')
      const optimizeId = isOzaria ? 'OPT-PT28TD8' : 'OPT-K2B6W8Q'
      script.src = `https://www.googleoptimize.com/optimize.js?id=${optimizeId}`
      script.async = true
      document.head.appendChild(script);
      this.enabled = true
    }

    this.onInitializeSuccess()
  }
}
