import BaseTracker from './BaseTracker'

export default class ZendeskTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
    this.zendeskShown = false
  }

  get isChatEnabled () {
    return !this.onNoZendeskPage &&
        this.store.getters['me/isHomePlayer'] &&
        this.store.getters['me/isPremium']
  }

  get onNoZendeskPage () {
    const { route } = this.store.state
    return /(\/play|\/certificates)/.test(route.path || '')
  }

  loadZendesk () {
    const scr = document.createElement('script')
    scr.type = 'text/javascript'
    scr.async = true
    scr.id = 'ze-snippet'
    scr.src = 'https://static.zdassets.com/ekr/snippet.js?key=ed461a46-91a6-430a-a09c-73c364e02ffe'
    document.getElementsByTagName('head')[0].appendChild(scr)
  }

  hideZendesk () {
    window.zE('messenger', 'hide')
  }

  showZendesk () {
    window.zE('messenger', 'show')
  }

  watchForRouteChange (store) {
    store.watch(
      (state) => state.route.path,
      () => {
        if (this.isChatEnabled) {
          if (!this.zendeskShown) {
            this.showZendesk()
            this.zendeskShown = true
          }
        } else {
          if (this.zendeskShown) {
            this.hideZendesk()
            this.zendeskShown = false
          }
        }
      },
    )
  }

  async _initializeTracker () {
    if (this.isChatEnabled) {
      await this.loadZendesk()
      this.zendeskShown = true
    }
    this.onInitializeSuccess()

    this.watchForRouteChange(this.store)
    this.watchForDisableAllTrackingChanges(this.store)
  }
}
