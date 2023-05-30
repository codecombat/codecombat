import BaseTracker, { extractDefaultUserTraits } from './BaseTracker'
import { getQueryVariable } from '../utils'
import api from 'core/api';

/**
 * Tracks events to our internal analytics database.
 */
export default class InternalTracker extends BaseTracker {
  constructor (store) {
    super()
    this.store = store
  }

  async _initializeTracker () {
    this.log('internal tracker initialize start')
    this.onInitializeSuccess()
    this.trackReferrers()
    this.trackUtm()
    this.log('internal tracker initialize end')
  }

  async identify (traits = {}) {
    await this.initializationComplete
    const { me } = this.store.state
    traits = _.merge(extractDefaultUserTraits(me), traits)
    traits.host = document.location.host
    if (me.isTeacher(true)) {
      traits.teacher = true
    } else {
      traits = _.omit(traits, 'firstName', 'lastName')
    }
    this.trackEventInternal('Identify', {id: me.id, traits})
  }

  async trackPageView () {
    await this.initializationComplete
    const name = Backbone.history.getFragment()
    this.trackEventInternal('Pageview', { url: name, href: window.location.href })
  }

  async trackEvent (action, properties = {}) {
    await this.initializationComplete
    this.trackEventInternal(action, properties)
  }

  trackEventInternal (event, properties) {
    if (this.disableAllTracking) return this.log('not tracking', event, 'because of disableAllTtracking')
    if (this.store.state.me.isAdmin) return this.log('not tracking', event, 'because of admin')
    // Skipping heavily logged actions we don't use internally
    if (['Simulator Result', 'Started Level Load', 'Finished Level Load', 'View Load'].indexOf(event) !== -1) return this.log('not tracking common event', event)
    // Trimming properties we don't use internally
    properties = _.clone(properties)
    if (['Clicked Start Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Homepage Loaded', 'Change Hero'].indexOf(event) !== -1) {
      delete properties.category
      delete properties.label
    }
    else if (['Clicked Start Level', 'Inventory Play', 'Heard Sprite', 'Started Level', 'Saw Victory', 'Click Play', 'Choose Inventory', 'Homepage Loaded', 'Change Hero'].indexOf(event) !== -1) {
      delete properties.category
    }
    this.log('tracking internal analytics event:', event, properties)
    api.analyticsLogEvents.post({event, properties})
  }

  trackReferrers () {
    const elapsed = new Date() - new Date(me.get('dateCreated'))
    if (elapsed >= 5 * 60 * 1000) return
    if (me.get('siteref') || me.get('referrer')) return
    let changed = false
    const siteref = getQueryVariable('_r')
    const referrer = document.referrer
    if (siteref) {
      me.set('siteref', siteref)
      changed = true
    }
    if (referrer) {
      me.set('referrer', referrer)
      changed = true
    }
    if (changed) {
      me.patch()
    }
  }

  trackUtm () {
    const properties = { url: window.location.href }
    for (let [param, value] of new URLSearchParams(window.location.search)) {
      if (param.startsWith('utm_')) {
        properties[param] = value
      }
    }
    if (!properties.utm_source || !properties.utm_medium) return
    if (document.referrer) {
      properties.referrer = document.referrer
    }
    this.trackEventInternal('Arrived With UTM', properties)
  }
}
