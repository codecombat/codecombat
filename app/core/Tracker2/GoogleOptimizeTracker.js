import BaseTracker from './BaseTracker'

export default class GoogleOptimizeTracker extends BaseTracker {
  async _initializeTracker () {
    const isChina = (window.features || {}).china
    if (isChina) {
      return
    }

    const script = document.createElement('script')
    script.src = 'https://www.googleoptimize.com/optimize.js?id=OPT-K2B6W8Q'
    script.async = true
    document.head.appendChild(script);

    this.onInitializeSuccess()
  }
}
