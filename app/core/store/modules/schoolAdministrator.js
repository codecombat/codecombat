export default {
  namespaced: true,

  state: {
    loading: false,
    isSchoolAdministrator: false,
    administratedTeachers: []
  },

  mutations: {
    toggleLoading: (state) => state.loading = !state.loading,

    addTeachers: (state, teachers) => {
      state.administratedTeachers = teachers;
    }
  },

  actions: {
    fetch: ({ commit }) => {
      commit('toggleLoading')

      setTimeout(() => {
        commit(
          'addTeachers',
          [
            { name: 'Teacher 1', email: 'teacher1@education.com', lastLogin: 'LAST_LOGIN' },
            { name: 'Teacher 2', email: 'teacher2@education.com', lastLogin: 'LAST_LOGIN' },
          ]
        )

        commit('toggleLoading')
      }, 1000)
    }
  }
}

