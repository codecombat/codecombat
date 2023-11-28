<template>
  <div
    class="content"
  >
    <div class="calendar">
      <div class="calendar__panel body-bg">
        <calendar-panel
          :type="'my-classes'"
          :user-id="child._id"
        />
      </div>
      <div class="board" />
    </div>
    <div class="policy body-bg">
      <footer-component />
    </div>
  </div>
</template>

<script>
import CalendarPanel from '../../events/components/CalendarPanel'
import FooterComponent from './FooterComponent'
export default {
  name: 'BodyComponent',
  components: {
    CalendarPanel,
    FooterComponent
  },
  props: {
    child: {
      type: Object
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.content {
  display: grid;
  grid-template-rows: 2fr;
  grid-row-gap: 3rem;

  background: $color-grey-2;
  padding: 4rem;

  .body-bg {
    background: $color-white;
    box-shadow: -1px 0px 1px 0px rgba(0, 0, 0, 0.06), 3px 0px 8px 0px rgba(0, 0, 0, 0.15);
  }

  .calendar {
    display: grid;
    grid-template-columns: 4fr 1fr;

    &__panel {

    }
  }
}
</style>
