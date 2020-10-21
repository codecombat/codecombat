/**
 * Can be tested individually on a local dev environment by navigating
 * to the route: /test/app/views/teachers/BaseSingleClass.spec.js
 * Missing tests for the following items due to time constraints:
 *  - Concept check flag (inidividual student or class overview section)
 *  - Intro level progress breakdown
 *  - Intro level backward compatibility
 */
import BaseSingleClass from '../../../../ozaria/site/components/teacher-dashboard/BaseSingleClass/index.vue'

const MOCK_COURSE_ID = 'MOCK_ID'
const OWNER_ID = 'OWNER_ID'

const PRACTICE_ORIGINAL = 'PRACTICE_ORIGINAL'
const MOCK_STUDENT1_ID = 'MOCK_STUDENT1_ID'
const MOCK_STUDENT2_ID = 'MOCK_STUDENT2_ID'

const createPracticeLevel = () => ({
  contentMock: {
    ozariaType: 'practice',
    displayName: 'Practice Level Mock Name',
    _id: 'practiceID',
    original: PRACTICE_ORIGINAL
  },
  completionMock: (complete = false) => (
    {
      level: {
        original: PRACTICE_ORIGINAL
      },
      state: {
        complete: complete
      }
    }
  )
})

const singleStudentMockData = (overrides) => {
  const { members, students, complete, levelSessionsMapByUser } = overrides || {}
  return {
    createModuleStatsTable: BaseSingleClass.methods.createModuleStatsTable,
    selectedCourseId: MOCK_COURSE_ID,
    classroom: {
      ownerID: OWNER_ID,
      _id: 'mockID'
    },
    '$t': () => 'TranslatedMock',
    getCourseInstancesForClass: () => {
      return [
        {
          courseID: MOCK_COURSE_ID,
          members: members || [
            // This is whether or not the student is assigned.
            MOCK_STUDENT1_ID
          ]
        }
      ]
    },
    gameContent: {
      [MOCK_COURSE_ID]: {
        modules: {
          '1': [
            createPracticeLevel().contentMock
          ]
        }
      }
    },
    students: students || [
      {
        displayName: 'MockStudent T',
        isEnrolled: true,
        _id: MOCK_STUDENT1_ID
      }
    ],
    levelSessionsMapByUser: levelSessionsMapByUser || {
      [MOCK_STUDENT1_ID]: {
        [PRACTICE_ORIGINAL]: createPracticeLevel().completionMock(complete || false)
      }
    }
  }
}

const twoStudentsMockData = (overrides) => {
  const { members, levelSessionsMapByUser, mock1complete, mock2complete } = overrides || {}
  return singleStudentMockData({
    members: members || [MOCK_STUDENT1_ID, MOCK_STUDENT2_ID],
    students: [
      {
        displayName: 'MockStudent1 T',
        isEnrolled: true,
        _id: MOCK_STUDENT1_ID
      },
      {
        displayName: 'MockStudent2 T',
        isEnrolled: true,
        _id: MOCK_STUDENT2_ID
      }
    ],
    levelSessionsMapByUser: levelSessionsMapByUser || {
      [MOCK_STUDENT1_ID]: {
        [PRACTICE_ORIGINAL]: createPracticeLevel().completionMock(mock1complete || false)
      },
      [MOCK_STUDENT2_ID]: {
        [PRACTICE_ORIGINAL]: createPracticeLevel().completionMock(mock2complete || false)
      }
    }
  })
}

