<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import Guidelines from './Guidelines'
  import ViewAndMange from './ViewAndManage'
  import TableClassFrame from './table/TableClassFrame'
  import ModalEditStudent from '../modals/ModalEditStudent'

  import utils from 'app/core/utils'
  import User from 'models/User'

  import _ from 'lodash'
  import TableStudentListVue from './table/TableStudentList.vue'

  export default {
    name: COMPONENT_NAMES.MY_CLASSES_SINGLE,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'guidelines': Guidelines,
      'view-and-manage': ViewAndMange,
      'table-class-frame': TableClassFrame,
      'loading-bar': LoadingBar,
      ModalEditStudent
    },
    props: {
      classroomId: {
        type: String,
        default: '',
        required: true
      }
    },

    data: () => ({
      isGuidelinesVisible: true,
      sortMethod: 'Name'
    }),

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms',
        classroom: 'teacherDashboard/getCurrentClassroom',
        classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
        selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
        levelSessionsMapByUser: 'teacherDashboard/getLevelSessionsMapCurrentClassroom',
        getInteractiveSessionsForClass: 'interactives/getInteractiveSessionsForClass',
        classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
        gameContent: 'teacherDashboard/getGameContentCurrentClassroom',
        editingStudent: 'baseSingleClass/currentEditingStudent',
        getCourseInstancesForClass: 'courseInstances/getCourseInstancesForClass'
      }),

      modules () {
        const selectedCourseId = this.selectedCourseId
        const modules = (this.gameContent[selectedCourseId] || {}).modules

        if (modules === undefined) {
          return []
        }

        const modulesForTable = []
        const courseInstances = this.getCourseInstancesForClass(this.classroom.ownerID, this.classroom._id)
        const assignmentMap = new Map()
        for (const { courseID, members } of courseInstances) {
          assignmentMap.set(courseID, new Set(members || []))
        }

        // Get the name and content list of a module.
        for (const [moduleNum, moduleContent] of Object.entries(modules)) {
          const moduleDisplayName = `${this.$t(`teacher.module${moduleNum}`)}${utils.courseModules[this.selectedCourseId][moduleNum]}`
          const moduleStatsForTable = {
            displayName: moduleDisplayName,
            contentList: moduleContent.map(({ displayName, type, _id, name, ozariaType }) => {
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
                normalizedType = type;
              }

              if (!['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl'].includes(normalizedType)) {
                throw new Error(`Didn't handle normalized content type: '${normalizedType}'`)
              }

              return ({
                displayName: displayName || name,
                type: normalizedType,
                _id,
                description: '' // TODO: Where do we store this?
              })
            }),
            studentSessions: {},
            classSummaryProgress: []
          }

          // Track summary stats to display in the header of the table
          const classSummaryProgressMap = new Map(moduleContent.map((content) => {
            return [content._id, { status: 'assigned', flagCount: 0 }]
          }))

          // Iterate over all the students and all the sessions for the student.
          for (const student of this.students) {
            const studentSessions = this.levelSessionsMapByUser[student._id] || {}
            const levelOriginalCompletionMap = {}

            for (const session of Object.values(studentSessions)) {
              levelOriginalCompletionMap[session.level.original] = session.state
            }

            moduleStatsForTable.studentSessions[student._id] = moduleContent.map((content) => {
              const { original, fromIntroLevelOriginal } = content
              let normalizedOriginal = original || fromIntroLevelOriginal
              const defaultProgressDot = {
                status: 'assigned',
                normalizedType: content.type
              }

              if (content.type === 'game-dev') {
                defaultProgressDot.normalizedType = 'capstone'
              } else if (content.type === undefined) {
                defaultProgressDot.normalizedType = 'practicelvl'
              } else if (content.type === 'course') {
                defaultProgressDot.normalizedType = 'practicelvl'
              }

              if (!assignmentMap.get(selectedCourseId)?.has(student._id)) {
                // Return unassigned progress dot if the student isn't in the course-instance.
                defaultProgressDot.status = "unassigned"
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
                    levelOriginalCompletionMap[fromIntroLevelOriginal]?.complete === true
                    && defaultProgressDot.status !== 'complete'
                    && (levelOriginalCompletionMap[fromIntroLevelOriginal]?.introContentSessionComplete?.[content._id]) === undefined
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
                  } else {
                    // If there are no interactive sessions we ensure no progress is shown.
                    // This check is requires because with backwards compatibility we cannot have
                    // an interactive without sessions be shown as assigned or complete.
                    defaultProgressDot.status === 'assigned'
                  }
                }

                // Level types that teacher can open TeacherDashboardPanel on.
                // We also need to make sure that teachers can only click if a session exists.
                if (['practicelvl', 'capstone', 'interactive'].includes(defaultProgressDot.normalizedType) && defaultProgressDot.status !== 'assigned') {
                  defaultProgressDot.clickHandler = () => {
                    this.showPanelSessionContent({
                      student: student,
                      classroomId: this.classroomId, // TODO remove and use classroomId from teacherDashboard vuex
                      selectedCourseId: this.selectedCourseId,
                      moduleNum: moduleNum,
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
          return {
            displayName: User.broadName(userObj),
            _id: userObj._id,
            isEnrolled
          }
        })
        
        // Sort based on table view options.
        // We count the number of completed sessions here before using the student list elsewhere.
        // The student array is a dependency for other functions, and needs to be ordered prior
        // to other calculations occuring.
        if (this.sortMethod === 'Name') {
          students.sort((a, b) => {
            return a.displayName.localeCompare(b.displayName)
          })
          return students
        } else {
          const originalsInModule = Object.values(modules).flat().map(({ fromIntroLevelOriginal, original }) => fromIntroLevelOriginal || original)
          const studentProgression = new Map(students.map(({ _id }) => ([_id, 0])))

          for (const { _id } of students) {
            let completedCount = 0;
            for (const original of originalsInModule) {
              if (this.levelSessionsMapByUser[_id]?.[original]?.state.complete === true) {
                completedCount ++;
              }
            }
            studentProgression.set(_id, completedCount)
          }

          students.sort((a, b) => {
            return studentProgression.get(b._id) - studentProgression.get(a._id)
          })
          if (this.sortMethod === 'Progress (reversed)') {
            students.reverse()
          }

          return students
        }
        return []
      }
    },

    watch: {
      classroomId (newId) {
        this.setClassroomId(newId)
        this.fetchData({ loadedEventName: 'Track Progress: Loaded' })
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.setClassroomId(this.classroomId)
      this.fetchData({ loadedEventName: 'Track Progress: Loaded' })
    },

    beforeRouteUpdate (to, from, next) {
      this.closePanel()
      this.clearSelectedStudents()
      next()
    },

    beforeRouteLeave (to, from, next) {
      this.closePanel()
      this.clearSelectedStudents()
      next()
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'baseSingleClass/fetchData',
        setPanelSessionContent: 'teacherDashboardPanel/setPanelSessionContent',
        showPanelSessionContent: 'teacherDashboardPanel/showPanelSessionContent',
        clearSelectedStudents: 'baseSingleClass/clearSelectedStudents',
        addStudentSelectedId: 'baseSingleClass/addStudentSelectedId'
      }),

      ...mapMutations({
        resetLoadingState: 'teacherDashboard/resetLoadingState',
        setTeacherId: 'teacherDashboard/setTeacherId',
        setClassroomId: 'teacherDashboard/setClassroomId',
        setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom',
        closePanel: 'teacherDashboardPanel/closePanel'
      }),

      onChangeCourse (courseId) {
        this.setSelectedCourseId({ courseId: courseId })
      },

      onChangeStudentSort (sortMethod) {
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
      }
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar
      :title="classroom.name || ''"
      :show-class-info="true"
      :classroom="classroom"
      :courses="classroomCourses"
      :selected-course-id="selectedCourseId"
      @change-course="onChangeCourse"
    />
    <loading-bar
      :key="loading"
      :loading="loading"
    />
    <guidelines :visible="isGuidelinesVisible" v-on:click-arrow="clickGuidelineArrow" />
    <view-and-manage
      :arrow-visible="!isGuidelinesVisible"

      @change-sort-by="onChangeStudentSort"
      @click-arrow="clickGuidelineArrow"
      @assignContent="$emit('assignContent')"
      @addStudents="$emit('addStudents')"
      @removeStudents="$emit('removeStudents')"
    />

    <table-class-frame
      v-if="modules && students"
      :students="students"
      :modules="modules"

      @toggle-all-students="toggleAllStudents"
    />
    <modal-edit-student v-if="editingStudent" />
  </div>
</template>
