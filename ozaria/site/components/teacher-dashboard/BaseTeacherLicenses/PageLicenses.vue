
<script>
  import LicenseCard from './common/LicenseCard'
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import { mapGetters } from 'vuex'
  import ButtonResourceIcon from '../BaseResourceHub/components/ButtonResourceIcon'
  import { resourceHubLinks } from '../common/constants.js'

  export default {
    components: {
      LicenseCard,
      PrimaryButton,
      ButtonResourceIcon
    },
    props: {
      activeLicenses: {
        type: Array,
        required: true,
        default: () => []
      },
      expiredLicenses: {
        type: Array,
        required: true,
        default: () => []
      },
      teacherId: {
        type: String,
        required: true
      }
    },
    computed: {
      ...mapGetters({
        getUserById: 'users/getUserById'
      }),
      howToLicensesResourceData () {
        return resourceHubLinks.howToLicenses
      }
    },
    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'Teachers' })
        }
      }
    }
  }
</script>

<template>
  <div class="licenses-page">
    <div class="side-bar">
      <span class="side-bar-title"> {{ $t("common.help") }} </span>
      <div class="side-bar-text">
        Have questions about applying or revoking licenses?
      </div>
      <button-resource-icon
        class="pdf-btn"
        :icon="howToLicensesResourceData.icon"
        :label="howToLicensesResourceData.label"
        :link="howToLicensesResourceData.link"
        from="My Licenses"
      />
      <div class="side-bar-text">
        Need more licenses? We'll help you build a solution that meets your needs.
      </div>
      <primary-button
        class="get-licenses-btn"
        @click="$emit('getLicenses')"
        @click.native="trackEvent('My Licenses: Get More Licenses Clicked')"
      >
        {{ $t("courses.get_enrollments") }}
      </primary-button>
    </div>
    <div class="license-cards">
      <div class="active-licenses row" v-if="activeLicenses.length > 0">
        <span class="col-md-12"> {{ $t("teacher_licenses.active_licenses") }} </span>
        <license-card
          v-for="license in activeLicenses"
          :key="license._id"
          class="card col-md-2"
          :total="license.maxRedeemers"
          :used="(license.redeemers || []).length"
          :start-date="license.startDate"
          :end-date="license.endDate"
          :owner="getUserById(license.creator)"
          :teacher-id="teacherId"
          @apply="$emit('apply')"
          @share="$emit('share', license)"
        />
      </div>
      <div class="expired-licenses row" v-if="expiredLicenses.length > 0">
        <span class="col-md-12"> {{ $t("teacher_licenses.expired_licenses") }} </span>
        <license-card
          v-for="license in expiredLicenses"
          :key="license._id"
          class="card col-md-2"
          :total="license.maxRedeemers"
          :used="(license.redeemers || []).length"
          :start-date="license.startDate"
          :end-date="license.endDate"
          :owner="getUserById(license.creator)"
          :teacher-id="teacherId"
          :expired="true"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.licenses-page {
  display: flex;
}

.side-bar {
  background: #F2F2F2;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  width: 20%;
  padding: 30px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  margin-top: 3px;
}

.side-bar-title {
  @include font-h-4-nav-uppercase-black;
}

.side-bar-text {
  @include font-p-3-paragraph-small-gray;
  color: $pitch;
  margin: 15px 0px;
}

.pdf-btn {
  align-self: center;
  margin: 10px 0px;
}

.get-licenses-btn {
  width: 100%;
  max-width: 220px;
  height: 50px;
  margin: 20px 0px;
}

.license-cards {
  width: 80%;
  padding: 30px 0px;
}

.active-licenses, .expired-licenses {
  margin: 0px 20px 30px 20px;
  span {
    @include font-h-5-button-text-black;
    color: $twilight;
    text-align: left;
  }
}
.card  {
  margin: 10px;
}
</style>
