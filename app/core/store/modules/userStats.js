import { getStatsForUser } from 'ozaria/site/api/user-stats'

export default {
  namespaced: true,

  state: {
    statsByUserId: {}
  },

  mutations: {
    addStatsForUser: (state, { userId, stats }) => {
      Vue.set(state.statsByUserId, userId, stats)
    }
  },

  getters: {
    getStatsByUser: (state) => (id) => {
      return state.statsByUserId[id]
    }
  },

  actions: {
    fetchStatsForUser: ({ commit }, userId) => {
      return getStatsForUser(userId)
        .then(res => {
          if (res) {
            commit('addStatsForUser', {
              userId,
              stats: res
            })
          } else {
            throw new Error('Unexpected response from get user-stats API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch user-stats failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
    }
  }
}
