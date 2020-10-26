<script>
  import { mapGetters } from 'vuex'
  import ModalGetLicenses from '../modals/ModalGetLicenses'
  export default {
    components: {
      ModalGetLicenses
    },
    data: () => {
      return {
        showModalGetLicenses: false
      }
    },
    computed: {
      ...mapGetters({
        getLicensesStatsByTeacher: 'prepaids/getLicensesStatsByTeacher',
        teacherId: 'teacherDashboard/teacherId'
      }),

      totalUsedLicenses () {
        return this.getLicensesStatsByTeacher(this.teacherId).usedLicenses
      },

      totalSpots () {
        return this.getLicensesStatsByTeacher(this.teacherId).totalSpots
      }
    },
    methods: {
      clickRequestLicenses () {
        window.tracker?.trackEvent('Request Licenses Clicked', { category: 'Teachers', label: `${this.$route.path}` })
        this.showModalGetLicenses = true
      }
    }
  }
</script>

<template>
  <div id="licenses-component">
    <div id="Licenses" />
    <div
      v-if="totalSpots === 0"
      id="license-text"
    >
      <span>{{ $t('teacher_dashboard.no_licenses_yet') }}</span>
      <a @click="clickRequestLicenses">{{ $t('teacher_dashboard.req_licenses') }}</a>
    </div>
    <div v-else id="license-text">
      <span>{{ $t('teacher_dashboard.license_ratio_used', { totalUsedLicenses, totalSpots }) }}</span>
      <span class="licenses-applied">{{ $t('teacher_dashboard.licenses_applied') }}</span>
    </div>
    <modal-get-licenses
      v-if="showModalGetLicenses"
      @close="showModalGetLicenses = false"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#Licenses {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Gray.svg);
  background-repeat: no-repeat;
  background-position: center;

  width: 22px;
  height: 20px;
  margin-right: 8px;
}

#licenses-component {
  display: flex;
  flex-direction: row;
  justify-content: center;
  align-items: center;
}

#license-text {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: normal;

  span {
    @include font-p-4-paragraph-smallest-gray;
    font-weight: bold;
  }

  a {
    @include font-p-4-paragraph-smallest-gray;
    font-size: 12px;
    text-decoration: underline;
  }

  .licenses-applied {
    font-weight: normal;
  }
}
</style>
