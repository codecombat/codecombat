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
    levels: 'original,name,description,slug,concepts,displayName,type,ozariaType,practice,shareable,i18n,assessment,goals,additionalGoals,documentation'
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

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        classroomsByTeacher: 'classrooms/getClassroomsByTeacher',
        courses: 'courses/sorted',
        getSelectedCourseId: 'teacherDashboard/getSelectedCourseIdForClassroom',
        gameContent: 'gameContent/getContentForClassroom',
        levelSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom',
        members: 'users/getClassroomMembers'
      }),
      teacherId () {
        return me.get('_id')
      },
      classroomId () {
        return this.$route.params.classroomId
      },
      activeClassrooms () {
        return (this.classroomsByTeacher(this.teacherId) || {}).active || []
      },
      classroom () {
        return this.activeClassrooms.find((c) => c._id === this.classroomId) || {}
      },
      classroomCourses () {
        const classroomCourseIds = (this.classroom.courses || []).map((c) => c._id) || []
        return (this.courses || []).filter((c) => classroomCourseIds.includes(c._id))
      },
      selectedCourseId () {
        return this.getSelectedCourseId(this.classroomId) || (this.classroomCourses[0] || {})._id // TODO default should be last assigned course
      },
      selectedCourse () {
        return this.classroomCourses.find((c) => c._id === this.selectedCourseId) || {}
      },
      capstoneLevel () {
        return ((this.gameContent(this.classroomId) || {})[this.selectedCourseId] || {}).capstone || {}
      },
      levelSessionsMapByUser () {
        return this.levelSessionsMapForClassroom(this.classroomId) || {}
      },
      classroomMembers () {
        return this.members(this.classroom) || []
      },
      exemplarProjectUrl () {
        return ''
        // return this.capstoneLevel.exemplarProjectUrl // TODO update after schema is updated
      }
    },

    watch: {
      classroomId () {
        this.fetchData({ componentName: this.$options.name, options: { classroomId: this.classroomId, data: projectionData } })
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name, options: { classroomId: this.classroomId, data: projectionData } })
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
        setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdForClassroom'
      }),
      onChangeCourse (courseId) {
        this.setSelectedCourseId({ classroomId: this.classroomId, courseId: courseId })
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
    />
    <div
      class="container"
    >
      <capstone-details-container
        :key="selectedCourseId+'-capstone-details'"
        class="col-md-5"
        :capstone-level="capstoneLevel"
        :course="selectedCourse"
      />
      <capstone-sessions-container
        :key="selectedCourseId+'-capstone-sessions'"
        class="col-md-7"
        :capstone-level="capstoneLevel"
        :level-sessions-by-user="levelSessionsMapByUser"
        :members="classroomMembers"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.container {
  width: 100%;
}
</style>
