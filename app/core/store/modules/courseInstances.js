import courseInstancesApi from 'core/api/course-instances'

export default {
  namespaced: true,

  state: {
    loading: {
      byId: {},
      byTeacher: {}
    },

    byId: {},
    courseInstancesByTeacher: {}
  },

  mutations: {
    toggleIdLoading: (state, id) => {
      let loading = true
      if (state.loading.byId[id]) {
        loading = false
      }

      Vue.set(state.loading.byId, id, loading)
    },

    toggleTeacherLoading: (state, teacherId) => {
      let loading = true
      if (state.loading.byTeacher[teacherId]) {
        loading = false
      }

      Vue.set(state.loading.byTeacher, teacherId, loading)
    },

    addCourseInstanceForId: (state, courseInstance) =>
      Vue.set(state.course),

    addCourseInstancesForTeacher: (state, { teacherId, instances }) =>
      Vue.set(state.courseInstancesByTeacher, teacherId, instances)
  },

  actions: {
    fetchById: async ({ commit }, courseInstanceId) => {
      commit('toggleIdLoading', courseInstanceId)

      try {
        const result = courseInstancesApi.get(courseInstanceId)
        if (result) {
          commit('addCourseInstanceForId', result)
          return result
        }

        throw new Error('Unexpected result format')
      } catch (e) {
        // TODO handle
      } finally {
        commit('toggleIdLoading', courseInstanceId)
      }
    },

    fetchCourseInstancesForTeacher: ({ commit }, teacherId) => {
      commit('toggleTeacherLoading', teacherId)

      return courseInstancesApi
        .fetchByOwner(teacherId)
        .then(res => {
          if (res) {
            commit('addCourseInstancesForTeacher', {
              teacherId,
              instances: res
            })
          } else {
            throw new Error('Unexpected response from course instances by owner API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch course instances failure: ' + e, type: 'error' }))
        .finally(() => commit('toggleTeacherLoading', teacherId))
    }
  }
}
