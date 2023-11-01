import usersApi from 'core/api/users'
import classroomsApi from 'core/api/classrooms'
import adminApi from 'core/api/admin'

export default {
  namespaced: true,

  state: {
    loading: {
      byId: {}
    },

    users: {
      byId: {},
      searchedResult: []
    },

    userNames: {
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
    },

    setUsers: (state, users) => {
      users.forEach((user) => {
        Vue.set(state.users.byId, user._id, user)
      })
    },

    setSearchedResult: (state, users) => {
      state.users.searchedResult = users
    },
    resetSearchedResult: (state) => {
      state.users.searchedResult = []
    },

    setUserNames: (state, nameMap) => {
      Object.keys(nameMap).forEach((userId) => {
        Vue.set(state.userNames.byId, userId, nameMap[userId])
      })
    }
  },
  getters: {
    // Get user data for classroom members
    getClassroomMembers: (state) => (classroom) => {
      const members = []
      if (classroom.members) {
        classroom.members.forEach((m) => {
          if (state.users.byId[m]) {
            members.push(state.users.byId[m])
          }
        })
      }
      return members
    },
    getUserById: (state) => (id) => {
      return state.users.byId[id]
    },
    getUserSearchResult: (state) => {
      return state.users.searchedResult
    },
    getUserNameById: (state) => (id) => {
      const user = state.userNames.byId[id]
      if(!user) return ''
      let name = ''
      if (user.firstName) {
        name = user.name
      }
      if (user.lastName) {
        name += ' ' + user.lastName
      }
      if (!name) {
        name = user.name
      }
      return name
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
        .catch((e) => noty({ text: 'Fetch user failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForId', userId))
    },

    fetchClassroomMembers: ({ commit }, { classroom, options = {} }) => {
      return classroomsApi
        .getMembers({ classroom }, {
          removeDeleted: true,
          data: { project: options.project || 'firstName,lastName,name,email,coursePrepaid,products,deleted' }
        })
        .then(res => {
          if (res && res.length > 0) {
            commit('setUsers', res)
          }
        })
        .catch((e) => noty({ text: 'Fetch user failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
    },

    fetchCreatorOfPrepaid: ({ commit }, prepaidId) => {
      return usersApi
        .fetchCreatorOfPrepaid({ prepaidId: prepaidId })
        .then(res => {
          if (res) {
            commit('setUsers', [res])
          }
        })
        .catch((e) => {
          console.error(`Fetch user failure ${e.message}`)
          // HACK: Disabling this user notification whilst keeping it in the console.
          // noty({ text: 'Fetch user failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 })
        })
    },

    fetchUsersByNameOrSlug: ({ commit }, q) => {
      adminApi.searchUser(q)
        .then(res => {
          commit('setSearchedResult', res)
        })
        .catch((e) => {
          console.error(`Fetch user failure ${e.message}`)
        })
    },

    fetchUserNamesById: ({ commit }, ids) => {
      return usersApi
        .fetchNamesForUser(ids)
        .then(res => {
          if (res) {
            commit('setUserNames', res)
          }
        })
        .catch(e => {
          console.error(`Fetch user names failure ${e.message}`)
        })
    }
  }
}
