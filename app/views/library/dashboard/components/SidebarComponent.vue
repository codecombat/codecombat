<template>
  <div class="sidebar">
    <div class="sidebar__img">
      <img
        v-if="imagePath"
        :src="`/images${imagePath}`"
        alt="Library logo"
      />
    </div>
    <div
      v-if="totalLicensesUsed"
      class="sidebar__licenses"
    >
      <div class="sidebar__licenses__container">
        <div class="sidebar__licenses__text sidebar__text">
          {{ $t('library.total_licenses_used') }}:
        </div>
        <div
          class="sidebar__text sidebar__subtext"
        >
          *{{ $t('library.from_launch_date') }}
        </div>
      </div>
      <div class="sidebar__licenses__number sidebar__value">
        {{ totalLicensesUsed }}
      </div>
    </div>
    <div
      v-if="renewalDate"
      class="sidebar__renewal"
    >
      <div class="sidebar__renewal__text sidebar__text">
        {{ $t('library.renewal_date') }}:
      </div>
      <div
        class="sidebar__renewal__date sidebar__value"
      >
        {{ renewalDate }}
      </div>
    </div>
  </div>
</template>

<script>
import moment from 'moment'
export default {
  name: 'SidebarComponent',
  props: {
    stats: {
      type: Object
    }
  },
  computed: {
    totalLicensesUsed () {
      return this.stats?.totalLicensesUsed
    },
    imagePath () {
      return this.stats?.info?.imagePath
    },
    renewalDate () {
      const dt = this.stats?.info?.endDate
      return dt ? moment(dt).format('LL') : null
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";

.sidebar {
  grid-column: sidebar-start / sidebar-end;

  display: flex;
  flex-direction: column;
  padding: 2rem;
  box-shadow: 0 0 20px 0 rgba(0, 0, 0, 0.20);

  &__img {
    align-self: center;
    img {
      width: 12rem;
    }
  }

  &__licenses {
    &::after {
      content: "";
      height: 1px;
      background: $color-yellow-1;
      display: block;
      width: 100%;
      margin-top: 1rem;
    }
  }

  &__text {
    font-feature-settings: 'clig' off, 'liga' off;
    font-size: 1.4rem;
    font-style: normal;
    font-weight: 400;
    line-height: 1.8rem; /* 128.571% */
    letter-spacing: 0.4px;
    text-transform: uppercase;
  }

  &__subtext {
    font-size: 1rem;
    color: $color-dark-grey-1;
  }

  &__value {
    color: $color-blue-2;
    font-family: Space Mono, sans-serif;
    font-size: 3.5rem;
    font-style: normal;
    font-weight: 700;
    line-height: normal;
  }

  & > div {
    margin-bottom: 4rem;
  }
}
</style>
