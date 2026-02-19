const DEFAULT_TRACKING_DOMAINS = [
  'codecombat.com',
  'ozaria.com',
  'localhost',
]

const COCO_ENABLE_TRACKING_OVERRIDE_QUERY_PARAM = 'coco_tracking'

let hasTrackingOverrideQueryParameter = false
try {
  hasTrackingOverrideQueryParameter = (new URLSearchParams(window.location.search))
    .has(COCO_ENABLE_TRACKING_OVERRIDE_QUERY_PARAM)
} catch (e) {}

export default {
  namespaced: true,

  state: {
    doNotTrack: window.navigator && window.navigator.doNotTrack === '1',
    spying: window.serverSession && typeof window.serverSession.amActually !== 'undefined',
    switching: window.serverSession?.switchingUserActualId,
    trackingEnabledForEnvironment: DEFAULT_TRACKING_DOMAINS.includes(window.location.hostname.replace('www.', '')),
    enableTrackingOverride: hasTrackingOverrideQueryParameter,

    cookieConsent: {
      answered: false,
      consented: false,
      declined: false
    }
  },

  mutations: {
    updateCookieConsentStatus: (state, status) => {
      // Update properties individually to maintain Vue reactivity
      state.cookieConsent.answered = status.answered
      state.cookieConsent.consented = status.consented
      state.cookieConsent.declined = status.declined
    }
  },

  getters: {
    disableAllTracking (state, getters, rootState, rootGetters) {
      if (state.enableTrackingOverride) {
        console.log('disableAllTracking: false (tracking override enabled)')
        return false
      }

      // With opt-in consent: disable tracking unless user explicitly consented
      const hasNotConsented = !state.cookieConsent.consented
      const doNotTrack = state.doNotTrack
      const isSmokeTestUser = rootGetters['me/isSmokeTestUser']
      const spying = state.spying
      const trackingNotEnabledForEnv = !state.trackingEnabledForEnvironment

      const result = hasNotConsented || doNotTrack || isSmokeTestUser || spying || trackingNotEnabledForEnv
      return result
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
