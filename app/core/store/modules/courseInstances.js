import Vue from 'vue'

import courseInstancesApi from 'core/api/course-instances'

export default {
  namespaced: true,

  state: {
    loading: {
      byTeacher: {}
    },

    courseInstancesByTeacher: {}
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
        .catch((e) => console.error('Fetch course instances failure', e)) // TODO handle this
        .finally(() => commit('toggleTeacherLoading', teacherId))
    },
  }
}
