/**
 * This store tracks the student checkboxes.
 */

import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
// TODO: Ensure download size isn't too big.
const projectionData = {
  levelSessions: 'state.complete,state.introContentSessionComplete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage,introContentSessionComplete,playtime',
  users: 'firstName,lastName,name,email,coursePrepaid,coursePrepaidID,deleted'
}

export default {
  namespaced: true,
  state: {
    selectedStudents: {},
    // This is either the student id being editted, or null.
    editingStudent: null
  },

  getters: {
    isStudentSelected: (state) => (studentId) => {
      return state.selectedStudents[studentId] || false
    },

    selectedStudentIds (state) {
      return Object.keys(state.selectedStudents || [])
    },

    currentEditingStudent (state) {
      return state.editingStudent
    }
  },

  mutations: {
    setCheckedStudent (state, { studentId }) {
      if (state.selectedStudents[studentId]) {
        return
      }
      Vue.set(state.selectedStudents, studentId, true)
    },

    removeCheckedStudent (state, { studentId }) {
      Vue.delete(state.selectedStudents, studentId)
    },

    clearSelectedStudents (state) {
      state.selectedStudents = {}
    },

    openModalEditStudent (state, studentId) {
      state.editingStudent = studentId
    },

    closeModalEditStudent (state) {
      state.editingStudent = undefined
    }
  },

  actions: {
    addStudentSelectedId ({ commit }, { studentId }) {
      commit('setCheckedStudent', { studentId })
    },

    removeStudentSelectedId ({ commit }, { studentId }) {
      commit('removeCheckedStudent', { studentId })
    },

    toggleStudentSelectedId ({ dispatch, state }, { studentId }) {
      if (state.selectedStudents[studentId]) {
        dispatch('removeStudentSelectedId', { studentId })
      } else {
        dispatch('addStudentSelectedId', { studentId })
      }
    },

    clearSelectedStudents ({ commit }) {
      commit('clearSelectedStudents')
    },

    fetchData ({ dispatch }) {
      dispatch('teacherDashboard/fetchData', { componentName: COMPONENT_NAMES.MY_CLASSES_SINGLE, options: { data: projectionData } }, { root: true })
    },

    async applyLicenses ({ state, rootGetters, dispatch, getters }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      const teacherId = rootGetters['teacherDashboard/teacherId']
      if (students.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        return
      }
      await dispatch('prepaids/applyLicenses', { members: students, teacherId }, { root: true })
      dispatch('prepaids/fetchPrepaidsForTeacher', teacherId, { root: true })
      await dispatch('users/fetchClassroomMembers', { classroom: rootGetters['teacherDashboard/classroom'], options: { project: projectionData.users } }, { root: true })
      // TODO confirmation?
    },

    async revokeLicenses ({ state, rootGetters, dispatch, getters }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      if (students.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        return
      }
      const teacherId = rootGetters['teacherDashboard/teacherId']
      await dispatch('prepaids/revokeLicenses', { members: students }, { root: true })
      dispatch('prepaids/fetchPrepaidsForTeacher', teacherId, { root: true })
      await dispatch('users/fetchClassroomMembers', { classroom: rootGetters['teacherDashboard/classroom'], options: { project: projectionData.users } }, { root: true })
      // TODO confirmation?
    }
  }
}
