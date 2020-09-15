<script>
  import { mapGetters, mapMutations, mapActions } from 'vuex'
  import { COMPONENT_NAMES } from '../../common/constants.js'
  import BaseTeacherLicensesComponent from 'ozaria/site/components/teacher-dashboard/BaseTeacherLicenses'

  export default {
    name: COMPONENT_NAMES.ADMINISTERED_TEACHERS.TEACHER_LICENSES,

    components: {
      BaseTeacherLicensesComponent
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
        activeLicenses: 'teacherDashboard/getActiveLicenses',
        expiredLicenses: 'teacherDashboard/getExpiredLicenses'
      }),
      showNoLicenses () {
        return this.activeLicenses.length === 0 && this.expiredLicenses.length === 0 && !this.loading
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
      v-if="showNoLicenses"
      class="no-licenses"
    >
      <span> {{ selectedAdministeredTeacherName }} doesn’t have any licenses yet! Purchase or share licenses with {{ selectedAdministeredTeacherName }} from your <a href="/school-administrator/licenses">Admin Licenses</a> page. </span>
    </div>
    <base-teacher-licenses-component
      v-else
      :teacher-id="teacherId"
      :display-only="true"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "ozaria/site/styles/common/variables.scss";
.no-licenses {
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
  a {
    text-decoration: underline;
  }
}
</style>
