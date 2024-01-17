<template>
  <div
    class="stats"
    :class="{ printing: printing }"
  >
    <stat-item-component
      img-path="/images/pages/library/icon-users.png"
      :name="$t('library.total_users')"
      :value="totalUsers"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-code.png"
      :name="$t('library.lines_of_code_written')"
      :value="linesOfCode"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-hours.png"
      :name="$t('library.hours_spent')"
      :value="Math.round(minutesSpent / 60)"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-programs.png"
      :name="$t('library.levels_completed')"
      :value="programsWritten"
    />
  </div>
</template>

<script>
import StatItemComponent from './StatItemComponent'
export default {
  name: 'StatsComponent',
  components: {
    StatItemComponent
  },
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
    },
    printing: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style scoped lang="scss">
@import "../../css-mixins/variables";
.stats {
  display: flex;
  justify-content: center;

  background: $color-yellow-3 !important;
  -webkit-print-color-adjust: exact !important;
  padding: 2rem;

  &.printing {
    max-width: 1024px;
  }
}
</style>
