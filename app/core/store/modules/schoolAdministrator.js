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

      const groups = Math.ceil(administratedTeachers.length / 100.0)
      const userPromises = []
      for (let i = 0; i < groups; i++) {
        userPromises.push(
          usersApi
            .fetchByIds({
              fetchByIds: administratedTeachers,
              includeTrialRequests: true
            })
            .then(res => {
              if (res) {
                return res
              } else {
                throw new Error('Unexpected response from teachers by ID API.')
              }
            })
        )
      }

      return Promise.all(userPromises)
        .then(groupResults => groupResults.flat())
        .then(combinedResults => commit('addTeachers', combinedResults))
        .catch((e) => noty({ text: 'Fetch teachers failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoading', 'teachers'))
    },
  }
}