describe('BaseSingleClass', () => {
  it('empty module returns empty array default', () => {
    // Here we fill in the `this` object in the method.
    const mockedCourse = 'mockCourse'
    const localThis = {
      selectedCourseId: mockedCourse,
      classroom: {
        ownerID: 'mockOwnerID',
        _id: 'mockID'
      },
      getCourseInstancesForClass: () => {
        return [
          { courseID: 'mockCourseID', members: [] }
        ]
      },
      gameContent: {
        [mockedCourse]: {
          modules: [] // Empty course returns nothing
        }
      }
    }
    expect(BaseSingleClass.computed.modules.call(localThis)).toEqual([])
  })

  describe('student assignment', () => {
    it('will fill in assigned dots', () => {
      const localThis = singleStudentMockData({ levelSessionsMapByUser: {} })
      // Here we fill in the `this` object in the method.
      expect(BaseSingleClass.computed.modules.call(localThis)).toEqual([{
        moduleNum: '1',
        displayName: 'TranslatedMockundefined',
        contentList: [ jasmine.objectContaining({ displayName: 'Practice Level Mock Name', type: 'practicelvl', _id: 'practiceID', normalizedOriginal: 'PRACTICE_ORIGINAL', tooltipName: 'Practice Level: Practice Level Mock Name', description: '', contentKey: 'PRACTICE_ORIGINAL' })],
        studentSessions: { MOCK_STUDENT1_ID: [ { status: 'assigned', normalizedType: 'practicelvl', isLocked: false } ] },
        classSummaryProgress: [{ status: 'assigned', border: '' }]
      }])
    })

    it('will fill in unassigned dots if student is not in course instance', () => {
      const localThis = singleStudentMockData({ members: [] })
      // Here we fill in the `this` object in the method.
      expect(BaseSingleClass.computed.modules.call(localThis)).toEqual([
        {
          moduleNum: '1',
          // This is due to patching in $t for the test.
          displayName: 'TranslatedMockundefined',
          contentList: [
            jasmine.objectContaining({ displayName: 'Practice Level Mock Name', type: 'practicelvl', _id: 'practiceID', description: '' })
          ],
          studentSessions: {
            MOCK_STUDENT1_ID: [
              { status: 'unassigned', normalizedType: 'practicelvl', isLocked: false }
            ]
          },
          classSummaryProgress: [ { status: 'assigned', border: '' } ]
        }
      ])
    })
  })

  xit('handle empty classroom', () => {
    const localThis = singleStudentMockData({ members: [], students: [] })

    expect(BaseSingleClass.computed.modules.call(localThis)).toEqual([
      {
        displayName: 'TranslatedMockundefined',
        contentList: [ jasmine.objectContaining({
          displayName: 'Practice Level Mock Name', type: 'practicelvl', _id: 'practiceID', description: ''
        }) ],
        studentSessions: { },
        // TODO: This is interesting and should maybe be blank
        classSummaryProgress: [ { status: 'assigned', border: '', isLocked: false } ]
      }
    ])
  })

  xdescribe('practice level summary dot - single student', () => {
    it('summary and student match completed', () => {
      const localThis = singleStudentMockData({ complete: true })

      expect(BaseSingleClass.computed.modules.call(localThis)).toEqual([
        {
          // Due to mocked translation missing
          displayName: 'TranslatedMockundefined',
          contentList: [
            { displayName: 'Practice Level Mock Name', type: 'practicelvl', _id: 'practiceID', description: '' }
          ],
          studentSessions: {
            MOCK_STUDENT1_ID: [
              // There is a function on this object that doesn't compare.
              jasmine.objectContaining({ status: 'complete', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT1_ID_practiceID' })
            ]
          },
          classSummaryProgress: [ { status: 'complete', border: '' } ]
        }
      ])
    })
    it('summary and student match in progress', () => {
      const localThis = singleStudentMockData({ complete: false })

      expect(BaseSingleClass.computed.modules.call(localThis)).toEqual([
        {
          // Due to mocked translation missing
          displayName: 'TranslatedMockundefined',
          contentList: [
            { displayName: 'Practice Level Mock Name', type: 'practicelvl', _id: 'practiceID', description: '' }
          ],
          studentSessions: {
            [MOCK_STUDENT1_ID]: [
              // There is a function on this object that doesn't compare.
              jasmine.objectContaining({ status: 'progress', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT1_ID_practiceID' })
            ]
          },
          classSummaryProgress: [ { status: 'progress', border: '' } ]
        }
      ])
    })
  })

  describe('practice level summary dot - two students', () => {
    it('two students with level sessions show up as in progress', () => {
      const localThis = twoStudentsMockData()
      expect(BaseSingleClass.computed.modules.call(localThis)[0]).toEqual(jasmine.objectContaining(
        {
          studentSessions: {
            [MOCK_STUDENT1_ID]: [
              jasmine.objectContaining({ status: 'progress', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT1_ID_practiceID' })
            ],
            [MOCK_STUDENT2_ID]: [
              jasmine.objectContaining({ status: 'progress', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT2_ID_practiceID' })
            ]
          },
          classSummaryProgress: [ { status: 'progress', border: '' } ]
        }
      ))
    })

    xit('having one student unassigned is handled', () => {
      const localThis = twoStudentsMockData({
        members: [MOCK_STUDENT2_ID]
      })
      expect(BaseSingleClass.computed.modules.call(localThis)[0]).toEqual(jasmine.objectContaining(
        {
          studentSessions: {
            [MOCK_STUDENT1_ID]: [
              { status: 'unassigned', normalizedType: 'practicelvl' }
            ],
            [MOCK_STUDENT2_ID]: [
              jasmine.objectContaining({ status: 'progress', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT2_ID_practiceID' })
            ]
          },
          classSummaryProgress: [ { status: 'progress', border: '' } ]
        }
      ))
    })

    it('one student is completed and the other is in progress', () => {
      const localThis = twoStudentsMockData({
        mock1complete: false,
        mock2complete: true
      })
      expect(BaseSingleClass.computed.modules.call(localThis)[0]).toEqual(jasmine.objectContaining(
        {
          studentSessions: {
            [MOCK_STUDENT1_ID]: [
              jasmine.objectContaining({ status: 'progress', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT1_ID_practiceID' })
            ],
            [MOCK_STUDENT2_ID]: [
              jasmine.objectContaining({ status: 'complete', normalizedType: 'practicelvl', selectedKey: 'MOCK_STUDENT2_ID_practiceID' })
            ]
          },
          classSummaryProgress: [ { status: 'complete', border: '' } ]
        }
      ))
    })
  })
})
