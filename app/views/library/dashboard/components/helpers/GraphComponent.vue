<template>
  <div class="graphs">
    <div class="graphs__item">
      <div class="graphs__heading">
        Number of users
      </div>
      <d3-line-chart
        :config="usersChartConfig"
        :datum="usersChartData"
      />
    </div>
    <div class="graphs__item">
      <div class="graphs__heading">
        Time spent
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
        :config="usersChartConfig"
        :datum="usersChartData"
      />
    </div>
    <div class="graphs__item">
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
        :config="linesOfCodeConfig"
        :datum="linesOfCodeData"
      />
    </div>
  </div>
</template>

<script>
import { D3LineChart, D3BarChart, D3PieChart } from 'vue-d3-charts'
export default {
  name: 'GraphComponent',
  components: {
    D3LineChart,
    D3BarChart,
    D3PieChart
  },
  data () {
    return {
      usersChartData: [
        { number_of_users: 23, date: '2023-01' },
        { number_of_users: 123, date: '2023-02' },
        { number_of_users: 413, date: '2023-03' },
        { number_of_users: 234, date: '2023-04' },
        { number_of_users: 523, date: '2023-05' }
      ],
      usersChartConfig: {
        values: ['number_of_users'],
        date: {
          key: 'date',
          inputFormat: '%Y-%m',
          outputFormat: '%Y-%m'
        }
      },
      timeSpentData: [
        { time_spent: 23, date: '2023-01' },
        { time_spent: 423, date: '2023-02' },
        { time_spent: 13, date: '2023-03' },
        { time_spent: 234, date: '2023-04' }
      ],
      timeSpentConfig: {
        values: ['time_spent'],
        key: 'date'
      },
      ageData: [
        { name: 'Under 15', count: 12 },
        { name: '15 < age < 18', count: 25 },
        { name: 'Greater than 18', count: 35 }
      ],
      ageConfig: {
        key: 'name',
        value: 'count',
        color: { scheme: 'schemeTableau10' },
        radius: { inner: 80 }
      },
      linesOfCodeData: [
        { time_spent: 23, date: '2023-01' },
        { time_spent: 423, date: '2023-02' },
        { time_spent: 13, date: '2023-03' },
        { time_spent: 234, date: '2023-04' }
      ],
      linesOfCodeConfig: {
        values: ['time_spent'],
        key: 'date',
        orientation: 'horizontal',
        color: {
          keys: {
            time_spent: '#0E4C60'
          }
        }
      }
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
    }
  }
}
</style>
