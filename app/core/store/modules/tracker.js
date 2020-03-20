export default {
  namespaced: true,

  state: {
    doNotTrack: window.navigator && window.navigator.doNotTrack === "1",

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
    disableAllTracking (state) {
      return state.cookieConsent.declined || state.doNotTrack
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
