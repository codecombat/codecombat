<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'

  export default {
    name: COMPONENT_NAMES.STUDENT_PROJECTS,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        classroomsByTeacher: 'classrooms/getClassroomsByTeacher'
      }),
      teacherId () {
        return me.get('_id')
      },
      classroomId () {
        return this.$route.params.classroomId
      },
      activeClassrooms () {
        return (this.classroomsByTeacher(this.teacherId) || {}).active
      }
    },

    watch: {
      classroomId () {
        this.fetchData({ componentName: this.$options.name, options: { classroomId: this.classroomId } })
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name, options: { classroomId: this.classroomId } })
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
        setTeacherId: 'teacherDashboard/setTeacherId'
      })
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar title="PLACEHOLDER Classname" :showClassInfo="true" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />
    <br /><br /><br /><br /><br /><br />
    <span>PLACEHOLDER: STUDENT PROJECTS COMPONENT GOES HERE</span>
    <br /><br /><br /><br /><br /><br />
  </div>
</template>
