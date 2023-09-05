<template>
  <div class="stats">
    <stat-item-component
      img-path="/images/pages/library/icon-users.png"
      name="Total Users"
      :value="totalUsers"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-code.png"
      name="Lines of code written"
      :value="linesOfCode"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-hours.png"
      name="Hours spent"
      :value="Math.round(minutesSpent / 60)"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-programs.png"
      name="Programs written"
      :value="programsWritten"
    />
  </div>
</template>

<script>
import StatItemComponent from './StatItemComponent'
export default {
  name: 'StatsComponent',
  props: {
    totalUsers: {
      type: Number
    },
    linesOfCode: {
      type: Number
    },
    minutesSpent: {
      type: Number
    },
    programsWritten: {
      type: Number
    }
  },
  components: {
    StatItemComponent
  }
}
</script>

<style scoped lang="scss">
@import "../../css-mixins/variables";
.stats {
  display: flex;
  justify-content: center;

  background: $color-yellow-3;
  padding: 2rem;
}
</style>
