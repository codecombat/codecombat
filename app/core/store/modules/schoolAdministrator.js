import usersApi from 'core/api/users'

export default {
  namespaced: true,

  state: {
    loading: {
      classrooms: false,
      teachers: false
    },

    isSchoolAdministrator: false,
    administratedTeachers: [],
  },

  mutations: {
    toggleLoading: (state, key) => state.loading[key] = !state.loading[key],

    addTeachers: (state, teachers) => {
      state.administratedTeachers = teachers;
    },
  },

  actions: {
    fetchTeachers: ({ commit, rootState }) => {
      const administratedTeachers = rootState.me.administratedTeachers || []
      if (administratedTeachers.length === 0) {
        return
      }

      commit('toggleLoading', 'teachers')

      return usersApi
        .fetchByIds({
          fetchByIds: administratedTeachers,
          includeTrialRequests: true
        })
        .then(res =>  {
          if (res) {
            commit('addTeachers', res)
          } else {
            throw new Error('Unexpected response from teachers by ID API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch teachers failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoading', 'teachers'))
    },
  }
}

