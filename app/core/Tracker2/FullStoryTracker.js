import BaseTracker from './BaseTracker'

const FULLSTORY_SESSION_TRACKING_ENALBED_KEY = 'coco.tracker.fullstory.enabled'

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

export default class ProofTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store

    const sessionEnabled = window.sessionStorage.getItem(FULLSTORY_SESSION_TRACKING_ENALBED_KEY)
    this.enableDecisionMade = (sessionEnabled !== null)
    this.enabled = (sessionEnabled === true)
  }

  async _initializeTracker () {
    window['_fs_ready'] = () => {
      if ((new URLSearchParams(window.location.search)).has('fullstory_enable')) {
        this.enabled = true
      } else if (!this.enableDecisionMade) {
        this.enabled = this.decideEnabled()
      }

      if (this.enabled) {
        this.enable()
      } else {
        this.disable()
      }

      this.onInitializeSuccess()
    }

    loadFullStory()
  }

  enable () {
    this.enabled = true
    window.sessionStorage.setItem(FULLSTORY_SESSION_TRACKING_ENALBED_KEY, 'true')
    FS.restart()
  }

  disable () {
    this.enabled = false
    window.sessionStorage.setItem(FULLSTORY_SESSION_TRACKING_ENALBED_KEY, 'false')
    FS.shutdown()
  }

  decideEnabled () {
    if (this.enabled) {
      return true
    }

    const { me } = this.store.state

    if (me.anonymous && Math.random() < 0.5) {
      return true
    } else if (this.store.getters['me/isTeacher'] && !this.store.getters['me/isParent'] && Math.random() < 0.5) {
      return true
    }

    return false
  }

  async identify (traits = {}) {
    await this.initializationComplete

    if (!this.enabled) {
      return
    }

    const { me } = this.store.state

    // TODO when a user transitions from anon to logged in we'll end up recording two different sessions
    //      is this ok? using window.session to enable full story doesn't make sense in this case?
    //      maybe when a user logs in we reset the recording decision logic?
    FS.identify(me._id)

    // TODO determine what traits we want to send for all user types
    FS.setUserVars({})
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

    if (!this.enabled) {
      return
    }

    FS.anonymize()
  }
}
