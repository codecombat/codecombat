import usersApi from 'core/api/users'

export default {
  namespaced: true,

  state: {
    loading: {
      teacher: false,
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
      commit('toggleLoading', 'teachers')

      return usersApi
        .fetchByIds({
          fetchByIds: rootState.me.administratedTeachers || [],
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

