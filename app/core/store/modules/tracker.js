const DEFAULT_TRACKING_DOMAINS = [
  'codecombat.com'
];

const COCO_ENABLE_TRACKING_OVERRIDE_QUERY_PARAM = 'coco_tracking'

let hasTrackingOverrideQueryParameter = false
try {
  hasTrackingOverrideQueryParameter = (new URLSearchParams(window.location.search))
    .has(COCO_ENABLE_TRACKING_OVERRIDE_QUERY_PARAM)
} catch (e) {}

export default {
  namespaced: true,

  state: {
    doNotTrack: window.navigator && window.navigator.doNotTrack === "1",
    spying: window.serverSession && typeof window.serverSession.amActually !== 'undefined',
    trackingEnabledForEnvironment: DEFAULT_TRACKING_DOMAINS.includes(window.location.hostname),

    enableTrackingOverride: hasTrackingOverrideQueryParameter,

    cookieConsent: {
      answered: false,
      consented: false,
      declined: false
    },
  },

  mutations: {
    updateCookieConsentStatus: (state, status) => {
      state.cookieConsent = status
    }
  },

  getters: {
    disableAllTracking (state, getters, rootState, rootGetters) {
      if (state.enableTrackingOverride) {
        return false;
      }

      return state.cookieConsent.declined || state.doNotTrack || rootGetters['me/isSmokeTestUser'] || state.spying ||
        !state.trackingEnabledForEnvironment
    }
  },

  actions: {
    cookieConsentStatusChange: ({ commit }, status) => {
      commit('updateCookieConsentStatus', {
        answered: typeof status === 'string',
        consented: status === 'allow' || status === 'dismiss',
        declined: status === 'deny'
      })
    }
  }
}
