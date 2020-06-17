<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import Guidelines from './Guidelines'
  import ViewAndMange from './ViewAndManage'
  import TableClassFrame from './table/TableClassFrame'

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
      'loading-bar': LoadingBar
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
        classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
        gameContent: 'teacherDashboard/getGameContentCurrentClassroom'
      }),

      modules () {
        const modules = (this.gameContent[this.selectedCourseId] || {}).modules

        if (modules === undefined) {
          return []
        }

        const modulesForTable = []

        // Get the name and content list of a module.
        for (const [moduleNum, moduleContent] of Object.entries(modules)) {
          const moduleDisplayName = `${this.$t(`teacher.module${moduleNum}`)}${utils.courseModules[this.selectedCourseId][moduleNum]}`
          const moduleStatsForTable = {
            displayName: moduleDisplayName,
            contentList: moduleContent.map(({ displayName, type, _id, name }) => {
              let normalizedType = type
              // TODO: What/how do we detect a 'challengelvl'?
              if (type === 'game-dev') {
                normalizedType = 'capstone'
              } else if (type === undefined) {
                normalizedType = 'practicelvl'
              } else if (type === 'course') {
                normalizedType = 'practicelvl'
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

          const classSummaryProgressMap = new Map(moduleContent.map((content) => {
            return [content._id, 'assigned']
          }))

          // Iterate over all the students and all the sessions for the student.
          for (const student of this.students) {
            const studentSessions = this.levelSessionsMapByUser[student._id]
            moduleStatsForTable.studentSessions[student.displayName] = moduleContent.map((content) => {
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

              if (studentSessions === undefined) {
                return defaultProgressDot
              }

              if (normalizedOriginal) {
                if (!studentSessions[normalizedOriginal]) {
                  return defaultProgressDot
                } else if (studentSessions[normalizedOriginal].state.complete === true) {
                  defaultProgressDot.status = 'complete'
                  classSummaryProgressMap.set(content._id, defaultProgressDot.status)
                } else {
                  defaultProgressDot.status = 'progress'
                  if (classSummaryProgressMap.get(content._id) !== 'complete') {
                    classSummaryProgressMap.set(content._id, defaultProgressDot.status)
                  }
                }

                // Level types that teacher can open TeacherDashboardPanel on.
                if (['practicelvl', 'capstone', 'interactive'].includes(defaultProgressDot.normalizedType)) {
                  defaultProgressDot.clickHandler = () => {
                    this.showPanelSessionContent({
                      student: student,
                      classroomId: this.classroomId, // TODO remove and use classroomId from teacherDashboard vuex
                      selectedCourseId: this.selectedCourseId,
                      moduleNum: moduleNum,
                      contentId: content._id
                    })
                  }
                  defaultProgressDot.selectedKey = `${student._id}_${content._id}`
                }
              } else {
                console.error(`Invariant violated: Content has neither original nor _id: ${content}`)
              }
              return defaultProgressDot
            })
          }

          moduleStatsForTable.classSummaryProgress = Array.from(classSummaryProgressMap.values()).map((status) => ({ status }))
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
            displayName: userObj.name,
            _id: userObj._id,
            isEnrolled
          }
        })
        
        // Sort based on table view options.
        // We count the number of completed sessions here before using the student list elsewhere.
        // The student array is a dependency for other functions, and needs to be ordered prior
        // to other calculations occuring.
        if (this.sortMethod === 'Name') {
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
        this.fetchData()
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.setClassroomId(this.classroomId)
      this.fetchData()
    },

    beforeRouteUpdate (to, from, next) {
      this.closePanel()
      this.clearSelectedStudents()
      next()
    },

    beforeRouteLeave (to, from, next) {
      this.closePanel()
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
  </div>
</template>
