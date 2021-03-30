import * as teacherApi from 'app/core/api/teacher'

export default {
  namespaced: true,

  state: {
    loading: false,

    studentNames: {
      byId: {}
      // byName: []
    }
  },

  mutations: {
    setLoading: (state, loading) => {
      state.loading = loading
    },

    addStudentNames: (state, students) => {
      students.forEach((student, index) => {
        Vue.set(state.studentNames.byId, student._id, student.name)
        // Vue.set(state.studentNames.byName, index, student.name)
      })
    }
  },

  actions: {
    fetchStudentNamesForTeacher: ({ commit }, teacherId) => {
      commit('setLoading', true)

      return teacherApi.fetchAllStudentNames(teacherId)
        .then(res => {
          if (res) {
            commit('addStudentNames', res)
          } else {
            throw new Error('Unexpected response from fetch student names API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch student names failure' + e, type: 'error' }))
        .finally(() => commit('setLoading', false))
    }
  },

  getters: {
    studentNames (state) {
      return state.studentNames.byId
    },
    // studentNames (state) {
    //   return state.studentNames.byName
    // },
    isLoading (state) {
      return state.loading
    }
  }
}
