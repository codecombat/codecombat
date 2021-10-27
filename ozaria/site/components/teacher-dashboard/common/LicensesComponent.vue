<script>
  import {mapActions, mapGetters} from 'vuex'
  import ModalGetLicenses from '../modals/ModalGetLicenses'
  export default {
    components: {
      ModalGetLicenses
    },
    props: {
      selectedTeacherId: {
        type: String,
      },
      sharedClassroomId: {
        type: String
      }
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
        return this.getLicensesStatsByTeacher(this.currentTeacherId).usedLicenses
      },

      totalSpots () {
        return this.getLicensesStatsByTeacher(this.currentTeacherId).totalSpots
      },
      currentTeacherId () {
        return this.selectedTeacherId || this.teacherId
      },
      showRequestLicense () {
        return this.currentTeacherId === me.get('_id')
      }
    },
    methods: {
      ...mapActions({
        fetchPrepaidsForTeacher: 'prepaids/fetchPrepaidsForTeacher'
      }),
      clickRequestLicenses () {
        window.tracker?.trackEvent('Request Licenses Clicked', { category: 'Teachers', label: `${this.$route.path}` })
        this.showModalGetLicenses = true
      }
    },
    mounted() {
      if (this.selectedTeacherId && this.selectedTeacherId !== this.teacherId) {
        this.fetchPrepaidsForTeacher({ teacherId: this.selectedTeacherId, sharedClassroomId: this.sharedClassroomId })
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
      <a @click="clickRequestLicenses" v-if="this.showRequestLicense">{{ $t('teacher_dashboard.req_licenses') }}</a>
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
