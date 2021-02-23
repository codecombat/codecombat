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
  'gender', 'lastLevel', 'siteref', 'ageRange', 'schoolName', 'coursePrepaidID', 'role', 'firstName', 'lastName'
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
    if (this.isChatEnabled) {
      await this.initializeDrift()
    } else {
      this.onInitializeSuccess()
    }

    this.store.watch(
      (state) => state.route,
      () => this.routeUpdated()
    )

    this.store.watch(
      (state) => state.me.role,
      () => this.userRoleUpdated()
    )

    this.watchForDisableAllTrackingChanges(this.store)
  }

  async initializeDrift () {
    loadDrift()

    window.drift.on('ready', async (api) => {
      this.driftApi = api
      this.initDriftOnLoad()
      this.updateDriftConfiguration()

      this.onInitializeSuccess()

      const retries = await getPageUnloadRetriesForNamespace('drift')
      for (const retry of retries) {
        this[retry.identifier](...retry.args)
      }
    })
  }

  initDriftOnLoad () {
    if (!this.isChatEnabled) {
      this.driftApi.widget.hide()
    }

    // Show when a message is received
    window.drift.on('message', (e) => {
      if (!e?.data?.sidebarOpen) {
        if (this.isChatEnabled) {
          this.driftApi.widget.show()
        }
      }
    })
  }

  routeUpdated () {
    this.updateDriftConfiguration()
  }

  userRoleUpdated () {
    this.updateDriftConfiguration()
  }

  get onPlayPage () {
    const { route } = this.store.state
    return (route.path || '').indexOf('/play') === 0
  }

  get isChatEnabled () {
    return !this.onPlayPage && !this.store.getters['me/isStudent'] && !this.store.getters['me/isHomePlayer']  // && !this.disableAllTracking
  }

  async updateDriftConfiguration () {
    await this.initializationComplete

    const chatEnabled = this.isChatEnabled
    if (!this.isInitialized) {
      // Drift failed to load, let's not try again.
      return
    } else if (chatEnabled && !this.driftApi) {
      return this.initializeDrift()
    } else if (!chatEnabled && !this.driftApi) {
      return
    }

    window.drift.config({
      enableWelcomeMessage: chatEnabled,
      enableCampaigns: chatEnabled,
      enableChatTargeting: chatEnabled,
    });

    if (chatEnabled) {
      this.driftApi.widget.show();
    } else {
      this.driftApi.widget.hide();
    }
  }

  async identify (traits = {}) {
    if (this.disableAllTracking) {
      return
    }

    await this.initializationComplete
    if (!window.drift) {
      return;
    }

    const { me } = this.store.state

    const {
      _id,
      ...meAttrs
    } = me

    const filteredMeAttributes = DEFAULT_DRIFT_IDENTIFY_USER_PROPERTIES.reduce((obj, key) => {
      const meAttr = meAttrs[key]
      if (typeof meAttr !== 'undefined' && meAttr !== null) {
        obj[key] = meAttr
      }

      return obj;
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

  async trackPageView (includeIntegrations = []) {
    if (this.disableAllTracking) {
      return
    }

    await this.initializationComplete

    const url = `/${Backbone.history.getFragment()}`
    await window.drift.page(url)
  }

  async trackEvent (action, properties = {}) {
    if (this.disableAllTracking) {
      return
    }

    await this.initializationComplete

    await window.drift.track(action, properties)
  }

  async resetIdentity () {
    window.drift.reset()
  }
}

