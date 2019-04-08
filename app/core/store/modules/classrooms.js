import classroomsApi from 'core/api/classrooms'

export default {
  namespaced: true,

  state: {
    loading: {
      byClassroom: {},
      byTeacher: {}
    },

    classrooms: {
      byClassroom: {},
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

    toggleLoadingForClassroom: (state, classroomId) => {
      let loading = true
      if (state.loading.byClassroom[classroomId]) {
        loading = false
      }

      Vue.set(state.loading.byClassroom, classroomId, loading)
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
    },

    addClassroomForId: (state, { classroomId, classroom }) => {
      Vue.set(state.classrooms.byClassroom, classroomId, classroom)
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
    fetchClassroomForId: ({ commit }, classroomId) => {
      commit('toggleLoadingForClassroom', classroomId)
      console.log('entered fetchclassroomforid with ')
      console.log(classroomId)

      return classroomsApi.get({ classroomId })
        .then(res =>  {
          if (res) {
            commit('addClassroomForId', {
              classroomId,
              classroom: res
            })
          } else {
            throw new Error('Unexpected response from get classroom API.')
          }
        })
        .catch((e) => noty({ text: 'Get classroom failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoadingForClassroom', classroomId))
    }
  }
}

