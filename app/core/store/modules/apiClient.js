import apiclientsApi from 'core/api/api-clients'

export default {
  namespaced: true,

  state: {
    loading: {
      byLicense: {}
    },
    licenseStats: {}
  },

  mutations: {
    toggleLoading: (state, type) => {
      let loading = true
      if (state.loading[type]) {
        loading = false
      }

      Vue.set(state.loading, type, loading)
    },

    addLicenseStats: (state, { stats }) =>
      Vue.set(state.licenseStats, stats)
  },

  actions: {
    fetchLicenseStats : ({ commit }, clientId) => {
      commit('toggleLoading', 'byLicense')

      return apiclientsApi
        .getLicenseStats(clientId)
        .then(res =>  {
          if (res) {
            commit('addLicenseStats', {
              res
            })
          } else {
            throw new Error('Unexpected response from license stats by owner API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch license stats failure: ' + e, type: 'error' }))
        .finally(() => commit('toggleLoading', 'byLicense'))
    },
  }
}
