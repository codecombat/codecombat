<template>
  <div
    v-if="child"
    class="summary"
  >
    <div
      class="summary__stats"
    >
      <student-stats-component
        :child="child"
      />
    </div>
    <div
      class="child-profile"
    >
      <child-profile-component
        :child="child"
        :is-paid-online-class-user="isPaidOnlineClassUser"
      />
    </div>
  </div>
  <div
    v-else
    class="empty-summary"
  >
    No child added
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
  },
  props: {
    child: {
      type: Object
    },
    isPaidOnlineClassUser: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style scoped lang="scss">
@import "css-mixins/variables";
.summary {
  grid-column: main-content-start / main-content-end;

  .child-profile {
    display: grid;
    grid-template-columns: 4fr 1fr;

    padding: 2rem;
    background: $color-grey-2;
  }
}

.empty-summary {
  grid-column: main-content-start / main-content-end;
  text-align: center;
  font-size: 3rem;
  padding: 1rem;
}
</style>
