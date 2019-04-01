import courseInstancesApi from 'core/api/course-instances'

export default {
  namespaced: true,

  state: {
    loading: {
      courseInstances: true
    },

    courseInstances: []
  },

  mutations: {
    toggleLoading: (state, key) => state.loading[key] = !state.loading[key],

    addCourseInstances: (state, courseInstances) => state.courseInstances = courseInstances
  },

  actions: {
    fetchCourseInstancesForTeacher: ({ commit }, teacherId) => {
      commit('toggleLoading', 'courseInstances')

      return courseInstancesApi
        .fetchByOwner(teacherId)
        .then(res =>  {
          if (res) {
            commit('addCourseInstances', res)
          } else {
            throw new Error('Unexpected response from course instances by owner API.')
          }
        })
        .catch((e) => console.error('Fetch course instances failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'courseInstances'))
    },
  }
}
