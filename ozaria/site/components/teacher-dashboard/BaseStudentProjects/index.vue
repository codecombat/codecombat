<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import CapstoneMenuBar from './CapstoneMenuBar'
  import CapstoneDetailsContainer from './CapstoneDetailsContainer'
  import CapstoneSessionsContainer from './CapstoneSessionsContainer'

  const projectionData = {
    levelSessions: 'state.complete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage',
    levels: 'original,name,description,slug,concepts,displayName,type,ozariaType,practice,shareable,i18n,assessment,goals,additionalGoals,documentation,screenshot'
  }

  export default {
    name: COMPONENT_NAMES.STUDENT_PROJECTS,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar,
      'capstone-menu-bar': CapstoneMenuBar,
      'capstone-details-container': CapstoneDetailsContainer,
      'capstone-sessions-container': CapstoneSessionsContainer
    },
    props: {
      classroomId: {
        type: String,
        default: '',
        required: true
      }
    },
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
      selectedCourse () {
        return this.classroomCourses.find((c) => c._id === this.selectedCourseId) || {}
      },
      capstoneLevel () {
        return (this.gameContent[this.selectedCourseId] || {}).capstone || {}
      },
      exemplarProjectUrl () {
        return Object.values(this.selectedCourse.modules || {}).find((m) => m.exemplarProjectUrl)?.exemplarProjectUrl || ''
      },
      exemplarCodeUrl () {
        return Object.values(this.selectedCourse.modules || {}).find((m) => m.exemplarCodeUrl)?.exemplarCodeUrl || ''
      },
      projectRubricUrl () {
        return Object.values(this.selectedCourse.modules || {}).find((m) => m.projectRubricUrl)?.projectRubricUrl || ''
      }
    },

    watch: {
      classroomId (newId) {
        this.setClassroomId(newId)
        this.fetchData({ componentName: this.$options.name, options: { data: projectionData } })
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.setClassroomId(this.classroomId)
      this.fetchData({ componentName: this.$options.name, options: { data: projectionData } })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'teacherDashboard/fetchData'
      }),
      ...mapMutations({
        resetLoadingState: 'teacherDashboard/resetLoadingState',
        setTeacherId: 'teacherDashboard/setTeacherId',
        setClassroomId: 'teacherDashboard/setClassroomId',
        setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom'
      }),
      onChangeCourse (courseId) {
        this.setSelectedCourseId({ courseId: courseId })
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
    <capstone-menu-bar
      :title="capstoneLevel.displayName"
      :course-name="selectedCourse.name"
      :exemplar-project-url="exemplarProjectUrl"
      :exemplar-code-url="exemplarCodeUrl"
      :project-rubric-url="projectRubricUrl"
    />
    <div
      class="capstone-container"
    >
      <capstone-details-container
        :key="selectedCourseId+'-capstone-details'"
        class="capstone-details"
        :capstone-level="capstoneLevel"
        :course="selectedCourse"
      />
      <capstone-sessions-container
        :key="selectedCourseId+'-capstone-sessions'"
        class="capstone-sessions"
        :capstone-level="capstoneLevel"
        :level-sessions-by-user="levelSessionsMapByUser"
        :members="classroomMembers"
      />
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
