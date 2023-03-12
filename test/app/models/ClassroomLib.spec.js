import ClassroomLib from '../../../app/models/ClassroomLib'
import { courseIDs, isOzaria } from 'app/core/utils'

describe('isStudentOnLockedCourse', () => {
  it('no lock is always false', () => {
    if (!isOzaria) {
      expect(true).toBeTruthy()
      return  // This is specific to the Ozaria level locking
    }

    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedCourse({
        studentLockMap: undefined
      },
      'StudentIdExample',
      courseId)).toEqual(false)
    }
  })

  it('student has lock on that course is always locked', () => {
    if (!isOzaria) {
      expect(true).toBeTruthy()
      return  // This is specific to the Ozaria level locking
    }

    const studentId = 'StudentIdExample'
    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedCourse({
        studentLockMap: {
          [studentId]: {
            courseId
          }
        }
      },
      'StudentIdExample',
      courseId)).toEqual(true)
    }
  })

  it('course locked before returns locked', () => {
    if (!isOzaria) {
      expect(true).toBeTruthy()
      return  // This is specific to the Ozaria level locking
    }

    const studentId = 'StudentIdExample'
    expect(ClassroomLib.isStudentOnLockedCourse({
      studentLockMap: {
        [studentId]: {
          courseId: courseIDs.CHAPTER_TWO
        }
      }
    },
    'StudentIdExample',
    courseIDs.CHAPTER_THREE)).toEqual(true)
  })

  it('later locked course return unlocked', () => {
    if (!isOzaria) {
      expect(true).toBeTruthy()
      return  // This is specific to the Ozaria level locking
    }

    const studentId = 'StudentIdExample'
    expect(ClassroomLib.isStudentOnLockedCourse({
      studentLockMap: {
        [studentId]: {
          courseId: courseIDs.CHAPTER_TWO
        }
      }
    },
    'StudentIdExample',
    courseIDs.CHAPTER_ONE)).toEqual(false)
  })
})

describe('isStudentOnLockedLevel', () => {
  it('no lock is always false', () => {
    if (!isOzaria) return
    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: undefined
      },
      'StudentIdExample',
      courseId,
      'levelOriginal')).toEqual(false)
    }
  })

  it('same course and same level original', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId,
            levelOriginal: levelOriginal
          }
        },
        courses: [{
          _id: courseId,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseId, levelOriginal)).toEqual(true)
    }
  })

  it('same course and after locked level', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId,
            levelOriginal: levelOriginal
          }
        },
        courses: [{
          _id: courseId,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseId, 'original3')).toEqual(true)
    }
  })

  it('same course and before locked level', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId,
            levelOriginal: levelOriginal
          }
        },
        courses: [{
          _id: courseId,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseId, 'original1')).toEqual(false)
    }
  })

  it('same course and corrupt missing level original', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId,
            levelOriginal: 'CORRUPT LEVEL ORIGINAL LOCKED'
          }
        },
        courses: [{
          _id: courseId,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseId, levelOriginal)).toEqual(false)
    }
  })

  it('same course with only course lock is locked', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const courseId of Object.values(courseIDs)) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId
          }
        },
        courses: [{
          _id: courseId,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseId, levelOriginal)).toEqual(true)
    }

    for (const original of ['original1', 'original2', 'original3']) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId: courseIDs.CHAPTER_ONE
          }
        },
        courses: [{
          _id: courseIDs.CHAPTER_ONE,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseIDs.CHAPTER_ONE, original)).toEqual(true)
    }
  })

  it('level is always unlocked if lock is in an earlier course', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const original of ['original1', 'original2', 'original3']) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId: courseIDs.CHAPTER_TWO,
            levelOriginal: levelOriginal
          }
        },
        courses: [{
          _id: courseIDs.CHAPTER_THREE,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseIDs.CHAPTER_ONE, original)).toEqual(false)
    }
  })

  it('level is always locked if lock is in an earlier course', () => {
    if (!isOzaria) return
    const studentId = 'StudentIdExample'
    const levelOriginal = 'original2'

    for (const original of ['original1', 'original2', 'original3']) {
      expect(ClassroomLib.isStudentOnLockedLevel({
        studentLockMap: {
          [studentId]: {
            courseId: courseIDs.CHAPTER_TWO,
            levelOriginal: levelOriginal
          }
        },
        courses: [{
          _id: courseIDs.CHAPTER_THREE,
          levels: [
            { original: 'original1' },
            { original: levelOriginal },
            { original: 'original3' }
          ]
        }]
      },
      studentId,
      courseIDs.CHAPTER_THREE, original)).toEqual(true)
    }
  })
})
