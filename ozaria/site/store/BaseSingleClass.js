/**
 * This store tracks the student checkboxes.
 */

import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
import ClassroomLib from '../../../app/models/ClassroomLib'
import { hasSharedWriteAccessPermission } from '../../../app/lib/classroom-util'

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
    editingStudent: null,
    // Used to group together hover feedback for intro levels.
    showingTooltipOfThisOriginal: null
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
    async lockSelectedStudents ({ rootGetters, getters, dispatch }, {
      classroom,
      currentCourseId,
      onSuccess,
      original = undefined
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

      let numberStudentsLockChanged = 0

      for (const { _id } of students) {
        // Only lock if this level is unlocked
        if (
          (original && !ClassroomLib.isStudentOnLockedLevel(clonedClass, _id, currentCourseId, original)) ||
          (!original && !ClassroomLib.isStudentOnLockedCourse(clonedClass, _id, currentCourseId))
        ) {
          numberStudentsLockChanged += 1
          ClassroomLib.setStudentLockLevel(clonedClass, _id, currentCourseId, original)
        }
      }

      if (numberStudentsLockChanged === 0) {
        noty({
          text: `Levels already locked for these students`,
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

    // Unlocks locked level original in the currentCourseId.
    // If called without a currentCourseId and original will entirely unlock student.
    async unlockSelectedStudents ({ rootGetters, getters, dispatch }, {
      classroom,
      currentCourseId,
      onSuccess,
      original = undefined
    }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      if (students.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        window.tracker?.trackEvent('Failure to lock', { category: 'Teachers' })
        return
      }

      // Cloning the classroom so we aren't mutating a vue store object.
      const clonedClass = JSON.parse(JSON.stringify(classroom))

      let numberStudentsLockChanged = 0

      for (const { _id } of students) {
        // Only set the locked level point on a level that is already locked.
        // This guarantees that unlocking always unlocks more levels. If this
        // level is unlocked, then we would lock it and cause behavior that looks
        // like locking instead of unlocking.
        if (
          (original && ClassroomLib.isStudentOnLockedLevel(clonedClass, _id, currentCourseId, original)) ||
          (!original && ClassroomLib.isStudentOnLockedCourse(clonedClass, _id, currentCourseId)) ||
          (!original && !currentCourseId) // completely unlock student
        ) {
          numberStudentsLockChanged += 1
          ClassroomLib.setStudentLockLevel(clonedClass, _id, currentCourseId, original)
        }
      }

      if (numberStudentsLockChanged === 0) {
        noty({
          text: `Levels already unlocked for these students`,
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
    }
  }
}
