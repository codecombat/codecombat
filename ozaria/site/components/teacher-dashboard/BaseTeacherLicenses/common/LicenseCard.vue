
<script>
import moment from 'moment'
import IconButtonWithText from '../../common/buttons/IconButtonWithText'
const utils = require('core/utils')

export default {
  components: {
    IconButtonWithText,
  },
  props: {
    total: {
      type: Number,
      required: true,
    },
    used: {
      type: Number,
      required: true,
    },
    startDate: {
      type: String,
      required: true,
    },
    endDate: {
      type: String,
      required: true,
    },
    owner: {
      type: Object,
      default: () => {},
    },
    teacherId: {
      type: String,
      required: true,
    },
    expired: {
      type: Boolean,
      default: false,
    },
    displayOnly: {
      type: Boolean,
      default: false,
    },
    properties: {
      type: Object,
      default: () => {},
    },
    includedCourseIds: {
      type: Array,
      default: () => [],
    },
    disableApplyLicenses: {
      type: Boolean,
      default: false,
    },
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
      return this.disableApplyLicenses || this.displayOnly || this.expired || this.remaining === 0
    },
    shareLicensesDisabled () {
      return this.displayOnly || this.expired || !this.isLicenseOwner
    },
    applyLicensesIcon () {
      if (this.applyLicensesDisabled) {
        return 'IconApplyLicenses_Black'
      } else {
        return 'IconApplyLicenses_White'
      }
    },
    shareLicensesIcon () {
      if (this.shareLicensesDisabled) {
        return 'IconShare_Black'
      } else {
        return 'IconShare_White'
      }
    },
    licenseStatsIcon () {
      return 'IconLicense_White'
    },
    testStudentOnly () {
      return this.properties?.testStudentOnly
    },
    customizedLicense () {
      return !!this.includedCourseIds?.length
    },
    hackstackLicense () {
      const includedCourseIds = this.includedCourseIds
      const credit = this.properties?.creditDetails
      return credit && includedCourseIds?.length === 1 && includedCourseIds[0] === utils.courseIDs.HACKSTACK
    },
    licenseName () {
      if (this.customizedLicense) {
        if (this.hackstackLicense) {
          return $.i18n.t('teacher.hackstack_license')
        }
        return $.i18n.t('teacher.customized_license')
      } else {
        return $.i18n.t('teacher.full_license')
      }
    },
    licenseDescription () {
      if (this.customizedLicense) {
        if (this.hackstackLicense) {
          const credit = this.properties?.creditDetails
          const payload = {
            ...credit,
            durationKey: $.i18n.t('user_credits.level_chat_duration_' + credit.durationKey),
          }
          return $.i18n.t('teacher.hackstack_credits', payload)
        }
        return (this.includedCourseIds.map(id => utils.courseAcronyms[id])).join(' ')
      } else {
        return ''
      }
    },
  },
}
</script>

<template>
  <div class="license-card">
    <div
      class="license-info"
      :class="{ 'expired': expired }"
    >
      <div class="used">
        <div>
          {{
            $t('teacher_dashboard.license_ratio_used', {
              totalUsedLicenses: used,
              totalSpots: total
            })
          }}
        </div>
        <div class="sub-text">
          {{ $t('teacher_dashboard.licenses_applied') }}
        </div>
        <div class="special">
          <div v-if="testStudentOnly">
            {{ $t('teacher_dashboard.test_student_only') }}
          </div>
          <div class="license-name">
            {{ licenseName }}
          </div>
          <div class="license-description">
            {{ licenseDescription }}
          </div>
        </div>
      </div>
      <div class="remaining">
        {{ $t('teacher_dashboard.remaining_licenses', { remaining }) }}
      </div>
      <div class="dates">
        <div>{{ $t('teacher_dashboard.start_date', { date: startDateFormat }) }}</div>
        <div>{{ $t('teacher_dashboard.end_date', { date: endDateFormat }) }}</div>
      </div>
    </div>
    <div
      class="buttons"
      :class="{ 'expired': expired }"
    >
      <icon-button-with-text
        class="icn-button"
        :icon-name="applyLicensesIcon"
        :text="$t('teacher.apply_licenses')"
        :inactive="applyLicensesDisabled"
        @click="$emit('apply')"
      />
      <icon-button-with-text
        class="icn-button"
        :icon-name="shareLicensesIcon"
        :text="$t('share_licenses.share_licenses')"
        :inactive="shareLicensesDisabled"
        @click="$emit('share')"
      />
      <icon-button-with-text
        class="icn-button"
        :icon-name="licenseStatsIcon"
        :text="$t('teacher.license_stats')"
        @click="$emit('stats')"
      />
    </div>
    <div
      v-if="!isLicenseOwner"
      class="shared-by"
    >
      {{ $t('share_licenses.shared_by') }} <a :href="'mailto:'+licenseOwnerEmail"> {{ licenseOwnerEmail }} </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "app/styles/component_variables.scss";

.license-card {
  width: auto;
  height: auto;
}

.license-info {
  background: $middle-purple;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  border-radius: 24px 24px 0px 0px;
  width: 300px;
  height: auto;
  padding: 30px;

  &.expired {
    background: $light-purple;
  }
}

.used {
  @include font-h-2-subtitle-black;
  color: $purple;
  text-align: center;
  .sub-text {
    font-size: 18px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
  }
}

.remaining {
  @include font-p-4-paragraph-smallest-gray;
  color: $dark-grey-2;
  text-align: center;
  margin: 30px 0px 20px 0px;
  font-weight: 600;
}

.expired {
  .used {
    color: $purple-2;
  }

  .remaining {
    color: $dark-grey;
  }
}

.special {
  font-size: 14px;
  line-height: 14px;
  text-align: center;
  height: 20px;
}

.dates {
  font-family: Work Sans;
  font-size: 12px;
  line-height: 14px;
  text-align: center;
  color: $dark-grey-2;
}

.buttons {
  background: $purple;
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
    background: $purple-2;
  }
}

.icn-button {
  margin: 5px;

  ::v-deep span {
     color: $light-background;
  }

  &.disabled {
    ::v-deep span {
      color: $dark-grey-2;
    }
  }
}

.shared-by {
  @include font-p-4-paragraph-smallest-gray;
  text-align: center;
  margin-top: 10px;
  width: 300px;
}
</style>
