
<script>
import { mapGetters, mapActions, mapMutations } from 'vuex'
import { COMPONENT_NAMES } from '../common/constants.js'
import utils from 'core/utils'
import TeacherClassAssessmentsTable from 'app/views/courses/TeacherClassAssessmentsTable'
import PieChart from 'core/components/PieComponent'

const Classroom = require('models/Classroom')
const Course = require('models/Course')
const Classrooms = require('collections/Classrooms')
const Courses = require('collections/Courses')
const LevelSessions = require('collections/LevelSessions')
const Users = require('collections/Users')
const Levels = require('collections/Levels')
const CourseInstances = require('collections/CourseInstances')
const helper = require('lib/coursesHelper')

require('app/styles/courses/teacher-class-view.sass')

const projectionData = {
  levelSessions: 'state.complete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage'
}

export default {
  name: COMPONENT_NAMES.STUDENT_ASSESSMENTS,
  components: {
    'teacher-class-assessments-table': TeacherClassAssessmentsTable,
    'pie-chart': PieChart
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
    }
  },
  data () {
    return {
      propsData: null
    }
  },
  computed: {
    ...mapGetters({
      classroom: 'teacherDashboard/getCurrentClassroom',
      classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      levelSessionsMapByUser: 'teacherDashboard/getLevelSessionsMapCurrentClassroom',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      gameContent: 'teacherDashboard/getGameContentCurrentClassroom',
      getClassroomById: 'classrooms/getClassroomById',
      getActiveClassrooms: 'teacherDashboard/getActiveClassrooms',
      getCourseInstancesOfClass: 'courseInstances/getCourseInstancesOfClass',
      getInteractiveSessionsForClass: 'interactives/getInteractiveSessionsForClass',
      getSessionsForClassroom: 'levelSessions/getSessionsForClassroom',
      loading: 'teacherDashboard/getLoadingState',
      getLevelsForClassroom: 'levels/getLevelsForClassroom'
    }),
    selectedCourse () {
      return this.classroomCourses.find((c) => c._id === this.selectedCourseId) || {}
    },
    capstoneLevel () {
      return (this.gameContent[this.selectedCourseId] || {}).capstone || {}
    },
    utils () {
      return utils
    },
    exemplarProjectUrl () {
      return this.capstoneLevel.exemplarProjectUrl || ''
    },
    exemplarCodeUrl () {
      return this.capstoneLevel.exemplarCodeUrl || ''
    },
    projectRubricUrl () {
      return this.capstoneLevel.projectRubricUrl || ''
    }
  },

  watch: {
    async classroomId (newId) {
      this.setClassroomId(newId)
      await this.fetchClassroomData(newId)
    },
    async selectedCourseId (newId, oldId) {
      if (newId !== oldId) {
        await this.fetchClassroomData(this.classroomId)
      }
    }
  },

  async mounted () {
    this.setTeacherId(this.teacherId || me.get('_id'))
    this.setClassroomId(this.classroomId)
    await this.fetchClassroomData(this.classroomId)
    const areTeacherClassesFetched = this.getActiveClassrooms.length !== 0
    if (!areTeacherClassesFetched) {
      // to show list of classes in student projects tab
      await this.fetchClassroomsForTeacher({ teacherId: me.get('_id') })
    }
  },

  destroyed () {
    this.resetLoadingState()
  },

  methods: {
    ...mapActions({
      fetchData: 'teacherDashboard/fetchData',
      fetchClassroomById: 'classrooms/fetchClassroomForId',
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher'
    }),
    ...mapMutations({
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setClassroomId: 'teacherDashboard/setClassroomId',
      setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom'
    }),

    async getCourseAssessmentPairs (courses, classroom) {
      const levels = new Levels(this.getLevelsForClassroom(this.classroomId))
      // await levels.fetchForClassroom(this.classroomId, { data: { project: 'original,name,primaryConcepts,concepts,primerLanguage,practice,shareable,i18n,assessment,assessmentPlacement,slug,goals' } })
      const courseAssessmentPairs = []
      const coursesStub = new Courses(courses)
      for (const course of coursesStub.models) {
        const assessmentLevels = classroom.getLevels({ courseID: course.id, assessmentLevels: true }).models
        const assessmentLevelOriginals = assessmentLevels.map(l2 => l2.get('original'))
        const fullLevels = levels.models.filter(l => assessmentLevelOriginals.includes(l.get('original')))
        courseAssessmentPairs.push([course, fullLevels])
      }
      return courseAssessmentPairs
    },

    async fetchClassroomData (classroomId) {
      this.propsData = null

      if (!this.getClassroomById(classroomId)) {
        await this.fetchClassroomById(classroomId)
      }
      await this.fetchData({ componentName: this.$options.name, options: { data: projectionData, loadedEventName: 'Student Assessments: Loaded' } })

      const classroomInstance = new Classroom(this.classroom)
      const courseInstances = new CourseInstances(this.getCourseInstancesOfClass(this.classroomId))
      const courses = new Courses(this.classroomCourses)
      const students = new Users(this.classroomMembers)
      const classroomsStub = new Classrooms([classroomInstance])
      const levelSessions = new LevelSessions(this.getSessionsForClassroom(this.classroomId))
      classroomInstance.sessions = levelSessions

      if (classroomInstance.hasAssessments()) {
        let courseInstance
        let levels = []
        let course = this.selectedCourse

        if (course && !classroomInstance.hasAssessments({ courseId: this.selectedCourseId })) {
          course = this.classroomCourses.find(c => classroomInstance.hasAssessments({ courseId: c._id }))
        }

        if (course) {
          const pair = (await this.getCourseAssessmentPairs(this.classroomCourses, classroomInstance, levels)).find(pair => pair[0].id === course._id)
          levels = pair ? pair[1] : []
          levels = levels.map(l => l.toJSON())

          courseInstance = courseInstances.findWhere({ courseID: this.selectedCourseId, classroomID: this.classroomId })

          if (courseInstance) {
            courseInstance = courseInstance.toJSON()
          }
        }

        const progressData = helper.calculateAllProgress(classroomsStub, courses, courseInstances, students)

        this.propsData = {
          students: this.classroomMembers,
          levels,
          course,
          progress: progressData?.get({ classroom: classroomInstance, course: new Course(course) }),
          courseInstance,
          classroom: classroomInstance.toJSON(),
          readOnly: true
        }
        console.log('propsData', this.propsData)
      }
    }
  }
}
</script>

