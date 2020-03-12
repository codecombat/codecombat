import BaseTracker from './BaseTracker'
import { getPageUnloadRetriesForNamespace, retryOnPageUnload } from './pageUnload'

function loadDrift () {
  /* eslint-disable */

  !function() {
    var t = window.driftt = window.drift = window.driftt || [];
    if (!t.init) {
      if (t.invoked) return void (window.console && console.error && console.error("Drift snippet included twice."));
      t.invoked = !0, t.methods = [ "identify", "config", "track", "reset", "debug", "show", "ping", "page", "hide", "off", "on" ],
        t.factory = function(e) {
          return function() {
            var n = Array.prototype.slice.call(arguments);
            return n.unshift(e), t.push(n), t;
          };
        }, t.methods.forEach(function(e) {
        t[e] = t.factory(e);
      }), t.load = function(t) {
        var e = 3e5, n = Math.ceil(new Date() / e) * e, o = document.createElement("script");
        o.type = "text/javascript", o.async = !0, o.crossorigin = "anonymous", o.src = "https://js.driftt.com/include/" + n + "/" + t + ".js";
        var i = document.getElementsByTagName("script")[0];
        i.parentNode.insertBefore(o, i);
      };
    }
  }();

  drift.SNIPPET_VERSION = '0.3.1';
  drift.load('9h3pui39u2s3');
}

const DEFAULT_DRIFT_IDENTIFY_USER_PROPERTIES = [
  'email', 'anonymous', 'dateCreated', 'hourOfCode', 'name', 'referrer', 'testGroupNumber', 'testGroupNumberUS',
  'gender', 'lastLevel', 'siteref', 'ageRange', 'schoolName', 'coursePrepaidID', 'role'
]

export default class DriftTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  get drift () {
    return this.driftApi
  }

  async _initializeTracker () {
    loadDrift()

    window.drift.on('ready', (api) => {
      this.driftApi = api

      this.initDriftOnLoad()
      this.onInitializeSuccess()
    })

    await this.initializationComplete

    const retries = await getPageUnloadRetriesForNamespace('drift')
    for (const retry of retries) {
      this[retry.identifier](...retry.args)
    }
  }

  initDriftOnLoad () {
    // Hide by default
    this.driftApi.widget.hide()

    // Show when a message is received
    window.drift.on('message', (e) => {
      if (!e.data.sidebarOpen) {
        this.driftApi.widget.show()
      }
    })
  }

  async identify (traits = {}) {
    await this.initializationComplete

    const { me } = this.store.state

    const {
      _id,
      ...meAttrs
    } = me

    const filteredMeAttributes = Object.keys(meAttrs)
      .reduce((obj, key) => {
        if (DEFAULT_DRIFT_IDENTIFY_USER_PROPERTIES.includes(key) && meAttrs[key] !== null) {
          obj[key] = meAttrs[key]
        }

        return obj
      }, {})

    retryOnPageUnload('drift', 'identify', [ traits ], () => {
      window.drift.identify(
        _id.toString(),
        {
          ...filteredMeAttributes,
          ...traits
        }
      )
    })
  }

  async trackPageView (includeIntegrations = {}) {
    await this.initializationComplete

    const url = `/${Backbone.history.getFragment()}`
    await window.drift.page(url)
  }

  async trackEvent (action, properties = {}) {
    await this.initializationComplete

    await window.drift.track(action, properties)
  }
}

