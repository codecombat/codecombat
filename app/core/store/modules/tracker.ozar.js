// NOTE: If we change how http -> https and non-www to www is rewritten in CloudFlare,
// we also need to update this matching. This avoids matching other envs like staging.
const TRACKING_DOMAIN = 'www.ozaria.com'

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
    trackingEnabledForEnvironment: window.location.hostname === TRACKING_DOMAIN,

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
