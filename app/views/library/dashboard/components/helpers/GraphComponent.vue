<template>
  <div class="graphs">
    <div class="graphs__item">
      <div class="graphs__heading">
        Number of users
      </div>
      <d3-line-chart
        :config="usersChartConfig"
        :datum="numberOfUsersData"
      />
    </div>
    <div class="graphs__item">
      <div class="graphs__heading">
        Time spent (in minutes)
      </div>
      <d3-bar-chart
        :config="timeSpentConfig"
        :datum="timeSpentData"
      />
    </div>
    <div class="graphs__item">
      <div class="graphs__heading">
        New users
      </div>
      <d3-line-chart
        :config="newSignupsChartConfig"
        :datum="newSignupsData"
      />
    </div>
    <div
      v-if="ageData.length > 0"
      class="graphs__item"
    >
      <div class="graphs__heading">
        Age demographics
      </div>
      <d3-pie-chart
        :datum="ageData"
        :config="ageConfig"
      />
    </div>
    <div class="graphs__item">
      <div class="graphs__heading">
        Lines of Code Written
      </div>
      <d3-bar-chart
        :config="linesOfCodeConfig"
        :datum="linesOfCodeData"
      />
    </div>
    <div class="graphs__item">
      <div class="graphs__heading">
        Programs written
      </div>
      <d3-bar-chart
        :config="programsWrittenConfig"
        :datum="programsWrittenData"
      />
    </div>
  </div>
</template>

<script>
import { D3LineChart, D3BarChart, D3PieChart } from 'vue-d3-charts'
export default {
  name: 'GraphComponent',
  props: {
    stats: {
      type: Object
    }
  },
  components: {
    D3LineChart,
    D3BarChart,
    D3PieChart
  },
  data () {
    return {
      usersChartConfig: {
        values: ['number_of_users'],
        date: {
          key: 'date',
          inputFormat: '%Y-%m',
          outputFormat: '%Y-%m'
        },
        color: {
          scheme: ['#1FBAB4']
        }
      },
      newSignupsChartConfig: {
        values: ['new_signups'],
        date: {
          key: 'date',
          inputFormat: '%Y-%m',
          outputFormat: '%Y-%m'
        },
        color: {
          scheme: ['#20572B']
        }
      },
      timeSpentConfig: {
        values: ['time_spent'],
        key: 'date',
        color: {
          keys: {
            time_spent: '#7D0101'
          }
        }
      },
      ageConfig: {
        key: 'name',
        value: 'count',
        color: { scheme: 'schemeTableau10' },
        radius: { inner: 80 }
      },
      linesOfCodeConfig: {
        values: ['lines_of_code'],
        key: 'date',
        orientation: 'horizontal',
        color: {
          keys: {
            lines_of_code: '#0E4C60'
          }
        }
      },
      programsWrittenConfig: {
        values: ['programs_written'],
        key: 'date',
        orientation: 'horizontal',
        color: {
          keys: {
            programs_written: '#1FBAB4'
          }
        }
      }
    }
  },
  computed: {
    numberOfUsersData () {
      const arr = []
      for (const month in this.stats?.licenseDaysByMonth) {
        arr.push({ date: month, number_of_users: this.stats?.licenseDaysByMonth[month]?.noOfRedeemers })
      }
      return arr
    },
    newSignupsData () {
      const arr = []
      for (const month in this.stats?.licenseDaysByMonth) {
        arr.push({ date: month, new_signups: this.stats?.licenseDaysByMonth[month]?.newSignups })
      }
      return arr
    },
    linesOfCodeData () {
      const arr = []
      for (const month in this.stats?.licenseDaysByMonth) {
        arr.push({ date: month, lines_of_code: this.stats?.licenseDaysByMonth[month]?.progress?.linesOfCode })
      }
      return arr
    },
    programsWrittenData () {
      const arr = []
      for (const month in this.stats?.licenseDaysByMonth) {
        arr.push({ date: month, programs_written: this.stats?.licenseDaysByMonth[month]?.progress?.programs })
      }
      return arr
    },
    timeSpentData () {
      const arr = []
      for (const month in this.stats?.licenseDaysByMonth) {
        arr.push({ date: month, time_spent: (this.stats?.licenseDaysByMonth[month]?.progress?.playtime || 0) / 60 })
      }
      return arr
    },
    ageData () {
      const arr = []
      for (const ageRange in this.stats.ageStats) {
        const val = this.stats.ageStats[ageRange]
        if (val > 0) arr.push({ name: ageRange, count: val })
      }
      return arr
    }
  }
}
</script>

<style scoped lang="scss">
@import "../../css-mixins/variables";
.graphs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-column-gap: 2rem;
  grid-row-gap: 2rem;
  background: $color-grey-1;
  padding: 2rem;

  &__item {
    padding: 1rem;
    background: $color-white;

    border-radius: 1.4rem;
    border: 1px solid $color-grey-2;
    box-shadow: 0 0 2rem 0 rgba(0, 0, 0, 0.20);
  }

  &__heading {
    color: $color-blue-2;
    font-feature-settings: 'clig' off, 'liga' off;
    font-family: Work Sans, serif;
    font-size: 1.8rem;
    font-style: normal;
    font-weight: 600;
    line-height: 2.4rem; /* 133.333% */
    letter-spacing: 0.444px;
    text-transform: uppercase;

    &::after {
      content: "";
      height: 1px;
      background: $color-yellow-1;
      display: block;
      width: 100%;
      margin-top: 1rem;
    }
  }
}
</style>
