<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import CapstoneMenuBar from './CapstoneMenuBar'
  import CapstoneDetailsContainer from './CapstoneDetailsContainer'
  import CapstoneSessionsContainer from './CapstoneSessionsContainer'
  import utils from 'core/utils'

  const projectionData = {
    levelSessions: 'state.complete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage'
  }

  export default {
    name: COMPONENT_NAMES.STUDENT_PROJECTS,
    components: {
      'capstone-menu-bar': CapstoneMenuBar,
      'capstone-details-container': CapstoneDetailsContainer,
      'capstone-sessions-container': CapstoneSessionsContainer
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
    computed: {
      ...mapGetters({
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
      classroomId (newId) {
        this.setClassroomId(newId)
        this.fetchData({ componentName: this.$options.name, options: { data: projectionData, loadedEventName: 'Student Projects: Loaded' } })
      }
    },

    mounted () {
      this.setTeacherId(this.teacherId || me.get('_id'))
      this.setClassroomId(this.classroomId)
      this.fetchData({ componentName: this.$options.name, options: { data: projectionData, loadedEventName: 'Student Projects: Loaded' } })
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
      })
    }
  }
</script>

<template>
  <div>
    <capstone-menu-bar
      :title="utils.i18n(capstoneLevel, 'displayName')"
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
