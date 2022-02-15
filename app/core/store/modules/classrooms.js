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

  getters: {
    classroomById(state) {
      return (id) => {
        return state.classrooms.byClassroom[id]
      }
    }
  },

  mutations: {
    toggleLoadingForTeacher: (state, teacherId) => {
      Vue.set(
        state.loading.byTeacher,
        teacherId,
        !state.loading.byTeacher[teacherId]
      )
    },

    toggleLoadingForClassroom: (state, classroomID) => {
      Vue.set(
        state.loading.byClassroom,
        classroomID,
        !state.loading.byClassroom[classroomID]
      )
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

    addClassroomForId: (state, { classroomID, classroom }) => {
      Vue.set(state.classrooms.byClassroom, classroomID, classroom)
    },

    updateClassroomById: (state, { classroomID, updates }) => {
      let classroom = state.classrooms.byClassroom[classroomID]
      if (!classroom) {
        console.error('classroom not found for update')
        return
      }
      classroom = { ...classroom }
      for (const key in updates) {
        classroom[key] = updates[key]
      }
      Vue.set(state.classrooms.byClassroom, classroomID, classroom)
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
    fetchClassroomForId: ({ commit }, classroomID) => {
      commit('toggleLoadingForClassroom', classroomID)

      return classroomsApi.get({ classroomID })
        .then(res =>  {
          if (res) {
            commit('addClassroomForId', {
              classroomID,
              classroom: res
            })
          } else {
            throw new Error('Unexpected response from get classroom API.')
          }
        })
        .catch((e) => noty({ text: 'Get classroom failure' + e, type: 'error' }))
        .finally(() => commit('toggleLoadingForClassroom', classroomID))
    },
    addPermission: async ({ commit }, options) => {
      const classroom = options.classroom
      const params = { classroomID: classroom._id, permission: options.permission }
      const response = await classroomsApi.addPermission(params)

      commit('updateClassroomById', {
        classroomID: classroom._id,
        updates: { permissions: response.data } // use response.permissions ?
      })
    },
    removePermission: async ({ commit }, options) => {
      const classroom = options.classroom
      const params = { classroomID: classroom._id, permission: options.permission }
      const response = await classroomsApi.removePermission(params)

      commit('updateClassroomById', {
        classroomID: classroom._id,
        updates: { permissions: response.data } // use response.permissions ?
      })
    },
  }
}

