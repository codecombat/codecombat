import usersApi from 'core/api/users'

export default {
  namespaced: true,

  state: {
    loading: {
      byId: {}
    },

    users: {
      byId: {}
    }
  },

  mutations: {
    toggleLoadingForId: (state, userId) => {
      let loading = true
      if (state.loading.byId[userId]) {
        loading = false
      }

      Vue.set(state.loading.byId, userId, loading)
    },

    addUser: (state, user) => {
      Vue.set(state.users.byId, user._id, user)
    }
  },

  actions: {
    fetchUserById: ({ commit }, userId) => {
      commit('toggleLoadingForId', userId)

      return usersApi
        .fetchByIds({ fetchByIds: [ userId ] })
        .then(res =>  {
          if (res && res.length === 1) {
            commit('addUser', res[0])
          } else {
            throw new Error('Unexpected response returned from user API')
          }
        })
        .catch((e) => noty({ text: 'Fetch user failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoadingForId', userId))
    }
  }
}
