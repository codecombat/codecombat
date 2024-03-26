const lowUsageUsersApi = require('../../api/low-usage-users')
export default {
  namespaced: true,
  state: {
    lowUsageUsers: []
  },
  mutations: {
    setLowUsageUsers: (state, lowUsageUsers) => {
      state.lowUsageUsers = lowUsageUsers
    }
  },
  actions: {
    fetchLowUsageUsers: async ({ commit }) => {
      const lowUsageUsers = await lowUsageUsersApi.fetchAll()
      console.log('fetch', lowUsageUsers)
      commit('setLowUsageUsers', lowUsageUsers.data)
    },
  },
  getters: {
    getLowUsageUsers: state => state.lowUsageUsers
  }
}