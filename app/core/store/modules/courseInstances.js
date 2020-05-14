import courseInstancesApi from 'core/api/course-instances'

export default {
  namespaced: true,

  state: {
    loading: {
      byTeacher: {}
    },

    courseInstancesByTeacher: {}
  },

  getters: {
    // to get cis for a particluar class of the teacher
    getCourseInstancesForClass: (state) => (teacherId, classroomId) => {
      const cis = state.courseInstancesByTeacher[teacherId] || []
      return cis.filter((ci) => ci.classroomID == classroomId)
    }
  },

  mutations: {
    toggleTeacherLoading: (state, teacherId) => {
      let loading = true
      if (state.loading.byTeacher[teacherId]) {
        loading = false
      }

      Vue.set(state.loading.byTeacher, teacherId, loading)
    },

    addCourseInstancesForTeacher: (state, { teacherId, instances }) =>
      Vue.set(state.courseInstancesByTeacher, teacherId, instances)
  },

  actions: {
    fetchCourseInstancesForTeacher: ({ commit }, teacherId) => {
      commit('toggleTeacherLoading', teacherId)

      return courseInstancesApi
        .fetchByOwner(teacherId)
        .then(res =>  {
          if (res) {
            commit('addCourseInstancesForTeacher', {
              teacherId,
              instances: res
            })
          } else {
            throw new Error('Unexpected response from course instances by owner API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch course instances failure: ' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleTeacherLoading', teacherId))
    },
  }
}
