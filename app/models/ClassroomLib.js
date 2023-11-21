import { orderedCourseIDs } from 'app/core/utils'

/**
 * This file includes separate static methods that are assigned to
 * the Classroom model.
 */

const ClassroomLib = {
  // Lock a student to various granularity.
  setStudentLockLevel: (classroom, studentId, courseId, levelOriginal = undefined) => {
    if (!classroom.studentLockMap) {
      classroom.studentLockMap = {}
    }

    if (!courseId && !levelOriginal) {
      ClassroomLib.clearStudentLock(classroom, studentId)
    }

    classroom.studentLockMap[studentId] = {
      courseId,
      levelOriginal
    }
  },

  initializeLevelLockForStudent: (classroom, studentId, courseId) => {
    if (!classroom.studentLockMap) {
      classroom.studentLockMap = {}
    }

    if (!classroom.studentLockMap[studentId]) {
      classroom.studentLockMap[studentId] = {
        courseId,
        lockedLevels: {}
      }
    }

    if (!classroom.studentLockMap[studentId].lockedLevels) {
      classroom.studentLockMap[studentId].lockedLevels = {}
    }

    if (!classroom.studentLockMap[studentId].optionalLevels) {
      classroom.studentLockMap[studentId].optionalLevels = {}
    }
  },

  // modifier possible values: 'locked', 'optional'
  setModifierForStudent: ({ classroom, studentId, courseId, levels = [], date = null, modifier, value }) => {
    ClassroomLib.initializeLevelLockForStudent(classroom, studentId, courseId)
    levels.forEach(levelOriginal => {
      classroom.studentLockMap[studentId][`${modifier}Levels`][levelOriginal] = date || value
    })
  },

  // Returns true if student is on a locked course.
  // There may be a level within that course that sets a more granular lock.
  isStudentOnLockedCourse: (classroom, studentId, courseIdToCheck) => {
    const studentCourseLocked = classroom.studentLockMap?.[studentId]?.courseId
    if (!studentCourseLocked) {
      return false
    }
    const studentCourseIdx = orderedCourseIDs.indexOf(studentCourseLocked)
    const courseToCheckIdx = orderedCourseIDs.indexOf(courseIdToCheck)

    // If they are equal then we want to return locked so that we check
    // more granularly. I.e. check the module number of level original.
    return courseToCheckIdx >= studentCourseIdx
  },

  isModifierActiveForStudent: (classroomAttributes, studentId, courseIdToCheck, level, modifier, modifierExpiryDate = null) => {

    if (!level) {
      return false
    }

    const value = classroomAttributes?.studentLockMap?.[studentId]?.[`${modifier}Levels`]?.[level]

    if (typeof value === 'undefined' && modifier === 'locked') {
      // Legacy behavior.
      return ClassroomLib.isStudentOnLockedLevel(classroomAttributes, studentId, courseIdToCheck, level)
    }

    // If we have a modifier expiry date, then we check if the modifier will expire at the given date.
    if (modifierExpiryDate) {
      if (new Date(value).toString() === modifierExpiryDate.toString()) {
        return true
      }
      return false
    }

    if (!value) {
      // If we have not tracked a locked course, then assume unlocked.
      return false
    }

    if (value === true) {
      return true
    }

    if (new Date(value) > new Date()) {
      return true
    }
  },

  isStudentOnLockedLevel: (classroom, studentId, courseIdToCheck, levelOriginal) => {
    const studentCourseLocked = classroom?.studentLockMap?.[studentId]?.courseId
    if (!studentCourseLocked) {
      // If we have not tracked a locked course, then assume unlocked.
      return false
    }

    if (studentCourseLocked !== courseIdToCheck) {
      return ClassroomLib.isStudentOnLockedCourse(classroom, studentId, courseIdToCheck)
    }

    const studentOriginalLocked = classroom.studentLockMap?.[studentId]?.levelOriginal
    if (!studentOriginalLocked) {
      // In this case, there is no locked level set, so we judge locked status based only
      // on the course. We also know we are on that course.
      // Therefore this level is locked as it is in a locked course.
      return true
    }

    if (levelOriginal === studentOriginalLocked) {
      return true
    }

    // Get level order from the classroom.
    const classroomCachedCourse = classroom.courses.find(({ _id }) => _id === courseIdToCheck)
    const levelOriginals = classroomCachedCourse.levels.map(({ original }) => original)

    for (const original of levelOriginals) {
      // If we encounter our level, then the locked level must be later and this is unlocked
      if (original === levelOriginal) {
        return false
      }
      // If we encounter the locked level, then our level must be later and is locked
      if (original === studentOriginalLocked) {
        return true
      }
    }

    // There was an invalid level original. Don't set a lock.
    return false
  },

  getStudentLockDate: (classroom, studentId, level) => {
    const lockedValue = classroom.studentLockMap?.[studentId]?.lockedLevels?.[level]

    if (lockedValue && typeof lockedValue === 'string') {
      return new Date(lockedValue)
    }
    return null
  }
}

export default ClassroomLib
