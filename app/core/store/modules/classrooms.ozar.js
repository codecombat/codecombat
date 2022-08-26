import classroomsApi from 'core/api/classrooms'
import courseInstancesApi from 'core/api/course-instances'
import storage from 'core/storage'
import _ from 'lodash'

function getTeacherIdBasedOnSharedWritePermission(classroom) {
  let teacherId = classroom.ownerID
  const hasSharedWriteAccess = (classroom.permissions || []).find(p => p.target === me.get('_id') && p.access === 'write')
  if (hasSharedWriteAccess) {
    teacherId = me.get('_id')
  }
  return teacherId
}

export default {
  namespaced: true,

  state: {
    loading: {
      byClassroom: {},
      byTeacher: {},
      byCourseInstanceId: {}
    },

    classrooms: {
      byClassroom: {},
      // Classrooms by teacher ID
      //  {
      //     active: [],
      //     archived: []
      //  }
      byTeacher: {}, // used for teacher dashboard, TODO combine byClassroom/byTeacher?
      byCourseInstanceId: {}
    },

    // TODO: Handle HoC classrooms and "most recent classroom" better. This is a hack
    // for HoC 2020, so classCode is shown in the LayoutChrome
    mostRecentClassCode: ''
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

    toggleLoadingForCourseInstanceId: (state, courseInstanceId) => {
      Vue.set(
        state.loading.byCourseInstanceId,
        courseInstanceId,
        !state.loading.byCourseInstanceId[courseInstanceId]
      )
    },

    addClassroomsForTeacher: (state, { teacherId, classrooms }) => {
      const teacherClassroomsState = {
        active: [],
        archived: [],
        shared: []
      }

      classrooms.forEach((classroom) => {
        if (classroom.ownerID !== teacherId) {
          teacherClassroomsState.shared.push(classroom)
        } else if (classroom.archived) {
          teacherClassroomsState.archived.push(classroom)
        } else {
          teacherClassroomsState.active.push(classroom)
        }
      })

      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    },

    addNewClassroomForTeacher: (state, { teacherId, classroom }) => {
      const currentClassrooms = state.classrooms.byTeacher[teacherId] || {}
      const teacherClassroomsState = {
        active: currentClassrooms.active || [],
        archived: currentClassrooms.archived || [],
        shared: currentClassrooms.shared || [] // classes that have been shared by other teachers
      }

      // return if classroom already present
      if (teacherClassroomsState.active.find((c) => c._id === classroom._id) || teacherClassroomsState.archived.find((c) => c._id === classroom._id) ||
          teacherClassroomsState.shared.find((c) => c._id === classroom._id)) {
        return
      }

      if (classroom.ownerID !== teacherId) {
        teacherClassroomsState.shared.push(classroom)
      } else if (classroom.archived) {
        teacherClassroomsState.archived.push(classroom)
      } else {
        teacherClassroomsState.active.push(classroom)
      }
      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    },

    addClassroomForId: (state, { classroomID, classroom }) => {
      Vue.set(state.classrooms.byClassroom, classroomID, classroom)
    },

    addClassroomForCourseInstanceId: (state, { courseInstanceId, classroom }) => {
      Vue.set(state.classrooms.byCourseInstanceId, courseInstanceId, classroom)
    },

    addMembersForClassroom: (state, { teacherId, classroomId, memberIds }) => {
      if (!state.classrooms.byTeacher[teacherId]) {
        return
      }
      const teacherClassroomsState = {
        active: state.classrooms.byTeacher[teacherId].active || [],
        archived: state.classrooms.byTeacher[teacherId].archived || [],
        shared: state.classrooms.byTeacher[teacherId].shared || []
      }
      const classrooms = [...teacherClassroomsState.active, ...teacherClassroomsState.shared]
      const classroom = classrooms.find((c) => c._id === classroomId)
      if (!classroom) {
        return
      }
      classroom.members = (classroom.members || []).concat(memberIds)
      Vue.set(state.classrooms.byTeacher, teacherId, teacherClassroomsState)
    },

    removeMembersForClassroom: (state, { teacherId, classroomId, memberIds }) => {
      if (!state.classrooms.byTeacher[teacherId]) {
        return
      }
      const teacherClassroomsState = {
        active: state.classrooms.byTeacher[teacherId].active || [],
        archived: state.classrooms.byTeacher[teacherId].archived || [],
        shared: state.classrooms.byTeacher[teacherId].shared || []
      }
      const classrooms = [...teacherClassroomsState.active, ...teacherClassroomsState.shared]
      const classroom = classrooms.find((c) => c._id === classroomId)
      if (!classroom) {
        return
      }
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
        archived: state.classrooms.byTeacher[teacherId].archived || [],
        shared: state.classrooms.byTeacher[teacherId].shared || []
      }
      const classrooms = [...teacherClassroomsState.active, ...teacherClassroomsState.shared, ...teacherClassroomsState.archived]
      const classroom = classrooms.find((c) => c._id === classroomId)
      if (!classroom) {
        return
      }
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
    },

    setMostRecentClassCode: (state, classCode) => {
      state.mostRecentClassCode = classCode
      // Persisting to local storage to help HoC users always have their class code in the layout chrome
      // TODO: Probably better ways to handle this! :)
      storage.save('most-recent-class-code', classCode)
    }
  },

  getters: {
    getClassroomsByTeacher: (state) => (id) => {
      return state.classrooms.byTeacher[id]
    },
    getClassroomByCourseInstanceId: (state) => (id) => {
      return state.classrooms.byCourseInstanceId[id]
    },
    getActiveClassroomsByTeacher: (state) => (id) => {
      return (state.classrooms.byTeacher[id] || {}).active
    },
    getArchivedClassroomsByTeacher: (state) => (id) => {
      return (state.classrooms.byTeacher[id] || {}).archived
    },
    getSharedClassroomsByTeacher: (state) => (id) => {
      return (state.classrooms.byTeacher[id] || {}).shared
    },
    getMostRecentClassCode: (state) => {
      if (state.mostRecentClassCode?.length > 0) {
        return state.mostRecentClassCode
      }

      // For teachers who reload their page or come back after HoC sign up, still show class code:
      if (me.isTeacher()) {
        return storage.load('most-recent-class-code')
      }
    },
    getClassroomById: (state) => (id) => {
      return state.classrooms.byClassroom[id]
    }
  },

  actions: {
    fetchClassroomsForTeacher: ({ commit }, { teacherId, project }) => {
      commit('toggleLoadingForTeacher', teacherId)

      return classroomsApi.fetchByOwner(teacherId, {
        project: project || ['_id', 'name', 'slug', 'members', 'deletedMembers', 'ownerID', 'code', 'codeCamel', 'aceConfig', 'archived', 'googleClassroomId', 'settings', 'studentLockMap', 'courses._id', 'courses.levels', 'permissions'],
        includeShared: true,
      })
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
            if (res.ownerID === me.get('_id') || (res.permissions || []).find(p => p.target === me.get('_id'))) {
              commit('addNewClassroomForTeacher', {
                classroom: res,
                teacherId: me.get('_id')
              })
            }
            commit('setMostRecentClassCode', res.codeCamel)
          } else {
            throw new Error('Unexpected response from get classroom API.')
          }
        })
        .catch((e) => noty({ text: 'failed to fetch classroom:' + e, type: 'error', layout: 'topCenter', timeout: 5000 }))
        .finally(() => commit('toggleLoadingForClassroom', classroomID))
    },
    fetchClassroomForCourseInstanceId: ({ commit }, courseInstanceId) => {
      commit('toggleLoadingForCourseInstanceId', courseInstanceId)

      return classroomsApi.fetchByCourseInstanceId(courseInstanceId)
      .then(res =>  {
        if (res) {
          commit('addClassroomForCourseInstanceId', {
            courseInstanceId,
            classroom: res
          })
          commit('setMostRecentClassCode', res.codeCamel)
        } else {
          throw new Error('Unexpected response from fetchByCourseInstanceId classroom API.')
        }
      })
      .catch((e) => noty({ text: 'Get classroom failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
      .finally(() => commit('toggleLoadingForCourseInstanceId', courseInstanceId))
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
      const teacherId = getTeacherIdBasedOnSharedWritePermission(classroom)
      await Promise.all(removePromises).then(() => {
        dispatch('fetchClassroomsForTeacher', { teacherId })
        commit('removeMembersForClassroom', { teacherId, classroomId: classroom._id, memberIds: memberIds })
      })
    },
    // Adds members to classroom and updates the vuex state for classroom
    addMembersToClassroom: async ({ commit, dispatch }, options) => {
      const members = options.members || []
      const memberIds = members.map((m) => m._id)
      const classroom = options.classroom
      await classroomsApi.addMembers({ classroomID: classroom._id, members: members })
      const teacherId = getTeacherIdBasedOnSharedWritePermission(classroom)
      commit('addMembersForClassroom', { teacherId, classroomId: classroom._id, memberIds: memberIds })
      // Load classroom data
      dispatch('baseSingleClass/fetchData', {}, { root: true })
    },
    // Updates the classroom and its vuex state
    updateClassroom: async ({ commit }, options) => {
      const classroom = options.classroom
      const response = await classroomsApi.update({ classroomID: classroom._id, updates: options.updates })
      const keysToUpdate = Object.keys(options.updates);
      const teacherId = getTeacherIdBasedOnSharedWritePermission(classroom)
      commit('updateClassroom', {
        teacherId,
        classroomId: classroom._id,
        updates: {
          ...options.updates,
          ..._.pick(response, keysToUpdate),
        }
      });
    },
    addPermission: async ({ commit }, options) => {
      const classroom = options.classroom
      const params = { classroomID: classroom._id, permission: options.permission }
      const response = await classroomsApi.addPermission(params)
      const teacherId = getTeacherIdBasedOnSharedWritePermission(classroom)
      commit('updateClassroom', {
        teacherId,
        classroomId: classroom._id,
        updates: { permissions: response.data } // use response.permissions ?
      })
    },
    removePermission: async ({ commit }, options) => {
      const classroom = options.classroom
      const params = { classroomID: classroom._id, permission: options.permission }
      const response = await classroomsApi.removePermission(params)

      const teacherId = getTeacherIdBasedOnSharedWritePermission(classroom)
      commit('updateClassroom', {
        teacherId,
        classroomId: classroom._id,
        updates: { permissions: response.data } // use response.permissions ?
      })
    },

    setMostRecentClassCode: ({ commit }, classCode) => {
      commit('setMostRecentClassCode', classCode)
    },

    setMostRecentClassroomId: ({ commit, state }, classroomId) => {
      // TODO: State should be set across all "by" lookups so it can be looked up properly, but hacking this
      // by unwrapping the teacher -> active -> classroom -> codeCamel
      let codeCamel = state?.classrooms?.byClassroom?.[classroomId]?.codeCamel
      if (!codeCamel) {
        codeCamel = Object.values(state?.classrooms?.byTeacher || {}).find(t => t?.active)?.active?.find(c => c?._id === classroomId)?.codeCamel
      }

      if (codeCamel) {
        commit('setMostRecentClassCode', codeCamel)
      }
    }
  }
}
