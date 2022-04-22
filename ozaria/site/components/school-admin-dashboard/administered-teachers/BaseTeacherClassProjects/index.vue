<script>
  import { mapGetters, mapMutations, mapActions } from 'vuex'
  import { COMPONENT_NAMES } from '../../common/constants.js'
  import BaseStudentProjects from 'ozaria/site/components/teacher-dashboard/BaseStudentProjects'

  export default {
    name: COMPONENT_NAMES.ADMINISTERED_TEACHERS.CLASS_PROJECTS,

    components: {
      BaseStudentProjects
    },

    props: {
      teacherId: {
        type: String,
        required: true
      },
      classroomId: {
        type: String,
        required: true
      }
    },

    computed: {
      ...mapGetters({
        loading: 'schoolAdminDashboard/getLoadingState'
      })
    },

    mounted () {
      this.setSelectedAdministeredTeacherId(this.teacherId)
      this.setSelectedAdministeredTeacherClassroomId(this.classroomId)
      this.fetchData({ componentName: this.$options.name })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapMutations({
        resetLoadingState: 'schoolAdminDashboard/resetLoadingState',
        setSelectedAdministeredTeacherId: 'schoolAdminDashboard/setSelectedAdministeredTeacherId',
        setSelectedAdministeredTeacherClassroomId: 'schoolAdminDashboard/setSelectedAdministeredTeacherClassroomId'
      }),
      ...mapActions({
        fetchData: 'schoolAdminDashboard/fetchData'
      })
    }
  }
</script>

<template>
  <div>
    <base-student-projects
      :classroom-id="classroomId"
      :teacher-id="teacherId"
    />
  </div>
</template>

<style lang="scss" scoped>

</style>
