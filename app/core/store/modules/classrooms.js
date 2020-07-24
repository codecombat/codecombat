import classroomsApi from 'core/api/classrooms'
import courseInstancesApi from 'core/api/course-instances'

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
      byTeacher: {} // used for teacher dashboard, TODO combine byClassroom/byTeacher?
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

    addNewClassroomForTeacher: (state, { teacherId, classroom }) => {
      const teacherClassroomsState = {
        active: state.classrooms.byTeacher[teacherId].active || [],
        archived: state.classrooms.byTeacher[teacherId].archived || []
      }

      // return if classroom already present
      if (teacherClassroomsState.active.find((c) => c._id === classroom._id) || teacherClassroomsState.archived.find((c) => c._id === classroom._id)) {
        return
      }

      if (classroom.archived) {
        teacherClassroomsState.archived.push(classroom)
      } else {
        teacherClassroomsState.active.push(classroom)
      }

      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    },

    addClassroomForId: (state, { classroomID, classroom }) => {
      Vue.set(state.classrooms.byClassroom, classroomID, classroom)
    },

    addMembersForClassroom: (state, { teacherId, classroomId, memberIds }) => {
      if (!state.classrooms.byTeacher[teacherId]) {
        return
      }
      const teacherClassroomsState = {
        active: state.classrooms.byTeacher[teacherId].active || [],
        archived: state.classrooms.byTeacher[teacherId].archived || []
      }
      const classroom = teacherClassroomsState.active.find((c) => c._id === classroomId)
      classroom.members = (classroom.members || []).concat(memberIds)
      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    },

    removeMembersForClassroom: (state, { teacherId, classroomId, memberIds }) => {
      if (!state.classrooms.byTeacher[teacherId]) {
        return
      }
      const teacherClassroomsState = {
        active: state.classrooms.byTeacher[teacherId].active || [],
        archived: state.classrooms.byTeacher[teacherId].archived || []
      }
      const classroom = teacherClassroomsState.active.find((c) => c._id === classroomId)
      classroom.members = (classroom.members || []).filter((m) => !memberIds.includes(m))
      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    },
    // update a property in classroom / archive or un-archive a classroom
    updateClassroom: (state, { teacherId, classroomId, updates }) => {
      if (!state.classrooms.byTeacher[teacherId]) {
        return
      }
      const teacherClassroomsState = {
        active: state.classrooms.byTeacher[teacherId].active || [],
        archived: state.classrooms.byTeacher[teacherId].archived || []
      }

      const classroom = teacherClassroomsState.active.find((c) => c._id === classroomId) || teacherClassroomsState.archived.find((c) => c._id === classroomId)

      for (const key in updates) {
        classroom[key] = updates[key]
      }

      if (typeof updates.archived === 'boolean') {
        if (updates.archived === true) {
          teacherClassroomsState.active = teacherClassroomsState.active.filter((c) => c._id !== classroomId)
          if (!teacherClassroomsState.archived.includes(classroom)) {
            teacherClassroomsState.archived.push(classroom)
          }
        } else if (updates.archived === false) {
          teacherClassroomsState.archived = teacherClassroomsState.archived.filter((c) => c._id !== classroomId)
          if (!teacherClassroomsState.active.includes(classroom)) {
            teacherClassroomsState.active.push(classroom)
          }
        }
      }
      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    }
  },

  getters: {
    getClassroomsByTeacher: (state) => (id) => {
      return state.classrooms.byTeacher[id]
    },
    getActiveClassroomsByTeacher: (state) => (id) => {
      return (state.classrooms.byTeacher[id] || {}).active
    },
    getArchivedClassroomsByTeacher: (state) => (id) => {
      return (state.classrooms.byTeacher[id] || {}).archived
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
        .catch((e) => noty({ text: 'Fetch classrooms failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
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
        .catch((e) => noty({ text: 'Get classroom failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForClassroom', classroomID))
    },
    createClassroom: ({ commit }, options) => {
      return classroomsApi.post(options)
        .then(res => {
          if (res) {
            commit('addNewClassroomForTeacher', {
              teacherId: res.ownerID,
              classroom: res
            })
            return res
          } else {
            throw new Error('Unexpected response from create classroom API.')
          }
        })
    },
    // Removes members from classroom and updates the vuex state for classroom
    removeMembersFromClassroom: async ({ rootGetters, commit, dispatch }, options) => {
      const memberIds = options.memberIds
      const classroom = options.classroom
      const courseInstances = rootGetters['courseInstances/getCourseInstancesForClass'](classroom.ownerID, classroom._id) || []

      const removePromises = []
      memberIds.forEach((mId) => {
        const ciIds = (courseInstances
          .filter((ci) => ci.members.includes(mId)) || [])
          .map((ci) => ci._id)
        ciIds.forEach((ciId) => {
          removePromises.push(courseInstancesApi.removeMember(ciId, { memberId: mId }))
        })
        removePromises.push(classroomsApi.removeMember({ classroomID: classroom._id, userId: mId }))
      })
      await Promise.all(removePromises).then(() => {
        dispatch('fetchClassroomsForTeacher', classroom.ownerID)
        commit('removeMembersForClassroom', { teacherId: classroom.ownerID, classroomId: classroom._id, memberIds: memberIds })
      })
    },
    // Adds members to classroom and updates the vuex state for classroom
    addMembersToClassroom: async ({ commit, dispatch }, options) => {
      const members = options.members || []
      const memberIds = members.map((m) => m._id)
      const classroom = options.classroom
      await classroomsApi.addMembers({ classroomID: classroom._id, members: members })
      commit('addMembersForClassroom', { teacherId: classroom.ownerID, classroomId: classroom._id, memberIds: memberIds })
      // Load classroom data
      dispatch('baseSingleClass/fetchData', {}, { root: true })
    },
    // Updates the classroom and its vuex state
    updateClassroom: async ({ commit }, options) => {
      const classroom = options.classroom
      await classroomsApi.update({ classroomID: classroom._id, updates: options.updates })
      commit('updateClassroom', { teacherId: classroom.ownerID, classroomId: classroom._id, updates: options.updates })
    }
  }
}
