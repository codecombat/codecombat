<script>
import { mapActions, mapGetters, mapMutations } from 'vuex'
import { COMPONENT_NAMES } from '../common/constants.js'
import Guidelines from './Guidelines'
import ViewAndMange from './ViewAndManage'
import TableClassFrame from './table/TableClassFrame'
import ModalEditStudent from '../modals/ModalEditStudent'
import storage from '../../../../../app/core/storage'

import utils from 'app/core/utils'
import { getGameContentDisplayNameWithType } from 'ozaria/site/common/ozariaUtils.js'
import User from 'models/User'
import { getLevelUrl, isOzariaNoCodeLevelHelper } from 'ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/curriculum-guide-helper'

import _ from 'lodash'
import ClassroomLib from '../../../../../app/models/ClassroomLib.js'

function getLearningGoalsDocumentation (content) {
  if (!content.documentation) {
    return ''
  }
  const { documentation } = content
  return utils.i18n((documentation?.specificArticles || []).find(({ name }) => name === 'Learning Goals'), 'body')
}

export default {
  name: COMPONENT_NAMES.MY_CLASSES_SINGLE,
  components: {
    Guidelines,
    'view-and-manage': ViewAndMange,
    'table-class-frame': TableClassFrame,
    ModalEditStudent,
  },

  beforeRouteUpdate (to, from, next) {
    this.closePanel()
    this.clearSelectedStudents()
    this.setClassroomId(to.params.classroomId)
    if (to.params.courseId) {
      this.setSelectedCourseId({ courseId: to.params.courseId })
    }
    next()
  },

  beforeRouteLeave (to, from, next) {
    this.closePanel()
    this.clearSelectedStudents()
    next()
  },

  props: {
    classroomId: {
      type: String,
      default: '',
      required: true,
    },
    teacherId: { // sent from DSA
      type: String,
      default: '',
    },
    displayOnly: { // sent from DSA
      type: Boolean,
      default: false,
    },
    defaultCourseId: {
      type: String,
      default: null,
    },
  },

  data: () => ({
    isGuidelinesVisible: true,
    refreshKey: 0,
    sortMethod: storage.load('sortMethod') || 'Last Name',
  }),

  computed: {
    ...mapGetters({
      classroom: 'teacherDashboard/getCurrentClassroom',
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      levelSessionsMapByUser: 'teacherDashboard/getLevelSessionsMapCurrentClassroom',
      aiProjectsMapByUser: 'teacherDashboard/getAiProjectsMapCurrentClassroom',
      getInteractiveSessionsForClass: 'interactives/getInteractiveSessionsForClass',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      gameContent: 'teacherDashboard/getGameContentCurrentClassroom',
      editingStudent: 'baseSingleClass/currentEditingStudent',
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      getCourseInstancesForClass: 'courseInstances/getCourseInstancesForClass',
      getClassroomById: 'classrooms/getClassroomById',
      getCourseInstancesOfClass: 'courseInstances/getCourseInstancesOfClass',
      getActiveClassrooms: 'teacherDashboard/getActiveClassrooms',
      selectableStudentIds: 'baseSingleClass/selectableStudentIds',
      getSelectableOriginals: 'baseSingleClass/getSelectableOriginals',
      classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
      aiScenarios: 'aiScenarios/getScenarios',
      modelsByName: 'aiModels/getModelsByName',
      getLevelNumber: 'gameContent/getLevelNumber',
    }),

    courseInstances () {
      return this.getCourseInstancesOfClass(this.classroom._id) || []
    },

    assignmentMap () {
      const assignmentMap = new Map()
      for (const { courseID, members } of this.courseInstances) {
        assignmentMap.set(courseID, new Set(members || []))
      }
      return assignmentMap
    },

    modules () {
      // Reference below required to trigger a re-render when the refresh button is clicked.
      this.refreshKey // eslint-disable-line no-unused-expressions

      const selectedCourseId = this.selectedCourseId
      const modules = (this.gameContent[selectedCourseId] || {}).modules
      if (modules === undefined) {
        return []
      }

      if (this.isHackStackCourse(selectedCourseId)) {
        const hackStackModules = this.generateHackStackModules(modules)
        return hackStackModules
      }

      const intros = (this.gameContent[selectedCourseId] || {}).introLevels

      const modulesForTable = []

      // Get the name and content list of a module.
      const isPlayableForStudent = {}
      const lastLockDateForStudent = {}
      for (const [moduleNum, moduleContent] of Object.entries(modules)) {
        // Because we are only reading the easiest way to propagate _most_
        // i18n is by transforming the content linearly here.
        const translatedModuleContent = moduleContent.map(content => {
          return {
            ...content,
            name: utils.i18n(content, 'name'),
            displayName: utils.i18n(content, 'displayName'),
            description: utils.i18n(content, 'description'),
          }
        })

        const course = this.classroomCourses.find(({ _id }) => _id === this.selectedCourseId)
        const module = course?.modules?.[moduleNum] || {}
        let moduleDisplayName = utils.i18n(module, 'name') || utils.i18n(course, 'name') || ''
        if (utils.isOzaria) {
          moduleDisplayName = this.$t(`teacher.module${moduleNum}`) + moduleDisplayName
        }

        const moduleStatsForTable = this.createModuleStatsTable({
          moduleDisplayName,
          intros,
          moduleNum,
          moduleContent: translatedModuleContent,
          access: module.access,
        })
        const levelNameMap = this.getLevelNameMap(translatedModuleContent, intros)
        const levelsByOriginal = translatedModuleContent
          .reduce((acc, content) => {
            acc[content.original] = content
            return acc
          }, {})

        // Track summary stats to display in the header of the table
        const classSummaryProgressMap = new Map(translatedModuleContent.map((content) => {
          return [content._id, { status: 'assigned', flagCount: 0 }]
        }))
        // Iterate over all the students and all the sessions for the student.
        for (const student of this.students) {
          isPlayableForStudent[student._id] = typeof isPlayableForStudent[student._id] === 'undefined' ? true : isPlayableForStudent[student._id]
          lastLockDateForStudent[student._id] = typeof lastLockDateForStudent[student._id] === 'undefined' ? null : lastLockDateForStudent[student._id]
          const studentSessions = this.levelSessionsMapByUser[student._id] || {}
          const levelOriginalCompletionMap = {}
          const playTimeMap = {}
          const completionDateMap = {}
          const playedOnMap = {}

          for (const session of Object.values(studentSessions)) {
            levelOriginalCompletionMap[session.level.original] = session.state
            playTimeMap[session.level.original] = session.playtime
            playedOnMap[session.level.original] = session.changed
            completionDateMap[session.level.original] = session.state.complete && session.dateFirstCompleted
          }

          moduleStatsForTable.studentSessions[student._id] = translatedModuleContent.map((content) => {
            const { original, fromIntroLevelOriginal, practiceLevels } = content
            const normalizedOriginal = original || fromIntroLevelOriginal

            const level = levelsByOriginal[normalizedOriginal]
            const selectedCourseInstance = this.courseInstances.find(({ courseID }) => courseID === this.selectedCourseId)
            const startLockedLevel = selectedCourseInstance?.startLockedLevel
            const lockedByOldDashboard = startLockedLevel && startLockedLevel === level?.slug

            const isLocked = lockedByOldDashboard || ClassroomLib.isModifierActiveForStudent(this.classroom, student._id, this.selectedCourseId, normalizedOriginal, 'locked')
            const lockDate = ClassroomLib.getStudentLockDate(this.classroom, student._id, normalizedOriginal)
            const isOptional = ClassroomLib.isModifierActiveForStudent(this.classroom, student._id, this.selectedCourseId, normalizedOriginal, 'optional')

            const isSkipped = isOptional && isLocked

            if (lockDate && lockDate > new Date()) {
              lastLockDateForStudent[student._id] = lockDate
              if (!isOptional) {
                isPlayableForStudent[student._id] = false
              }
            }

            if (isLocked && !isOptional) {
              isPlayableForStudent[student._id] = false
            }

            const isPractice = Boolean(content.practice)

            const defaultProgressDot = {
              status: 'assigned',
              normalizedType: content.type,
              isLocked,
              isSkipped,
              lockDate,
              lastLockDate: lastLockDateForStudent[student._id],
              original,
              normalizedOriginal,
              fromIntroLevelOriginal,
              isOptional,
              isPlayable: isPlayableForStudent[student._id],
              isPractice,
              playTime: playTimeMap[normalizedOriginal],
              playedOn: playedOnMap[normalizedOriginal],
              completionDate: completionDateMap[normalizedOriginal],
              tooltipName: levelNameMap[content._id].levelName,
              practiceLevels,
            }

            if (content.type === 'game-dev' || content.type === 'web-dev') {
              defaultProgressDot.normalizedType = 'capstone'
            } else if (content.type === undefined) {
              defaultProgressDot.normalizedType = 'practicelvl'
            } else if (content.type === 'course' || content.type === 'hero') {
              defaultProgressDot.normalizedType = 'practicelvl'
            }

            if (content.shareable === 'project') {
              defaultProgressDot.normalizedType = 'capstone'
            }

            if (!this.assignmentMap.get(selectedCourseId)?.has(student._id)) {
              // Return unassigned progress dot if the student isn't in the course-instance.
              defaultProgressDot.status = 'unassigned'
              return defaultProgressDot
            }

            // Return default progress dot if the student has not made progress.
            if (studentSessions === undefined) {
              return defaultProgressDot
            }

            if (normalizedOriginal) {
              if (!studentSessions[normalizedOriginal]) {
                return defaultProgressDot
              } else if (studentSessions[normalizedOriginal].state.complete === true) {
                defaultProgressDot.status = 'complete'
                classSummaryProgressMap.get(content._id).status = defaultProgressDot.status
              } else {
                defaultProgressDot.status = 'progress'
              }

              // Allows for incremental completion of an intro level.
              // We do not need to check if an interactive is in progress here.
              if (['interactive', 'cinematic', 'cutscene'].includes(defaultProgressDot.normalizedType)) {
                defaultProgressDot.status = 'assigned'

                if (levelOriginalCompletionMap[fromIntroLevelOriginal]?.introContentSessionComplete?.[content._id]?.complete) {
                  defaultProgressDot.status = 'complete'
                  classSummaryProgressMap.get(content._id).status = defaultProgressDot.status
                }

                // Preserve backwards compatability if there is no introContentSessionComplete property.
                if (
                  levelOriginalCompletionMap[fromIntroLevelOriginal]?.complete === true &&
                  defaultProgressDot.status !== 'complete' &&
                  (levelOriginalCompletionMap[fromIntroLevelOriginal]?.introContentSessionComplete?.[content._id]) === undefined
                ) {
                  defaultProgressDot.status = 'complete'
                }

                if (classSummaryProgressMap.get(content._id) !== 'complete' && defaultProgressDot.status !== 'assigned') {
                  classSummaryProgressMap.get(content._id).status = defaultProgressDot.status
                }
              }

              // Figure out if concept flag needs to be set on an interactive,
              // and whether an interactive is in progress.
              if (defaultProgressDot.normalizedType === 'interactive') {
                const interactiveSession = this.getInteractiveSessionsForClass(this.classroomId)?.[student._id]?.[content._id]
                if (interactiveSession !== undefined) {
                  const dateFirstCompleted = interactiveSession.dateFirstCompleted || undefined
                  let submissionsBeforeCompletion = []

                  // Makes sure to mark interactives for which we have sessions. We would have
                  // already marked for completion earlier. Here we are checking for progress.
                  if (defaultProgressDot.status === 'assigned') {
                    defaultProgressDot.status = 'progress'
                  }

                  if (dateFirstCompleted) {
                    submissionsBeforeCompletion = interactiveSession.submissions.filter((s) => new Date(s.submissionDate).getTime() <= new Date(dateFirstCompleted).getTime()) || []
                  } else {
                    submissionsBeforeCompletion = interactiveSession.submissions || []
                  }

                  if (submissionsBeforeCompletion.length >= 3) {
                    // Used by TableModuleGrid file to assign a border on the session.
                    defaultProgressDot.flag = 'concept'
                    classSummaryProgressMap.get(content._id).flagCount += 1
                  }
                }
              }

              // Level types that teacher can open TeacherDashboardPanel on.
              // We also need to make sure that teachers can only click if a session exists.
              if (['practicelvl', 'capstone', 'interactive', 'web-dev'].includes(defaultProgressDot.normalizedType) && defaultProgressDot.status !== 'assigned') {
                defaultProgressDot.clickHandler = () => {
                  this.showPanelSessionContent({
                    student,
                    classroomId: this.classroomId, // TODO remove and use classroomId from teacherDashboard vuex
                    selectedCourseId: this.selectedCourseId,
                    moduleNum,
                    contentId: content._id,
                  })
                }

                if (classSummaryProgressMap.get(content._id) !== 'complete' && defaultProgressDot.status !== 'assigned') {
                  classSummaryProgressMap.get(content._id).status = defaultProgressDot.status
                }

                defaultProgressDot.selectedKey = `${student._id}_${content._id}`
              }
            } else {
              console.error(`Invariant violated: Content has neither original nor _id: ${content}`)
            }
            return defaultProgressDot
          })
        }
        moduleStatsForTable.classSummaryProgress = Array.from(classSummaryProgressMap.values())
          .map(({ status, flagCount }) => ({
            status,
            border: flagCount >= (this.classroomMembers?.length || 1) / 2 ? 'red' : '',
          }))

        modulesForTable.push(moduleStatsForTable)
      }

      return modulesForTable
    },

    students () {
      if (!this.classroomMembers || this.classroomMembers.length === 0) {
        return []
      }

      const modules = (this.gameContent[this.selectedCourseId] || {}).modules
      if (!modules) {
        return []
      }

      const students = this.classroomMembers.map(userObj => {
        const isEnrolled = (new User(userObj)).isEnrolled()
        const displayName = User.broadName(userObj)
        return {
          displayName,
          _id: userObj._id,
          isEnrolled,
          firstName: userObj.firstName || displayName,
          lastName: userObj.lastName || displayName,
        }
      })

      // Sort based on table view options.
      // We count the number of completed sessions here before using the student list elsewhere.
      // The student array is a dependency for other functions, and needs to be ordered prior
      // to other calculations occuring.
      if (this.sortMethod === 'First Name' || this.sortMethod === 'Last Name') {
        const compareFunc = (s1, s2) => {
          if (this.sortMethod === 'First Name') {
            // compare by firstName, if they are same use lastName
            return s1.firstName.localeCompare(s2.firstName) || s1.lastName.localeCompare(s2.lastName)
          } else {
            return s1.lastName.localeCompare(s2.lastName) || s1.firstName.localeCompare(s2.firstName)
          }
        }
        students.sort(compareFunc)
        return students
      } else {
        const originalsInModule = Object.values(modules).flat().map(({
          fromIntroLevelOriginal,
          original,
        }) => fromIntroLevelOriginal || original)
        const studentProgression = new Map(students.map(({ _id }) => ([_id, 0])))

        for (const { _id } of students) {
          let completedCount = 0
          for (const original of originalsInModule) {
            if (this.levelSessionsMapByUser[_id]?.[original]?.state.complete === true) {
              completedCount++
            }
          }
          studentProgression.set(_id, completedCount)
        }

        students.sort((a, b) => {
          return studentProgression.get(b._id) - studentProgression.get(a._id)
        })
        if (this.sortMethod === 'Progress (Low to High)') {
          students.reverse()
        }

        return students
      }
    },
  },

  watch: {
    classroomId (newId) {
      this.setClassroomId(newId)
      this.fetchClassroomData(newId)
    },
    students (newStudents) {
      this.setSelectableStudentIds((newStudents || []).map(s => s._id))
    },
    modules (newModules) {
      const originals = newModules.reduce((acc, module) => {
        return acc.concat(module.contentList.map(c => c.normalizedOriginal))
      }, [])
      this.setSelectableOriginals(originals)
    },
  },

  mounted () {
    this.setClassroomId(this.classroomId)
    if (this.defaultCourseId) {
      this.setSelectedCourseId({ courseId: this.defaultCourseId })
    }
    this.setTeacherId(this.teacherId || me.get('_id'))
    this.fetchClassroomData(this.classroomId).catch(console.error)
  },

  destroyed () {
    this.resetLoadingState()
  },

  methods: {
    ...mapActions({
      fetchData: 'baseSingleClass/fetchData',
      setPanelSessionContent: 'teacherDashboardPanel/setPanelSessionContent',
      showPanelSessionContent: 'teacherDashboardPanel/showPanelSessionContent',
      showPanelProjectContent: 'teacherDashboardPanel/showPanelProjectContent',
      clearSelectedStudents: 'baseSingleClass/clearSelectedStudents',
      addStudentSelectedId: 'baseSingleClass/addStudentSelectedId',
      fetchClassroomById: 'classrooms/fetchClassroomForId',
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher',
      generateLevelNumberMap: 'gameContent/generateLevelNumberMap',
    }),

    ...mapMutations({
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setClassroomId: 'teacherDashboard/setClassroomId',
      setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom',
      setSelectableStudentIds: 'baseSingleClass/setSelectableStudentIds',
      setSelectableOriginals: 'baseSingleClass/setSelectableOriginals',
      closePanel: 'teacherDashboardPanel/closePanel',
    }),

    isHackStackCourse (selectedCourseId) {
      return selectedCourseId === utils.courseIDs.HACKSTACK
    },

    async fetchClassroomData (classroomId) {
      if (!this.getClassroomById(classroomId)) {
        await this.fetchClassroomById(classroomId)
      }
      await this.fetchData({ loadedEventName: 'Track Progress: Loaded' })
      const course = this.classroomCourses.find(({ _id }) => _id === this.selectedCourseId)
      await this.generateLevelNumberMap({
        campaignId: course.campaignID,
        language: this.classroom.aceConfig.language,
      })
    },

    async onRefresh () {
      await this.fetchClassroomData(this.classroomId)
      this.refreshKey += 1
    },

    onChangeStudentSort (sortMethod) {
      storage.save('sortMethod', sortMethod)
      this.sortMethod = sortMethod
    },

    clickGuidelineArrow: _.throttle(function () {
      this.isGuidelinesVisible = !this.isGuidelinesVisible
    }, 300),

    toggleAllStudents (event) {
      if (event.target.checked) {
        for (const { _id } of this.students) {
          this.addStudentSelectedId({ studentId: _id })
        }
      } else {
        this.clearSelectedStudents()
      }
    },

    getLevelNameMap (moduleContent, intros) {
      return moduleContent.reduce((acc, content) => {
        const { _id, original, fromIntroLevelOriginal, type } = content
        let levelKey = original
        if (isOzariaNoCodeLevelHelper(type)) {
          levelKey = _id
        }

        let description = getLearningGoalsDocumentation(content)

        let tooltipName
        let levelName
        const levelNumber = this.getLevelNumber(levelKey) || ''
        if (utils.isCodeCombat) {
          tooltipName = `${levelNumber}: ${utils.i18n(content, 'displayName') || utils.i18n(content, 'name')}`
          levelName = tooltipName
        } else {
          tooltipName = `${levelNumber}: ${getGameContentDisplayNameWithType(content)}`
          levelName = tooltipName
        }
        if (fromIntroLevelOriginal) {
          const introLevel = intros[fromIntroLevelOriginal] || {}
          const levelUrl = getLevelUrl({
            ...content,
            codeLanguage: this.classroom.aceConfig.language,
            courseId: this.selectedCourseId,
          })
          levelName = tooltipName
          description = `<h3><a target="_blank" href="${levelUrl}">${tooltipName}</a></h3><p>${utils.i18n(content, 'description') || getLearningGoalsDocumentation(content) || ''}</p>`
          tooltipName = `${Vue.t('teacher_dashboard.intro')}: ${utils.i18n(introLevel, 'displayName') || utils.i18n(introLevel, 'name')}`
        }

        acc[_id] = { tooltipName, description, levelName }

        return acc
      }, {})
    },

    setProgressDetails (details, classSummaryProgress, index) {
      details.status = 'progress'
      classSummaryProgress[index].status = 'progress'
    },

    setUnsafeFlag (details, aiProjects) {
      if (!Array.isArray(aiProjects)) {
        return
      }
      if (aiProjects.some(project => project.unsafeChatMessages?.length > 0)) {
        details.flag = 'unsafe'
      }
    },

    setClickHandler (details, student, moduleNum, aiScenario, aiProjects) {
      details.clickHandler = () => {
        this.showPanelProjectContent({
          header: 'HackStack Project',
          student,
          classroomId: this.classroomId,
          selectedCourseId: this.selectedCourseId,
          moduleNum,
          aiScenario,
          aiProjects,
        })
      }
    },

    checkIfComplete (aiScenario, aiProjects) {
      if (aiScenario.mode === 'learn to use' && aiProjects.some(project => (project.actionQueue.length === 0))) {
        return true
      } else if (aiScenario.mode === 'use' && aiProjects.some(project => (project.isReadyToReview))) {
        return true
      }
      return false
    },

    createProgressDetailsByAiScenario ({ aiScenario, index, student, classSummaryProgress, moduleNum }) {
      const details = {}
      classSummaryProgress[index] = classSummaryProgress[index] || { status: 'assigned', border: '' }
      const aiProjects = this.aiProjectsMapByUser[student._id]?.[aiScenario._id]

      if (aiProjects) {
        this.setProgressDetails(details, classSummaryProgress, index)
        this.setClickHandler(details, student, moduleNum, aiScenario, aiProjects)
        const completed = this.checkIfComplete(aiScenario, aiProjects)
        this.setUnsafeFlag(details, aiProjects)

        if (completed) {
          details.status = 'complete'
        }
      }

      const isLocked = ClassroomLib.isModifierActiveForStudent(this.classroom, student._id, this.selectedCourseId, aiScenario._id, 'lockedScenario')
      const isPlayable = !isLocked

      if (!this.assignmentMap.get(this.selectedCourseId)?.has(student._id)) {
        details.status = 'unassigned'
        return details
      }

      return {
        status: 'assigned',
        normalizedType: 'challengelvl',
        isLocked,
        isSkipped: false,
        lockDate: null,
        lastLockDate: null,
        original: aiScenario._id,
        normalizedOriginal: aiScenario._id,
        isOptional: false,
        isPlayable,
        isPractice: false,
        ...details,
      }
    },

    // Creates summary stats table for the content. These are the icons along
    // the top of the track progress table.
    createModuleStatsTable ({ moduleDisplayName, moduleContent, intros, moduleNum, access }) {
      const levelNameMap = this.getLevelNameMap(moduleContent, intros)
      return {
        moduleNum,
        access,
        displayName: moduleDisplayName,
        contentList: moduleContent.map((content, index) => {
          const { type, _id, ozariaType, original, fromIntroLevelOriginal, slug, practiceLevels } = content
          const normalizedOriginal = original || fromIntroLevelOriginal
          let normalizedType = type
          if (ozariaType) {
            if (ozariaType === 'challenge') {
              normalizedType = 'challengelvl'
            } else if (ozariaType === 'practice') {
              normalizedType = 'practicelvl'
            } else if (ozariaType === 'capstone') {
              normalizedType = 'capstone'
            }
          } else {
            normalizedType = type
          }

          if (!normalizedType) { // TODO: show all levels as Challenge Levels for now
            normalizedType = 'challengelvl'
          }

          if (utils.isCodeCombat) {
            if (content.shareable === 'project') {
              normalizedType = 'capstone'
            }
          }

          if (!['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl', 'intro', 'hero', 'course-ladder', 'game-dev', 'web-dev', 'ladder'].includes(normalizedType)) {
            throw new Error(`Didn't handle normalized content type: '${normalizedType}'`)
          }

          let contentLevelSlug = slug
          if (fromIntroLevelOriginal) {
            contentLevelSlug = intros[fromIntroLevelOriginal]?.slug
          }

          const isPractice = Boolean(content.practice)

          if (utils.isCodeCombat) {
            normalizedType = isPractice ? 'practicelvl' : normalizedType
          }

          return ({
            displayName: utils.i18n(content, 'displayName') || utils.i18n(content, 'name'),
            type: normalizedType,
            _id,
            contentKey: original || fromIntroLevelOriginal, // Currently use the original as the key that groups levels together.
            normalizedOriginal,
            normalizedType,
            contentLevelSlug,
            isPractice,
            practiceLevels,
            slug: content.slug,
            ozariaType: content.ozariaType,
            introLevelSlug: content.introLevelSlug,
            ...levelNameMap[_id],
          })
        }),
        studentSessions: {},
        classSummaryProgress: [],
      }
    },

    generateHackStackModules (modules) {
      const course = this.classroomCourses.find(({ _id }) => _id === this.selectedCourseId)
      return Object.entries(modules).map(([moduleNum, moduleContent]) => {
        const classSummaryProgress = []
        const module = course?.modules?.[moduleNum] || {}
        return {
          moduleNum,
          displayName: utils.i18n(module, 'name').replace('(coming soon)', ''),
          contentList: moduleContent.map((scenario, index) => {
            const type = utils.scenarioMode2Icon(scenario.mode)
            return {
              displayName: scenario.name,
              type,
              _id: scenario._id,
              tooltipName: scenario.name,
              description: '',
              contentKey: scenario._id,
              normalizedOriginal: scenario._id,
              normalizedType: type,
              contentLevelSlug: scenario.slug,
              isPractice: false,
            }
          }),
          studentSessions: this.students.reduce((studentSessions, student) => {
            studentSessions[student._id] = moduleContent.map((aiScenario, index) => {
              return this.createProgressDetailsByAiScenario({
                aiScenario,
                index,
                student,
                classSummaryProgress,
                moduleNum,
              })
            })
            return studentSessions
          }, {}),
          classSummaryProgress,
        }
      })
    },
  },
}
</script>

<template>
  <div>
    <guidelines
      :visible="isGuidelinesVisible"
      @click-arrow="clickGuidelineArrow"
    />
    <view-and-manage
      :arrow-visible="!isGuidelinesVisible"
      :display-only="displayOnly"

      @change-sort-by="onChangeStudentSort"
      @click-arrow="clickGuidelineArrow"
      @assignContent="$emit('assignContent')"
      @addStudents="$emit('addStudents')"
      @removeStudents="$emit('removeStudents')"
      @refresh="onRefresh"
    />

    <table-class-frame
      v-if="modules && students"
      :students="students"
      :modules="modules"
      :display-only="displayOnly"

      @toggle-all-students="toggleAllStudents"
    />
    <modal-edit-student
      v-if="editingStudent"
      :display-only="displayOnly"
    />
  </div>
</template>
