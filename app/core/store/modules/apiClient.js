import apiclientsApi from 'core/api/api-clients'

export default {
  namespaced: true,

  state: {
    loading: {
      byLicense: false,
      byPlayTime: false,
      teachers: false
    },
    clientId: '',
    licenseStats: {},
    playTimeStats: {},
    createdTeachers: []
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
    },
    addTeachers: (state, teachers) => {
      state.createdTeachers = teachers
    }
  },
  getters: {
    getTeachers: (state) => {
      return state.createdTeachers
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
    },
    fetchTeachers: ({ commit, rootState }, clientId) => {
      commit('toggleLoading', 'teachers')

      apiclientsApi.getTeacherCount(clientId)
        .then(res => {
          const groupSize = 100
          const groups = Math.ceil(res.num / (groupSize * 1.0))
          let lastStartIndex = 0
          const userPromises = []

          for (let i = 0; i < groups; i++) {
            userPromises.push(
              apiclientsApi.getTeachers(clientId, {
                skip: lastStartIndex,
                limit: groupSize
              }).then(res => {
                if (res) {
                  return res
                } else {
                  throw new Error('Unexpected resjponse from teachers by APIClient.')
                }
              }))

            lastStartIndex = lastStartIndex + groupSize
          }

          return Promise.all(userPromises)
            .then(groupResults => groupResults.flat())
            .then(combinedResults => commit('addTeachers', combinedResults))
            .catch((e) => noty({ text: 'Fetch teachers failure' + e, type: 'error' }))
            .finally(() => commit('toggleLoading', 'teachers'))
        })
    }
  }
}
