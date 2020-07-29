<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import PageNoLicenses from './PageNoLicenses'
  import PageLicenses from './PageLicenses'
  import ModalGetLicenses from '../modals/ModalGetLicenses'
  import ModalApplyLicenses from '../modals/ModalApplyLicenses'
  import ModalShareLicenses from '../modals/ModalShareLicenses/index'

  export default {
    name: COMPONENT_NAMES.MY_LICENSES,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar,
      'page-no-licenses': PageNoLicenses,
      'page-licenses': PageLicenses,
      ModalGetLicenses,
      ModalApplyLicenses,
      ModalShareLicenses
    },

    data: () => {
      return {
        showModalGetLicenses: false,
        showModalApplyLicenses: false,
        showModalShareLicenses: false,
        sharePrepaid: '' // for share licenses modal
      }
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms',
        activeLicenses: 'teacherDashboard/getActiveLicenses',
        expiredLicenses: 'teacherDashboard/getExpiredLicenses',
        teacherId: 'teacherDashboard/teacherId'
      }),

      showLicensesPage () {
        return this.activeLicenses.length > 0 || this.expiredLicenses.length > 0
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'My Licenses: Loaded' } })
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
      }),
      getLicenses () {
        this.showModalGetLicenses = true
      },
      applyLicenses () {
        window.tracker?.trackEvent('My Licenses: Apply Licenses Clicked', { category: 'Teachers' })
        this.showModalApplyLicenses = true
      },
      shareLicenses (prepaid) {
        window.tracker?.trackEvent('My Licenses: Share Licenses Clicked', { category: 'Teachers' })
        this.showModalShareLicenses = true
        this.sharePrepaid = prepaid
      }
    }
  }
</script>

<template>
  <div id="base-licenses">
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar title="My Licenses" @newClass="$emit('newClass')" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />

    <page-licenses
      v-if="showLicensesPage"
      :active-licenses="activeLicenses"
      :expired-licenses="expiredLicenses"
      :teacher-id="teacherId"
      @getLicenses="getLicenses"
      @apply="applyLicenses"
      @share="shareLicenses"
    />
    <page-no-licenses
      v-else-if="!loading"
      @getLicenses="getLicenses"
    />

    <modal-get-licenses
      v-if="showModalGetLicenses"
      @close="showModalGetLicenses = false"
    />
    <modal-apply-licenses
      v-if="showModalApplyLicenses"
      @close="showModalApplyLicenses = false"
    />
    <modal-share-licenses
      v-if="showModalShareLicenses"
      :prepaid="sharePrepaid"
      @close="showModalShareLicenses = false"
    />
  </div>
</template>

<style scoped>
#base-licenses {
  margin-bottom: -50px;
}
</style>
