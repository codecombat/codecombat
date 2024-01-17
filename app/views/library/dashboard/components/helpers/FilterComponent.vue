<template>
  <div class="filter">
    <img
      src="/images/pages/library/user-activity.png"
      alt="User activity"
      class="filter__img"
    >
    <div class="filter__text">
      {{ $t('library.user_activities') }} | <span class="filter__subtext">{{ $t('general.from') }}:</span>
    </div>
    <div class="filter__dates">
      <div
        v-if="printing"
        class="filter__date printing"
      >
        {{ startDate }}
      </div>
      <input
        v-else
        v-model="startDate"
        type="date"
        class="filter__date"
        :max="endDate"
      >
      <span class="filter__to">To:</span>
      <div
        v-if="printing"
        class="filter__date printing"
      >
        {{ endDate }}
      </div>
      <input
        v-else
        v-model="endDate"
        type="date"
        class="filter__date"
        :min="startDate"
        :max="currentDate"
      >
    </div>
  </div>
</template>

<script>
import moment from 'moment'
export default {
  name: 'FilterComponent',
  props: {
    initialStartDate: {
      type: String
    },
    initialEndDate: {
      type: String
    },
    printing: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      startDate: this.initialStartDate,
      endDate: this.initialEndDate,
      currentDate: moment().format('YYYY-MM-DD')
    }
  },
  watch: {
    startDate () {
      this.$emit('startDateChanged', this.startDate)
    },
    endDate () {
      this.$emit('endDateChanged', this.endDate)
    }
  }
}
</script>

<style scoped lang="scss">
@import "../../css-mixins/variables";
.filter {
  display: flex;
  background: $color-yellow-1 !important;
  -webkit-print-color-adjust: exact !important;
  padding: 2rem;

  font-feature-settings: 'clig' off, 'liga' off;
  font-family: Work Sans, serif;
  font-style: normal;
  line-height: 2.4rem; /* 171.429% */
  letter-spacing: 0.44px;
  font-weight: 400;

  &__img {
    height: 2.5rem;
    margin-right: 1rem;
  }

  &__text {
    color: $color-blue-2;
    font-size: 1.8rem;
    font-weight: 700;
    margin-right: 1rem;
  }

  &__subtext {
    font-weight: 400;
  }

  &__date {
    position: relative;
    top: -3px;

    color: $color-dark-grey-1;
    font-size: 1.4rem;
  }

  &__to {
    color: $color-blue-2;
    font-size: 1.8rem;

    margin-left: 5px;
    margin-right: 5px;
  }
}

@media print {
  .filter {
    width: 1024px !important;

    &__date.printing {
      display: inline-block;
      font-size: 2rem;
      font-weight: 600;
    }
  }
}
</style>
