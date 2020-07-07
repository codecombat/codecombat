
<script>
  import LicenseCard from './common/LicenseCard'
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import { mapGetters } from 'vuex'
  import ButtonResourceIcon from '../BaseResourceHub/components/ButtonResourceIcon'

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
      })
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
        icon="PDF"
        label="Licenses How-To Guide"
      />
      <div class="side-bar-text">
        Need more licenses? We'll help you build a solution that meets your needs.
      </div>
      <primary-button
        class="get-licenses-btn"
        @click="$emit('getLicenses')"
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
}

.get-licenses-btn {
  width: 100%;
  max-width: 220px;
  height: 50px;
  margin: 20px 0px;
}

.license-cards {
  width: 80%;
}

.active-licenses, .expired-licenses {
  margin-left: 20px;
  span {
    @include font-h-5-button-text-black;
    color: $twilight;
    text-align: left;
    margin-top: 10px;
  }
}
.card  {
  margin: 10px;
  width: auto;
}
</style>
