import BaseTracker, { extractDefaultUserTraits } from './BaseTracker'

const FULLSTORY_SESSION_TRACKING_ENALBED_KEY = 'coco.tracker.fullstory.enabled'
const FULLSTORY_LAST_USER_ID_KEY = 'coco.tracker.fullstory.lastUserId'
const FULLSTORY_ENABLE_QUERY_PARAM = 'fullstory_enable'

export function loadFullStory() {
  /* eslint-disable */

  window['_fs_debug'] = false;
  window['_fs_host'] = 'fullstory.com';
  window['_fs_script'] = 'edge.fullstory.com/s/fs.js';
  window['_fs_org'] = 'RQW5S';
  window['_fs_namespace'] = 'FS';
  (function(m,n,e,t,l,o,g,y){
    if (e in m) {if(m.console && m.console.log) { m.console.log('FullStory namespace conflict. Please set window["_fs_namespace"].');} return;}
    g=m[e]=function(a,b,s){g.q?g.q.push([a,b,s]):g._api(a,b,s);};g.q=[];
    o=n.createElement(t);o.async=1;o.crossOrigin='anonymous';o.src='https://'+_fs_script;
    y=n.getElementsByTagName(t)[0];y.parentNode.insertBefore(o,y);
    g.identify=function(i,v,s){g(l,{uid:i},s);if(v)g(l,v,s)};g.setUserVars=function(v,s){g(l,v,s)};g.event=function(i,v,s){g('event',{n:i,p:v},s)};
    g.anonymize=function(){g.identify(!!0)};
    g.shutdown=function(){g("rec",!1)};g.restart=function(){g("rec",!0)};
    g.log = function(a,b){g("log",[a,b])};
    g.consent=function(a){g("consent",!arguments.length||a)};
    g.identifyAccount=function(i,v){o='account';v=v||{};v.acctId=i;g(o,v)};
    g.clearUserCookie=function(){};
    g._w={};y='XMLHttpRequest';g._w[y]=m[y];y='fetch';g._w[y]=m[y];
    if(m[y])m[y]=function(){return g._w[y].apply(this,arguments)};
    g._v="1.2.0";
  })(window,document,window['_fs_namespace'],'script','user');
}

export default class FullstoryTracker extends BaseTracker {
  constructor (store, globalTracker) {
    super()

    this.store = store
    this.globalTracker = globalTracker

    const sessionEnabled = window.sessionStorage.getItem(FULLSTORY_SESSION_TRACKING_ENALBED_KEY)
    this.enableDecisionMade = (sessionEnabled !== null)
    this.enabled = (sessionEnabled === 'true')

    this.log('initialized enabled', this.enabled)
    this.log('initialized enable decision made', this.enableDecisionMade)
  }

  async _initializeTracker () {
    this.watchForDisableAllTrackingChanges(this.store)

    // TODO handle disable all tracking
    window['_fs_ready'] = () => {
      let hasFullstoryEnableQueryParam = false
      try {
        hasFullstoryEnableQueryParam = (new URLSearchParams(window.location.search)).has(FULLSTORY_ENABLE_QUERY_PARAM)
      } catch (e) {}

      try {
        this.log('ready')
        if (hasFullstoryEnableQueryParam) {
          this.enabled = true
          this.log('query param force enable')
        } else if (!this.enableDecisionMade) {
          this.log('deciding on enabled')
          this.enabled = this.decideEnabled()
          if (this.enabled) {
            this.globalTracker.trackEvent('FullStory Tracking Enabled')
          }
        }

        if (this.enabled) {
          this.log('enabling from init')
          this.enable()
        } else {
          this.log('disabling from init')
          this.disable()
        }

        this.onInitializeSuccess()
      } catch (e) {
        this.onInitializeFail(e)
        throw e
      }
    }

    loadFullStory()
  }

  enable () {
    this.enabled = true
    window.sessionStorage.setItem(FULLSTORY_SESSION_TRACKING_ENALBED_KEY, 'true')
    FS.restart()
    this.log('enabled')
  }

  disable () {
    this.enabled = false
    window.sessionStorage.setItem(FULLSTORY_SESSION_TRACKING_ENALBED_KEY, 'false')
    FS.shutdown()
    this.log('disabled')
  }

  decideEnabled () {
    const { me } = this.store.state

    if (this.disableAllTracking) {
      this.log('decide enabled', 'disable all tracking')
      return false
    } else if (me.anonymous && Math.random() < 0.0025) {
      this.log('decide enabled', 'anon user')
      return true
    } else if (this.store.getters['me/isTeacher'] && !this.store.getters['me/isParent'] && Math.random() < 0.02) {
      this.log('decide enabled', 'non parent teacher')
      return true
    }

    this.log('decide enabled', 'not enabled')
    return false
  }

  async identify (traits = {}) {
    await this.initializationComplete

    // When identify() is called it's possible that the user has changed, so check if the user
    // has changed and if so run the decision logic again
    const { me } = this.store.state
    const lastUserId = window.sessionStorage.getItem(FULLSTORY_LAST_USER_ID_KEY)
    if (lastUserId !== me._id) {
      this.log('identify', 'new user')
      this.enabled = this.decideEnabled()
      if (this.enabled) {
        this.log('identify', 'enabling')
        this.enable()
      } else {
        this.log('identify', 'disabling')
        this.disable()
      }
    }

    window.sessionStorage.setItem(FULLSTORY_LAST_USER_ID_KEY, me._id)
    if (!this.enabled) {
      return
    }

    FS.identify(me._id)
    FS.setUserVars(extractDefaultUserTraits(me))
  }

  async trackPageView (includeIntegrations = []) {
    await this.initializationComplete

    if (!this.enabled) {
      return
    }

    const url = `/${Backbone.history.getFragment()}`
    FS.event('page', { url })
  }

  async trackEvent (action, properties = {}) {
    await this.initializationComplete

    if (!this.enabled) {
      return
    }

    FS.event(action, properties)
  }

  async resetIdentity () {
    await this.initializationComplete

    window.sessionStorage.removeItem(FULLSTORY_LAST_USER_ID_KEY)
    if (!this.enabled) {
      return
    }

    FS.anonymize()
  }
}
