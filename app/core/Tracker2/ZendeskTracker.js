import BaseTracker from './BaseTracker'

export default class ZendeskTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  get isChatEnabled () {
    return !this.onNoZendeskPage && !this.store.getters['me/isStudent'] && !this.store.getters['me/isHomePlayer'] && this.store.getters['me/isTeacher']
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

  async _initializeTracker () {
    if (this.isChatEnabled) {
      await this.loadZendesk()
    }
    this.onInitializeSuccess()

    this.watchForDisableAllTrackingChanges(this.store)
  }
}
