
<script>
  import moment from 'moment'
  import IconButtonWithText from '../../common/buttons/IconButtonWithText'
  export default {
    components: {
      IconButtonWithText
    },
    props: {
      total: {
        type: Number,
        required: true
      },
      used: {
        type: Number,
        required: true
      },
      startDate: {
        type: String,
        required: true
      },
      endDate: {
        type: String,
        required: true
      },
      owner: {
        type: Object,
        default: () => {}
      },
      teacherId: {
        type: String,
        required: true
      },
      expired: {
        type: Boolean,
        default: false
      }
    },
    computed: {
      remaining () {
        return this.total - this.used
      },
      startDateFormat () {
        return moment(this.startDate).format('ll')
      },
      endDateFormat () {
        return moment(this.endDate).format('ll')
      },
      licenseOwnerEmail () {
        return (this.owner || {}).email
      },
      isLicenseOwner () {
        return !this.owner || this.owner._id === this.teacherId
      },
      applyLicensesDisabled () {
        return this.expired || this.remaining === 0
      },
      shareLicensesDisabled () {
        return this.expired || !this.isLicenseOwner
      },
      applyLicensesIcon () {
        if (this.applyLicensesDisabled) {
          return 'IconApplyLicenses_Gray'
        } else {
          return 'IconApplyLicenses_Dusk'
        }
      },
      shareLicensesIcon () {
        if (this.shareLicensesDisabled) {
          return 'IconShare_Gray'
        } else {
          return 'IconShare_Dusk'
        }
      }
    }
  }
</script>

<template>
  <div class="license-card">
    <div
      class="license-info"
      :class="{ 'expired': expired }"
    >
      <div class="used">
        <div> {{ used }} out of {{ total }} </div>
        <div class="sub-text"> licenses applied </div>
      </div>
      <div class="remaining">
        {{ remaining }} license(s) remaining
      </div>
      <div class="dates">
        <div> Start: {{ startDateFormat }} </div>
        <div> End: {{ endDateFormat }} </div>
      </div>
    </div>
    <div
      class="buttons"
      :class="{ 'expired': expired }"
    >
      <icon-button-with-text
        class="icn-button"
        :icon-name="applyLicensesIcon"
        text="Apply Licenses"
        :inactive="applyLicensesDisabled"
        @click="$emit('apply')"
      />
      <icon-button-with-text
        class="icn-button"
        :icon-name="shareLicensesIcon"
        text="Share Licenses"
        :inactive="shareLicensesDisabled"
        @click="$emit('share')"
      />
    </div>
    <div
      v-if="!isLicenseOwner"
      class="shared-by"
    >
      Shared by: <a :href="'mailto:'+licenseOwnerEmail"> {{ licenseOwnerEmail }} </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.license-card {
  width: auto;
  height: auto;
}

.license-info {
  background: #355EA0;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  border-radius: 24px 24px 0px 0px;
  width: 300px;
  height: auto;
  padding: 30px;

  &.expired {
    background: #6D8392;
  }
}

.used {
  @include font-h-2-subtitle-black;
  color: $moon;
  text-align: center;
  .sub-text {
    font-size: 18px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
  }
}

.remaining {
  @include font-p-4-paragraph-smallest-gray;
  color: #FFFFFF;
  text-align: center;
  margin: 10px 0px 20px 0px;
  font-weight: 600;
}

.dates {
  font-family: Work Sans;
  font-size: 12px;
  line-height: 14px;
  text-align: center;
  color: #FFFFFF;
}

.buttons {
  background: #20498A;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  border-radius: 0px 0px 24px 24px;
  width: 300px;
  height: 87px;
  padding: 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;

  &.expired {
    background: #526979;
  }
}

.icn-button {
  margin: 5px;
}

.shared-by {
  @include font-p-4-paragraph-smallest-gray;
  text-align: center;
  margin-top: 10px;
  width: 300px;
}
</style>
