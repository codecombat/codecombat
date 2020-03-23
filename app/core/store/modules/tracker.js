export default {
  namespaced: true,

  state: {
    doNotTrack: window.navigator && window.navigator.doNotTrack === "1",
    spying: window.serverSession && typeof window.serverSession.amActually !== 'undefined',

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
      return state.cookieConsent.declined || state.doNotTrack || rootGetters['me/isSmokeTestUser'] || state.spying
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
