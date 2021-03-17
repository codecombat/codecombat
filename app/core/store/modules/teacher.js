import teacherApi from 'app/core/api/teacher'

export default {
  namespaced: true,

  state: {
    loading: false,

    studentNames: {
      byId: {}
    }
  },

  mutations: {
    toggleLoading: (state, loading) => {
      state.loading = loading
    },

    addStudentNames: (state, students) => {
      for (const student of students) {
        Vue.set(state.studentNames.byId, student._id, student.name)
      }
    }
  },

  actions: {
    fetchStudentNamesForTeacher: ({ commit }, teacherId) => {
      commit('toggleLoading', true)

      return teacherApi.fetchAllStudentNames(teacherId)
        .then(res => {
          if (res) {
            commit('addStudentNames', res)
          } else {
            throw new Error('Unexpected response from fetch student names API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch student names failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoading', false))
    }
  }
}
