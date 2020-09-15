<script>
  import BaseCurriculumGuide from '../../teacher-dashboard/BaseCurriculumGuide'
  import LoadingBar from 'ozaria/site/components/common/LoadingBar'
  import SecondaryNavigation from '../common/SecondaryNavigation'
  import TitleBar from '../common/TitleBar'
  import { mapMutations, mapGetters } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants'
  import Panel from 'ozaria/site/components/teacher-dashboard/Panel/index.vue'

  export default {
    components: {
      BaseCurriculumGuide,
      LoadingBar,
      SecondaryNavigation,
      TitleBar,
      Panel
    },

    data () {
      return {
        showRestrictedDiv: false
      }
    },

    computed: {
      ...mapGetters({
        dsaLoading: 'schoolAdminDashboard/getLoadingState',
        pageTitle: 'schoolAdminDashboard/getPageTitle',
        pageBreadCrumbs: 'schoolAdminDashboard/getPageBreadCrumbs',
        componentName: 'schoolAdminDashboard/getComponentName',
        dtLoading: 'teacherDashboard/getLoadingState',
        classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
        selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom'
      }),

      loading () {
        return this.dsaLoading || this.dtLoading
      },

      showCourseDropdown () {
        return this.componentName === COMPONENT_NAMES.ADMINISTERED_TEACHERS.CLASS_PROGRESS || this.componentName === COMPONENT_NAMES.ADMINISTERED_TEACHERS.CLASS_PROJECTS
      },

      showBreadCrumbs () {
        return Object.values(COMPONENT_NAMES.ADMINISTERED_TEACHERS).includes(this.componentName)
      }
    },

    created () {
      if (!me.isTeacher() || !me.isSchoolAdmin()) { // TODO Restrict this from Router itself similar to how `RestrictedToTeachersView` works
        this.showRestrictedDiv = true
      } else {
        this.showRestrictedDiv = false
        this.setSchoolAdminId(me.get('_id'))
        this.setTeacherPagesTrackCategory('SchoolAdmin') // For pages shared between DT and DSA
      }
    },

    metaInfo () {
      return {
        title: 'Ozaria - School Admin Dashboard'
      }
    },

    beforeRouteUpdate (to, from, next) {
      // Ensures we close curriculum guide when navigating between pages in the
      // school admin dashboard.
      this.closeCurriculumGuide()
      next()
    },

    methods: {
      ...mapMutations({
        closeCurriculumGuide: 'baseCurriculumGuide/closeCurriculumGuide',
        setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom',
        setSchoolAdminId: 'schoolAdminDashboard/setSchoolAdminId',
        setTeacherPagesTrackCategory: 'teacherDashboard/setTrackCategory'
      }),

      onChangeCourse (courseId) {
        this.setSelectedCourseId({ courseId: courseId })
      }
    }
  }
</script>

<template>
  <div
    v-if="showRestrictedDiv"
    class="restricted-div"
  >
    <h5> {{ $t('teacher.access_restricted') }} </h5>
    <p> {{ $t('teacher.teacher_account_required') }} </p>
  </div>
  <div v-else>
    <base-curriculum-guide />
    <panel />
    <secondary-navigation />
    <title-bar
      :title="pageTitle"
      :breadcrumb-list="pageBreadCrumbs"
      :show-bread-crumbs="showBreadCrumbs"
      :show-course-dropdown="showCourseDropdown"
      :courses="classroomCourses"
      :selected-course-id="selectedCourseId"
      @change-course="onChangeCourse"
    />
    <loading-bar
      :key="loading"
      :loading="loading"
    />
    <router-view />
  </div>
</template>

<style lang="scss" scoped>
.restricted-div {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 100px;
}
</style>
