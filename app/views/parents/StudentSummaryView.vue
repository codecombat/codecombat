<template>
  <div class="summary">
    <div class="summary__stats">
      <student-stats-component />
    </div>
    <div class="child-profile">
      <child-profile-component />
    </div>
  </div>
</template>

<script>
import StudentStatsComponent from './summary/StudentStatsComponent'
import ChildProfileComponent from './summary/ChildProfileComponent'
export default {
  name: 'StudentSummaryView',
  components: {
    StudentStatsComponent,
    ChildProfileComponent
  }
}
</script>

<style scoped lang="scss">
.summary {
  grid-column: main-content-start / main-content-end;

  .child-profile {
    display: grid;
    grid-template-columns: 2fr 1fr;

    padding: 2rem;
    background: #F2F2F2;
  }
}
</style>
