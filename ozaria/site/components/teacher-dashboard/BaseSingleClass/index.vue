<script>
import { mapActions, mapGetters, mapMutations } from 'vuex'
import { COMPONENT_NAMES } from '../common/constants.js'
import Guidelines from './Guidelines'
import ViewAndMange from './ViewAndManage'
import TableClassFrame from './table/TableClassFrame'
import ModalEditStudent from '../modals/ModalEditStudent'
import Classroom from 'models/Classroom'
import storage from '../../../../../app/core/storage'

import utils from 'app/core/utils'
import { getGameContentDisplayNameWithType } from 'ozaria/site/common/ozariaUtils.js'
import User from 'models/User'

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
    ModalEditStudent
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
      required: true
    },
    teacherId: { // sent from DSA
      type: String,
      default: ''
    },
    displayOnly: { // sent from DSA
      type: Boolean,
      default: false
    },
    defaultCourseId: {
      type: String,
      default: null
    }
  },

  data: () => ({
    isGuidelinesVisible: true,
    refreshKey: 0,
    sortMethod: storage.load('sortMethod') || 'Last Name'
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

      if (this.isHackStackCourse(selectedCourseId)) {
        const hackStackModuleNames = this.aiScenarios.reduce((acc, scenario) => {
          acc.add(scenario.tool)
          return acc
        }, new Set())

        const hackStackModules = [...hackStackModuleNames].map(this.generateHackStackModule.bind(this)).filter(Boolean)

        return hackStackModules
      }

      const modules = (this.gameContent[selectedCourseId] || {}).modules
      if (modules === undefined) {
        return []
      }

      const intros = (this.gameContent[selectedCourseId] || {}).introLevels

      const modulesForTable = []

      // Get the name and content list of a module.
      for (const [moduleNum, moduleContent] of Object.entries(modules)) {
        // Because we are only reading the easiest way to propagate _most_
        // i18n is by transforming the content linearly here.
        const translatedModuleContent = moduleContent.map(content => {
          return {
            ...content,
            name: utils.i18n(content, 'name'),
            displayName: utils.i18n(content, 'displayName'),
            description: utils.i18n(content, 'description')
          }
        })

        let moduleDisplayName
        if (!utils.courseModules[this.selectedCourseId]?.[moduleNum]) {
          const course = this.classroomCourses.find(({ _id }) => _id === this.selectedCourseId)
          moduleDisplayName = utils.i18n(course, 'name')
        } else {
          // Todo: Ozaria-i18n
          moduleDisplayName = `${utils.isOzaria ? this.$t(`teacher.module${moduleNum}`) : ''}${utils.courseModules[this.selectedCourseId]?.[moduleNum]}`
        }

        const moduleStatsForTable = this.createModuleStatsTable(moduleDisplayName, translatedModuleContent, intros, moduleNum)
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
          const studentSessions = this.levelSessionsMapByUser[student._id] || {}
          const levelOriginalCompletionMap = {}
          const playTimeMap = {}
          const completionDateMap = {}

          for (const session of Object.values(studentSessions)) {
            levelOriginalCompletionMap[session.level.original] = session.state
            playTimeMap[session.level.original] = session.playtime
            completionDateMap[session.level.original] = session.state.complete && session.changed
          }

          let isPlayable = true
          let lastLockDate = null
          moduleStatsForTable.studentSessions[student._id] = translatedModuleContent.map((content) => {
            const { original, fromIntroLevelOriginal } = content
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
              lastLockDate = lockDate
              if (!isOptional) {
                isPlayable = false
              }
            }

            if (isLocked && !isOptional) {
              isPlayable = false
            }

            const isPractice = Boolean(content.practice)

            const defaultProgressDot = {
              status: 'assigned',
              normalizedType: content.type,
              isLocked,
              isSkipped,
              lockDate,
              lastLockDate,
              original,
              normalizedOriginal,
              fromIntroLevelOriginal,
              isOptional,
              isPlayable,
              isPractice,
              playTime: playTimeMap[normalizedOriginal],
              completionDate: completionDateMap[normalizedOriginal],
              tooltipName: levelNameMap[content._id].levelName
            }

            if (content.type === 'game-dev') {
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
              if (['practicelvl', 'capstone', 'interactive'].includes(defaultProgressDot.normalizedType) && defaultProgressDot.status !== 'assigned') {
                defaultProgressDot.clickHandler = () => {
                  this.showPanelSessionContent({
                    student,
                    classroomId: this.classroomId, // TODO remove and use classroomId from teacherDashboard vuex
                    selectedCourseId: this.selectedCourseId,
                    moduleNum,
                    contentId: content._id
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
            border: flagCount >= (this.classroomMembers?.length || 1) / 2 ? 'red' : ''
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
          lastName: userObj.lastName || displayName
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
          original
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
    }
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
    }
  },

  mounted () {
    const areTeacherClassesFetched = this.getActiveClassrooms.length !== 0
    this.setClassroomId(this.classroomId)
    if (this.defaultCourseId) {
      this.setSelectedCourseId({ courseId: this.defaultCourseId })
    }
    this.fetchClassroomById(this.classroomId)
      .then(() => {
        this.setTeacherId(me.get('_id'))
        this.fetchData({ loadedEventName: 'Track Progress: Loaded' })
        // this is for my classes tab showing classnames. If user lands up on a single class page directly, they will only see 1 class in tab if not for this fetch below
        if (!areTeacherClassesFetched) {
          this.fetchClassroomsForTeacher({ teacherId: me.get('_id') })
        }
      })
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
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher'
    }),

    ...mapMutations({
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setClassroomId: 'teacherDashboard/setClassroomId',
      setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom',
      setSelectableStudentIds: 'baseSingleClass/setSelectableStudentIds',
      setSelectableOriginals: 'baseSingleClass/setSelectableOriginals',
      closePanel: 'teacherDashboardPanel/closePanel'
    }),

    isHackStackCourse (selectedCourseId) {
      return selectedCourseId === utils.courseIDs.HACKSTACK
    },

    async fetchClassroomData (classroomId) {
      if (!this.getClassroomById(classroomId)) {
        await this.fetchClassroomById(classroomId)
      }
      this.fetchData({ loadedEventName: 'Track Progress: Loaded' })
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
      return moduleContent.reduce((acc, content, index) => {
        const { _id, fromIntroLevelOriginal, original } = content

        let description = getLearningGoalsDocumentation(content)

        let tooltipName
        let levelName
        if (utils.isCodeCombat) {
          const classroom = new Classroom(this.classroom)
          const levelNumber = classroom.getLevelNumber(original, index + 1)
          tooltipName = `${levelNumber}: ${utils.i18n(content, 'displayName') || utils.i18n(content, 'name')}`
          levelName = tooltipName
        } else {
          tooltipName = getGameContentDisplayNameWithType(content)
          levelName = tooltipName
        }
        if (fromIntroLevelOriginal) {
          const introLevel = intros[fromIntroLevelOriginal] || {}
          levelName = tooltipName
          description = `<h3>${tooltipName}</h3><p>${utils.i18n(content, 'description') || getLearningGoalsDocumentation(content) || ''}</p>`
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

    setClickHandler (details, student, moduleNum, aiScenario, aiProjects) {
      details.clickHandler = () => {
        this.showPanelProjectContent({
          header: 'HackStack Project',
          student,
          classroomId: this.classroomId,
          selectedCourseId: this.selectedCourseId,
          moduleNum,
          aiScenario,
          aiProjects
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

    createProgressDetailsByAiScenario ({ aiScenario, index, student, classSummaryProgress, moduleNum, createModeUnlocked }) {
      const details = {}
      classSummaryProgress[index] = classSummaryProgress[index] || { status: 'assigned', border: '' }
      const aiProjects = this.aiProjectsMapByUser[student._id]?.[aiScenario._id]

      if (aiProjects) {
        this.setProgressDetails(details, classSummaryProgress, index)
        this.setClickHandler(details, student, moduleNum, aiScenario, aiProjects)
        const completed = this.checkIfComplete(aiScenario, aiProjects)
        if (completed) {
          details.status = 'complete'
          createModeUnlocked.unlocked = completed
        }
      }

      let isLocked = ClassroomLib.isModifierActiveForStudent(this.classroom, student._id, this.selectedCourseId, aiScenario._id, 'lockedScenario')
      if (aiScenario.mode === 'use' && !createModeUnlocked.unlocked) {
        isLocked = true
      }

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
        ...details
      }
    },

    // Creates summary stats table for the content. These are the icons along
    // the top of the track progress table.
    createModuleStatsTable (moduleDisplayName, moduleContent, intros, moduleNum) {
      const levelNameMap = this.getLevelNameMap(moduleContent, intros)
      return {
        moduleNum,
        displayName: moduleDisplayName,
        contentList: moduleContent.map((content, index) => {
          const { type, _id, ozariaType, original, fromIntroLevelOriginal, slug } = content
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
            ...levelNameMap[_id]
          })
        }),
        studentSessions: {},
        classSummaryProgress: []
      }
    },

    generateHackStackModule (moduleName, key) {
      const moduleNum = key + 1
      const classSummaryProgress = []
      const moduleScenarios = (this.aiScenarios || [])
        .filter(scenario => scenario.tool === moduleName)

      const aiModel = this.modelsByName[moduleName]

      if (!aiModel) {
        return null
      }
      return {
        moduleNum,
        displayName: `<strong>${aiModel.displayName}</strong><br>${aiModel.description}`,
        displayLogo: utils.aiToolToImage[moduleName] || null,
        contentList: moduleScenarios
          .sort((a, b) => {
            return a.mode === 'use' ? 1 : -1 // Use scenarios should be at the end
          })
          .map((scenario, index) => {
            const type = scenario.mode === 'use' ? 'ai-use' : 'ai-learn'
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
              isPractice: false
            }
          }),
        studentSessions: this.students.reduce((studentSessions, student) => {
          const createModeUnlocked = { unlocked: false }
          studentSessions[student._id] = moduleScenarios
            .map((aiScenario, index) => {
              return this.createProgressDetailsByAiScenario({
                aiScenario,
                index,
                student,
                classSummaryProgress,
                moduleNum,
                createModeUnlocked
              })
            })

          return studentSessions
        }, {}),
        classSummaryProgress
      }
    }
  }
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
