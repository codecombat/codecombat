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
    selectableStudentIds: [],
    // This is either the student id being editted, or null.
    editingStudent: null,
    // Used to group together hover feedback for intro levels.
    showingTooltipOfThisOriginal: null,

    selectableOriginals: [],
    selectedOriginals: []
  },

  getters: {
    isStudentSelected: (state) => (studentId) => {
      return state.selectedStudents[studentId] || false
    },

    selectedStudentIds (state) {
      return Object.keys(state.selectedStudents || [])
    },

    selectableStudentIds (state) {
      return state.selectableStudentIds
    },

    selectableOriginals (state) {
      return state.selectableOriginals
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

    setSelectableStudentIds (state, studentIds) {
      state.selectableStudentIds = studentIds
    },

    setSelectableOriginals (state, listOfOriginals) {
      state.selectableOriginals = listOfOriginals
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
          noty({ text: 'You do not have a write permission on this class', layout: 'center', type: 'information', killer: true, timeout: 5000 })
          return
        }
      }

      if (students.length === 0) {
        noty({ text: 'You need to select student(s) first before performing that action.', layout: 'center', type: 'information', killer: true, timeout: 8000 })
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
        noty({ text: 'You need to select student(s) first before performing that action.', layout: 'center', type: 'information', killer: true, timeout: 8000 })
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
          noty({ text: 'You do not have a write permission on this class', layout: 'center', type: 'information', killer: true, timeout: 5000 })
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
      modifierValue = true, // true, false or Date
      levels = [],
      date
    }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      if (students.length === 0) {
        noty({ text: 'You need to select student(s) first before performing that action.', layout: 'center', type: 'information', killer: true, timeout: 8000 })
        window.tracker?.trackEvent('Failure to lock', { category: 'Teachers' })
        return
      }

      if (!currentCourseId) {
        throw new Error('You cannot lock an undefined course.')
      }

      // Cloning the classroom so we aren't mutating a vue store object.
      const clonedClass = JSON.parse(JSON.stringify(classroom))

      let numberStudentsChanged = 0
      const skippedModifications = []

      await dispatch('levels/fetchForClassroom', clonedClass._id, { root: true })
      const courseInstances = rootGetters['courseInstances/getCourseInstancesOfClass'](clonedClass._id)
      const selectedCourseId = rootGetters['teacherDashboard/getSelectedCourseIdCurrentClassroom']
      const courseInstance = courseInstances.find(ci => ci.courseID === selectedCourseId)
      const levelRecords = rootGetters['levels/getLevelsForClassroom'](clonedClass._id)
      const levelRecordsById = levelRecords.reduce((acc, level) => {
        acc[level.original] = level
        return acc
      }, {})

      const courseInstancesToClearLegacyLocks = []

      for (const modifier of modifiers) {
        for (const { _id } of students) {
          // let's filter out the levels that are already has the same modifier
          const levelsToHandle = levels.filter((level) => {
            if (modifier === 'locked' && modifierValue === false) {
              const levelRecord = levelRecordsById[level]
              if (courseInstance.startLockedLevel === levelRecord.slug) {
                courseInstancesToClearLegacyLocks.push(courseInstance)
              }
            }

            const isModifierActive = ClassroomLib.isModifierActiveForStudent(clonedClass, _id, currentCourseId, level, modifier, date)
            const shouldBeHandled = modifierValue ? !isModifierActive : isModifierActive
            if (!shouldBeHandled) {
              skippedModifications.push({ studentId: _id, level, modifier, modifierValue })
            }
            return shouldBeHandled
          })

          if (
            levelsToHandle.length > 0 ||
            ((!levels || levels.length === 0) && !ClassroomLib.isStudentOnLockedCourse(clonedClass, _id, currentCourseId))
          ) {
            numberStudentsChanged += 1
            ClassroomLib.setModifierForStudent({ classroom: clonedClass, studentId: _id, courseId: currentCourseId, levels: levelsToHandle, date, modifier, value: modifierValue })
          }
        }
      }

      if (numberStudentsChanged === 0 && courseInstancesToClearLegacyLocks.length === 0) {
        const skippedUnlocks = skippedModifications.filter(({ modifierValue, modifier }) => modifierValue === false && modifier === 'locked')
        noty({
          text: skippedUnlocks.length > 0 ? $.i18n.t('teacher_dashboard.no_modifiers_changed_unlocks_skipped') : $.i18n.t('teacher_dashboard.no_modifiers_changed'),
          layout: 'center',
          type: 'information',
          killer: true,
          timeout: 5000
        })
        return
      }

      if (courseInstancesToClearLegacyLocks.length > 0) {
        await Promise.all(courseInstancesToClearLegacyLocks.map((courseInstance) => {
          return dispatch('courseInstances/updateCourseInstance', {
            courseInstance,
            updates: {
              startLockedLevel: 'none'
            }
          }, { root: true })
        }))
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

    resetProgress ({ rootGetters, dispatch, getters }) {
      const students = getters.selectedStudentIds.map(id => rootGetters['teacherDashboard/getMembersCurrentClassroom'].find(({ _id }) => id === _id))
      const currentClassroom = rootGetters['teacherDashboard/getCurrentClassroom']
      const courseInstances = rootGetters['courseInstances/getCourseInstancesOfClass'](currentClassroom._id)
      const selectedCourseId = rootGetters['teacherDashboard/getSelectedCourseIdCurrentClassroom']
      const courseInstance = courseInstances.find(ci => ci.courseID === selectedCourseId)
      const courses = rootGetters['courses/sorted']
      const selectedCourse = courses.find(c => c._id === selectedCourseId)
      if (!selectedCourse || students.length === 0 || !courseInstance) {
        return noty({
          text: 'No progress to delete',
          type: 'error',
          timeout: 2000,
          layout: 'center'
        })
      }
      if (window.confirm(`Do you want to reset progress of ${students.length} users in ${selectedCourse.name}? Warning: student progress for this chapter will be deleted and cannot be recovered. Are you sure?`)) {
        noty({
          text: 'Deleting progress',
          timeout: 200,
          type: 'information',
          layout: 'center'
        })
        dispatch('levelSessions/resetProgressOfUsers', { users: students, courseInstanceId: courseInstance._id, currentClassroom }, { root: true })
      }
    }
  }
}
