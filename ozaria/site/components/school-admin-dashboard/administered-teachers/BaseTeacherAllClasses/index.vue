<script>
  import { mapGetters, mapMutations, mapActions } from 'vuex'
  import { COMPONENT_NAMES } from '../../common/constants.js'
  import BaseMyClasses from 'ozaria/site/components/teacher-dashboard/BaseMyClasses'

  export default {
    name: COMPONENT_NAMES.ADMINISTERED_TEACHERS.ALL_CLASSES,

    components: {
      BaseMyClasses
    },

    props: {
      teacherId: {
        type: String,
        required: true
      }
    },

    computed: {
      ...mapGetters({
        loading: 'schoolAdminDashboard/getLoadingState',
        selectedAdministeredTeacherName: 'schoolAdminDashboard/selectedAdministeredTeacherName',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms',
        archivedClassrooms: 'teacherDashboard/getArchivedClassrooms'
      }),
      showNoClasses () {
        return this.activeClassrooms.length === 0 && this.archivedClassrooms.length === 0 && !this.loading
      }
    },

    mounted () {
      this.setSelectedAdministeredTeacherId(this.teacherId)
      this.fetchData({ componentName: this.$options.name })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapMutations({
        resetLoadingState: 'schoolAdminDashboard/resetLoadingState',
        setSelectedAdministeredTeacherId: 'schoolAdminDashboard/setSelectedAdministeredTeacherId'
      }),
      ...mapActions({
        fetchData: 'schoolAdminDashboard/fetchData'
      })
    }
  }
</script>

<template>
  <div>
    <div
      v-if="showNoClasses"
      class="no-classes"
    >
      <span> {{ selectedAdministeredTeacherName }} hasn’t created any classes yet. </span>
    </div>
    <base-my-classes
      v-else
      :teacher-id="teacherId"
      :display-only="true"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "ozaria/site/styles/common/variables.scss";
.no-classes {
  margin: 30px;
  min-height: 200px;
  span {
    font-family: Work Sans;
    font-style: normal;
    font-weight: normal;
    font-size: 20px;
    line-height: 23px;
    color: $pitch;
  }
}
</style>
