/**
 * This store tracks the student checkboxes.
 */

import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
import ClassroomLib from '../../../app/models/ClassroomLib'
import { hasSharedWriteAccessPermission } from '../../../app/lib/classroom-utils'

// TODO: Ensure download size isn't too big.
const projectionData = {
  levelSessions: 'state.complete,state.introContentSessionComplete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage,introContentSessionComplete,playtime',
  users: 'firstName,lastName,name,email,products,coursePrepaid,coursePrepaidID,deleted'
}

export default {
  namespaced: true,
  state: {
    selectedStudents: {},
    // This is either the student id being editted, or null.
    editingStudent: null,
    // Used to group together hover feedback for intro levels.
    showingTooltipOfThisOriginal: null,

    selectedOriginals: []
  },

  getters: {
    isStudentSelected: (state) => (studentId) => {
      return state.selectedStudents[studentId] || false
    },

    selectedStudentIds (state) {
      return Object.keys(state.selectedStudents || [])
    },

    selectedOriginals (state) {
      return state.selectedOriginals
    },

    currentEditingStudent (state) {
      return state.editingStudent
    },

    getShowingTooltipOfThisOriginal (state) {
      return state.showingTooltipOfThisOriginal
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
    },

    setShowingTooltipOfThisOriginal (state, normalizedOriginal) {
      Vue.set(state, 'showingTooltipOfThisOriginal', normalizedOriginal)
    },

    replaceSelectedOriginals (state, list = []) {
      state.selectedOriginals = list
      Vue.set(state, 'selectedOriginals', list)
    },

    updateSelectedOriginals (state, { shiftKey, original, listOfOriginals = [] }) {
      const indexOfOriginal = listOfOriginals.indexOf(original)

      if (state.selectedOriginals.includes(original)) {
        state.selectedOriginals = state.selectedOriginals.filter(o => o !== original)
        if (shiftKey) {
          // Remove all levels between the last unselectd selected level and the current level
          const indexOfLastSelected = listOfOriginals.indexOf(state.selectedOriginals[state.selectedOriginals.length - 1])
          const start = Math.min(indexOfOriginal, indexOfLastSelected)
          const end = Math.max(indexOfOriginal, indexOfLastSelected)
          const range = listOfOriginals.slice(start, end + 1)
          state.selectedOriginals = state.selectedOriginals.filter(o => !range.includes(o))
        }
      } else {
        state.selectedOriginals.push(original)
        if (shiftKey) {
          // Select all levels between the last selected level and the current level
          const indexOfLastSelected = listOfOriginals.indexOf(state.selectedOriginals[state.selectedOriginals.length - 2])
          const start = Math.min(indexOfOriginal, indexOfLastSelected)
          const end = Math.max(indexOfOriginal, indexOfLastSelected)
          const range = listOfOriginals.slice(start, end + 1)
          state.selectedOriginals = [...state.selectedOriginals, ...range]
        }
      }

      const selectedList = [...state.selectedOriginals]
      Vue.set(state, 'selectedOriginals', selectedList)
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

    fetchData ({ dispatch }, options) {
      dispatch('teacherDashboard/fetchData', { componentName: COMPONENT_NAMES.MY_CLASSES_SINGLE, options: _.assign({ data: projectionData }, options) }, { root: true })
    },

    async applyLicenses ({ state, rootGetters, dispatch, getters }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      // use teacherId of classroom owner instead?
      let teacherId = rootGetters['teacherDashboard/teacherId']
      const classroom = rootGetters['teacherDashboard/getCurrentClassroom']
      const hasSharedWriteAccess = hasSharedWriteAccessPermission(classroom)

      // for shared classes, use ownerID of classroom to deduct/apply license
      if (classroom.ownerID !== teacherId) {
        if (hasSharedWriteAccess) {
          teacherId = classroom.ownerID
        } else {
          noty({ text: `You do not have a write permission on this class`, layout: 'center', type: 'information', killer: true, timeout: 5000 })
          return
        }
      }

      if (students.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        return
      }
      const sharedClassroomId = hasSharedWriteAccess ? classroom._id : null
      await dispatch('prepaids/applyLicenses', { members: students, teacherId, sharedClassroomId }, { root: true })
      dispatch('prepaids/fetchPrepaidsForTeacher', { teacherId, sharedClassroomId }, { root: true })
      await dispatch('users/fetchClassroomMembers', { classroom: rootGetters['teacherDashboard/getCurrentClassroom'], options: { project: projectionData.users } }, { root: true })
      // TODO confirmation?
    },

    async revokeLicenses ({ state, rootGetters, dispatch, getters }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      if (students.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        return
      }
      let teacherId = rootGetters['teacherDashboard/teacherId']
      const classroom = rootGetters['teacherDashboard/getCurrentClassroom']
      const hasSharedWriteAccess = hasSharedWriteAccessPermission(classroom)

      // for shared classes, use ownerID of classroom to deduct/apply license
      if (classroom.ownerID !== teacherId) {
        if (hasSharedWriteAccess) {
          teacherId = classroom.ownerID
        } else {
          noty({ text: `You do not have a write permission on this class`, layout: 'center', type: 'information', killer: true, timeout: 5000 })
          return
        }
      }

      const sharedClassroomId = hasSharedWriteAccess ? classroom._id : null
      await dispatch('prepaids/revokeLicenses', { members: students, sharedClassroomId }, { root: true })
      dispatch('prepaids/fetchPrepaidsForTeacher', { teacherId, sharedClassroomId }, { root: true })
      await dispatch('users/fetchClassroomMembers', { classroom: rootGetters['teacherDashboard/getCurrentClassroom'], options: { project: projectionData.users } }, { root: true })
      // TODO confirmation?
    },

    /**
     * lockSelectedStudents will set the lock on selected students.
     * Passing in `original` as undefined will lock the entire course.
     * Level originals passed in should be in the cached class level list.
     */
    async updateLevelAccessStatusForSelectedStudents ({ rootGetters, getters, dispatch }, {
      classroom,
      currentCourseId,
      onSuccess,
      modifiers = [],
      value = true,
      levels = [],
      date
    }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      if (students.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        window.tracker?.trackEvent('Failure to lock', { category: 'Teachers' })
        return
      }

      if (!currentCourseId) {
        throw new Error('You cannot lock an undefined course.')
      }

      // Cloning the classroom so we aren't mutating a vue store object.
      const clonedClass = JSON.parse(JSON.stringify(classroom))

      let numberStudentsChanged = 0

      for (const modifier of modifiers) {
        for (const { _id } of students) {
          // Only lock if this level is unlocked

          const levelsToHandle = levels.filter((level) => {
            if (value) {
              return !ClassroomLib.isModifierActiveForStudent(clonedClass, _id, currentCourseId, level, modifier, date)
            } else {
              return ClassroomLib.isModifierActiveForStudent(clonedClass, _id, currentCourseId, level, modifier, date)
            }
          })

          if (
            levelsToHandle.length > 0 ||
            ((!levels || levels.length === 0) && !ClassroomLib.isStudentOnLockedCourse(clonedClass, _id, currentCourseId))
          ) {
            numberStudentsChanged += 1
            ClassroomLib.setModifierForStudent(clonedClass, _id, currentCourseId, levelsToHandle, date, modifier, value)
          }
        }
      }

      if (numberStudentsChanged === 0) {
        noty({
          text: `Levels already modified for these students`,
          layout: 'center',
          type: 'information',
          killer: true,
          timeout: 5000
        })
        return
      }

      onSuccess?.()
      dispatch('classrooms/updateClassroom', {
        classroom,
        updates: {
          studentLockMap: clonedClass.studentLockMap
        }
      },
      { root: true })
    },
  }
}
