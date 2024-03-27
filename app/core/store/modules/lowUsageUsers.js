const lowUsageUsersApi = require('../../api/low-usage-users')
export default {
  namespaced: true,
  state: {
    lowUsageUsers: []
  },
  mutations: {
    setLowUsageUsers: (state, lowUsageUsers) => {
      state.lowUsageUsers = lowUsageUsers
    },
    addAction: (state, { lowUsageUserId, action }) => {
      const user = state.lowUsageUsers.find(user => user._id === lowUsageUserId)
      const index = state.lowUsageUsers.indexOf(user)
      user.actions ||= []
      user.actions.push(action)
      state.lowUsageUsers.splice(index, 1, user)
    }
  },
  actions: {
    fetchLowUsageUsers: async ({ commit }) => {
      const lowUsageUsers = await lowUsageUsersApi.fetchAll()
      commit('setLowUsageUsers', lowUsageUsers.data)
    },
    addActionToUser: async ({ commit }, { lowUsageUserId, action }) => {
      const res = await lowUsageUsersApi.addAction({ lowUsageUserId, action })
      commit('addAction', { lowUsageUserId, action: res.data })
    }
  },
  getters: {
    getLowUsageUsers: state => state.lowUsageUsers
  }
}