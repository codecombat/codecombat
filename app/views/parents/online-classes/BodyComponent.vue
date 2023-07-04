<template>
  <div
    class="content"
  >
    <div class="calendar">
      <div class="calendar__panel">
        <calendar-panel
          :type="'my-classes'"
          :user-id="child._id"
        />
      </div>
    </div>
    <div class="board">
    </div>
  </div>
</template>

<script>
import CalendarPanel from '../../events/components/CalendarPanel'
export default {
  name: 'BodyComponent',
  props: {
    child: {
      type: Object
    }
  },
  components: {
    CalendarPanel
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.content {
  display: grid;
  grid-template-columns: 4fr 1fr;
  background: $color-grey-2;
  padding: 4rem;

  .calendar {
    &__panel {
      background: $color-white;
      box-shadow: -1px 0p 1px 0 rgba(0, 0, 0, 0.06), 3px 0px 8px 0px rgba(0, 0, 0, 0.15);
    }
  }
}
</style>
