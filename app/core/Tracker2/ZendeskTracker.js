import BaseTracker from './BaseTracker'
const zendeskHelper = require('../../core/services/zendesk')

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
    zendeskHelper.loadZendesk()
  }

  async _initializeTracker () {
    if (this.isChatEnabled) {
      await this.loadZendesk()
    } else {
      this.onInitializeSuccess()
    }

    this.watchForDisableAllTrackingChanges(this.store)
  }
}