<template>
  <div id="teacher-class-view">
    <div class="container">
      <h4 class="m-b-2 m-t-3">{{ $t('teacher.progress_color_key') }}</h4>
      <div id="progress-color-key-row" class="row m-b-3">
        <div class="col col-md-2 col-xs-3">
          <div class="progress-dot forest"></div>
          <div class="key-text">
            <span class="small">{{ $t('teacher.success') }}</span>
          </div>
          <div class="clearfix"></div>
        </div>
        <div class="col col-md-2 col-xs-3">
          <div class="progress-dot gold"></div>
          <div class="key-text">
            <span class="small">{{ $t('teacher.in_progress') }}</span>
          </div>
          <div class="clearfix"></div>
        </div>
        <div class="col col-md-2 col-xs-3">
          <div class="progress-dot"></div>
          <div class="key-text">
            <span class="small">{{ $t('teacher.not_started') }}</span>
          </div>
          <div class="clearfix"></div>
        </div>
        <div class="col col-md-2 col-xs-3">
          <pie-chart :percent="100 * 2 / 3" :strokeWidth="10" color="#20572B" :opacity="1"></pie-chart>
          <div class="key-text">
            <span class="small" data-i18n='TODO'>Partially Complete</span>
          </div>
          <div class="clearfix"></div>
        </div>
      </div>
      <div v-if="!loading">
        <div v-if="propsData && propsData.courseInstance && propsData.courseInstance.members.length > 0">
          <teacher-class-assessments-table :students="propsData.students" :levels="propsData.levels"
            :course="propsData.course" :course-instance="propsData.courseInstance" :classroom="propsData.classroom"
            :progress="propsData.progress" :readOnly="propsData.readOnly" />
        </div>
        <div v-else>
          <h2 class="text-center">
            <i>{{ $t('teacher.no_student_assigned') }}</i>
          </h2>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.capstone-container {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  justify-content: center;
  padding: 0px 30px;
}

.capstone-details {
  width: 30%;
  margin-right: 60px;
}

.capstone-sessions {
  width: 70%;
}
</style>
