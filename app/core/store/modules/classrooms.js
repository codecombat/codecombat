import classroomsApi from 'core/api/classrooms'

export default {
  namespaced: true,

  state: {
    loading: {
      byTeacher: {}
    },

    classrooms: {
      // Classrooms by teacher ID
      //  {
      //     active: [],
      //     archived: []
      //  }
      byTeacher: {}
    }
  },

  mutations: {
    toggleLoadingForTeacher: (state, teacherId) => {
      let loading = true
      if (state.loading.byTeacher[teacherId]) {
        loading = false
      }

      Vue.set(state.loading.byTeacher, teacherId, loading)
    },

    addClassroomsForTeacher: (state, { teacherId, classrooms }) => {
      const teacherClassroomsState = {
        active: [],
        archived: []
      }

      classrooms.forEach((classroom) => {
        if (classroom.archived) {
          teacherClassroomsState.archived.push(classroom)
        } else {
          teacherClassroomsState.active.push(classroom)
        }
      })

      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    }
  },

  actions: {
    fetchClassroomsForTeacher: ({ commit }, teacherId) => {
      commit('toggleLoadingForTeacher', teacherId)

      return classroomsApi.fetchByOwner(teacherId)
        .then(res =>  {
          if (res) {
            commit('addClassroomsForTeacher', {
              teacherId,
              classrooms: res
            })
          } else {
            throw new Error('Unexpected response from fetch classrooms API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch classrooms failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoadingForTeacher', teacherId))
    },
  }
}

