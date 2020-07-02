import usersApi from 'core/api/users'
import classroomsApi from 'core/api/classrooms'

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
    },

    setUsers: (state, users) => {
      users.forEach((user) => {
        Vue.set(state.users.byId, user._id, user)
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
          data: { project: options.project || 'firstName,lastName,name,email,coursePrepaid,deleted' }
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
        .catch((e) => noty({ text: 'Fetch user failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
    }
  }
}
