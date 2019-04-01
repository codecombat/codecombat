import usersApi from 'core/api/users'

export default {
  namespaced: true,

  state: {
    loading: {
      teacher: false,
      classrooms: false,
      teachers: false
    },

    teacher: undefined,

    isSchoolAdministrator: false,
    administratedTeachers: [],
  },

  mutations: {
    toggleLoading: (state, key) => state.loading[key] = !state.loading[key],

    setTeacher: (state, teacher) => state.teacher = teacher,

    addTeachers: (state, teachers) => {
      state.administratedTeachers = teachers;
    },
  },

  actions: {
    fetchTeachers: ({ commit, rootState }) => {
      commit('toggleLoading', 'teachers')

      return usersApi
        .fetchByIds(rootState.me.administratedTeachers || [])
        .then(res =>  {
          if (res) {
            commit('addTeachers', res)
          } else {
            throw new Error('Unexpected response from teachers by ID API.')
          }
        })
        .catch((e) => console.error('Fetch teachers failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'teachers'))
    },

    fetchTeacher: ({ commit, state }, id) => {
      commit('toggleLoading', 'teacher')

      let resultPromise;
      const teacher = state.administratedTeachers.find(t => t.id === id);

      if (teacher) {
        resultPromise = Promise.resolve(teacher);
      } else {
        resultPromise = usersApi
          .fetchByIds([ id ])
          .then(res =>  {
            if (res && res.length === 1) {
              commit('setTeacher', res[0])
            } else {
              throw new Error('Unexpected response returned from teacher API')
            }
          })
          .catch((e) => console.error('Fetch teachers failure', e)) // TODO handle this
      }

      return resultPromise
        .finally(() => commit('toggleLoading', 'teacher'))
    },
  }
}

