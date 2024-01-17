<template>
  <div class="ldata">
    <filter-component
      :initial-start-date="startDate"
      :initial-end-date="endDate"
      :printing="printing"
      @startDateChanged="(start) => $emit('startDateChanged', start)"
      @endDateChanged="(end) => $emit('endDateChanged', end)"
    />
    <stats-component
      v-if="!loading"
      :total-users="totalUsers"
      :lines-of-code="linesOfCode"
      :minutes-spent="minutesSpent"
      :programs-written="programsWritten"
    />
    <graph-component
      v-if="!loading"
      :stats="stats"
    />
    <div
      v-if="loading"
      class="loading"
    >
      {{ $t('library.loading_from') }} {{ startDate }} to {{ endDate }}.....
    </div>
    <div
      class="ldata__old"
    >
      {{ $t('library.access_old_dashboard') }} <a
        href="/api-dashboard?fromNew=1"
        target="_blank"
        class="ldata__link"
      >{{ $t('general.here') }}</a>
    </div>
  </div>
</template>

<script>
import FilterComponent from './helpers/FilterComponent'
import GraphComponent from './helpers/GraphComponent'
import StatsComponent from './helpers/StatsComponent'

export default {
  name: 'LibraryDataComponent',
  components: {
    FilterComponent,
    GraphComponent,
    StatsComponent
  },
  props: {
    startDate: {
      type: String
    },
    endDate: {
      type: String
    },
    stats: {
      type: Object
    },
    loading: {
      type: Boolean,
      default: true
    },
    printing: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    totalUsers () {
      return this.stats?.totalUsers
    },
    linesOfCode () {
      let lines = 0
      for (const month in this.stats?.licenseDaysByMonth) {
        const val = this.stats?.licenseDaysByMonth[month]
        lines += val?.progress?.linesOfCode || 0
      }
      return lines
    },
    minutesSpent () {
      let minutes = 0
      for (const month in this.stats?.licenseDaysByMonth) {
        const val = this.stats?.licenseDaysByMonth[month]
        minutes += Math.round((val?.progress?.playtime || 0) / 60)
      }
      return minutes
    },
    programsWritten () {
      let programs = 0
      for (const month in this.stats?.licenseDaysByMonth) {
        const val = this.stats?.licenseDaysByMonth[month]
        programs += val?.progress?.programs || 0
      }
      return programs
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.ldata {
  grid-column: main-content-start / main-content-end;

  .loading {
    text-align: center;
    font-size: 2rem;
    padding: 1rem;
  }

  &__old {
    background: $color-blue-1;
    color: $color-yellow-1;

    padding: 5px;
    font-size: 1.4rem;
  }

  &__link {
    color: $color-white;
  }
}

@media print {
  .ldata__old {
    display: none;
  }
}
</style>
