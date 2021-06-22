import apiclientsApi from 'core/api/api-clients'

export default {
  namespaced: true,

  state: {
    loading: {
      byLicense: false,
      byPlayTime: false,
    },
    clientId: '',
    licenseStats: {},
    playTimeStats: {}
  },

  mutations: {
    toggleLoading: (state, type) => {
      let loading = true
      if (state.loading[type]) {
        loading = false
      }
      Vue.set(state.loading, type, loading)
    },

    setClientId: (state, { id }) => {
      state.clientId = id
    },
    addLicenseStats: (state, { stats }) => {
      state.licenseStats = stats
    },
    addPlayTimeStats: (state, { stats }) => {
      state.playTimeStats = stats
    }
  },

  actions: {
    fetchClientId: ({ commit }) => {
      apiclientsApi.getApiClientId().then(res => {
        commit('setClientId', {id: res})
      })
    },
    fetchLicenseStats: ({ commit }, clientId) => {
      commit('toggleLoading', 'byLicense')

      return apiclientsApi
        .getLicenseStats(clientId)
        .then(res =>  {
          if (res) {
            commit('addLicenseStats', {
              stats: res
            })
          } else {
            throw new Error('Unexpected response from license stats by owner API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch license stats failure: ' + e, type: 'error' }))
        .finally(() => commit('toggleLoading', 'byLicense'))
    },
    fetchPlayTimeStats: ({ commit }) => {
      commit('toggleLoading', 'byPlayTime')
      return apiclientsApi
        .getPlayTimeStats()
        .then(res => {
          if (res) {
            commit('addPlayTimeStats', {
              stats: res
            })
          } else {
            throw new Error('Unexpected response from play-time stats by owner API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch play time stats failure: ' + e, type: 'error' }))
        .finally(() => commit('toggleLoading', 'byPlayTime'))
    }
  }
}
