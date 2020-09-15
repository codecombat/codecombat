<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
  import PageNoLicenses from './PageNoLicenses'
  import PageLicenses from './PageLicenses'
  import ModalGetLicenses from '../modals/ModalGetLicenses'
  import ModalApplyLicenses from '../modals/ModalApplyLicenses'
  import ModalShareLicenses from '../modals/ModalShareLicenses/index'

  export default {
    name: COMPONENT_NAMES.MY_LICENSES,
    components: {
      'page-no-licenses': PageNoLicenses,
      'page-licenses': PageLicenses,
      ModalGetLicenses,
      ModalApplyLicenses,
      ModalShareLicenses
    },

    props: {
      teacherId: { // sent from DSA
        type: String,
        default: ''
      },
      displayOnly: { // sent from DSA
        type: Boolean,
        default: false
      }
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
        activeLicenses: 'teacherDashboard/getActiveLicenses',
        expiredLicenses: 'teacherDashboard/getExpiredLicenses',
        getTeacherId: 'teacherDashboard/teacherId'
      }),

      showLicensesPage () {
        return this.displayOnly || this.activeLicenses.length > 0 || this.expiredLicenses.length > 0
      }
    },

    mounted () {
      this.setTeacherId(this.teacherId || me.get('_id'))
      this.setPageTitle(PAGE_TITLES[this.$options.name])
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
        setTeacherId: 'teacherDashboard/setTeacherId',
        setPageTitle: 'teacherDashboard/setPageTitle'
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

    <page-licenses
      v-if="showLicensesPage"
      :active-licenses="activeLicenses"
      :expired-licenses="expiredLicenses"
      :teacher-id="getTeacherId"
      :display-only="displayOnly"
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
