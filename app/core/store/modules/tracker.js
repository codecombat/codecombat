export default {
  namespaced: true,

  state: {
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
    cookieConsentDeclined (state) {
      return state.cookieConsent.declined === true
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
