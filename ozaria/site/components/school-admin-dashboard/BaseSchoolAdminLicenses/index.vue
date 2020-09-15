<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'

  import PageNoLicenses from './PageNoLicenses'
  import PageLicenses from './PageLicenses'
  import ModalGetLicenses from 'ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'
  import ModalShareLicenses from 'ozaria/site/components/teacher-dashboard/modals/ModalShareLicenses/index'

  export default {
    name: COMPONENT_NAMES.SCHOOL_ADMIN_LICENSES,

    components: {
      PageNoLicenses,
      PageLicenses,
      ModalGetLicenses,
      ModalShareLicenses
    },

    data: () => {
      return {
        showModalGetLicenses: false,
        showModalShareLicenses: false,
        sharePrepaid: '' // for share licenses modal
      }
    },

    computed: {
      ...mapGetters({
        loading: 'schoolAdminDashboard/getLoadingState',
        schoolAdminId: 'schoolAdminDashboard/schoolAdminId',
        activeLicenses: 'schoolAdminDashboard/getActiveLicenses',
        expiredLicenses: 'schoolAdminDashboard/getExpiredLicenses'
      }),

      showLicensesPage () {
        return this.activeLicenses.length > 0 || this.expiredLicenses.length > 0
      },

      getLicensesMessage () { // TODO i18n?
        if (this.showLicensesPage) {
          return 'Hi Ozaria! I\'m interested in purchasing more licenses for my school or district.'
        } else {
          return 'Hi Ozaria! I\'m interested in learning more about your curriculum and discussing pricing options.'
        }
      }
    },

    mounted () {
      this.setPageTitle(PAGE_TITLES[this.$options.name])
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'Admin Licenses: Loaded' } })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'schoolAdminDashboard/fetchData'
      }),

      ...mapMutations({
        resetLoadingState: 'schoolAdminDashboard/resetLoadingState',
        setPageTitle: 'schoolAdminDashboard/setPageTitle'
      }),

      getLicenses () {
        this.showModalGetLicenses = true
      },
      shareLicenses (prepaid) {
        window.tracker?.trackEvent('Admin Licenses: Share Licenses Clicked', { category: 'SchoolAdmin' })
        this.showModalShareLicenses = true
        this.sharePrepaid = prepaid
      }
    }
  }
</script>

<template>
  <div id="base-admin-licenses">
    <page-licenses
      v-if="showLicensesPage"
      :active-licenses="activeLicenses"
      :expired-licenses="expiredLicenses"
      :teacher-id="schoolAdminId"
      @getLicenses="getLicenses"
      @share="shareLicenses"
    />
    <page-no-licenses
      v-else-if="!loading"
      @getLicenses="getLicenses"
    />

    <modal-get-licenses
      v-if="showModalGetLicenses"
      subtitle="Send us a message and our classroom success team will be in touch to help find the best solution for your needs!"
      :email-message="getLicensesMessage"
      @close="showModalGetLicenses = false"
    />
    <modal-share-licenses
      v-if="showModalShareLicenses"
      :prepaid="sharePrepaid"
      @close="showModalShareLicenses = false"
    />
  </div>
</template>

<style lang="scss" scoped>
#base-admin-licenses {
  margin-bottom: -50px;
  min-height: 200px;
}
</style>
