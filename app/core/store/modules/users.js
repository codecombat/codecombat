import usersApi from 'core/api/users'
import classroomsApi from 'core/api/classrooms'

export default {
  namespaced: true,

  state: {
    loading: {
      byId: {},
      byClassroom: {}
    },

    users: {
      byId: {},
      byClassroom: {}
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

    toggleLoadingForClassroom: (state, classroomId) => {
      let loading = true
      if (state.loading.byClassroom[classroomId]) {
        loading = false
      }

      Vue.set(state.loading.byClassroom, classroomId, loading)
    },

    addUser: (state, user) => {
      Vue.set(state.users.byId, user._id, user)
    },

    addMembersForClassroom: (state, { classroomId, members }) => {
      Vue.set(state.users.byClassroom, classroomId, members)
    }
  },

  getters: {
    getClassroomMembers: (state) => (classroom) => {
      return state.users.byClassroom[classroom]
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
      commit('toggleLoadingForClassroom', classroom._id)

      return classroomsApi
        .getMembers({ classroom }, { 
          removeDeleted: true,
          data: { project: options.project || 'firstName,lastName,name,email,coursePrepaid,deleted' }
        })
        .then(res =>  {
          if (res && res.length > 0) {
            commit('addMembersForClassroom', { classroomId: classroom._id, members: res })
          }
        })
        .catch((e) => noty({ text: 'Fetch user failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForClassroom', classroom._id))
    }
  }
}
