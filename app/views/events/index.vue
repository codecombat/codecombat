<template>
  <div class="event-calendar">
    <calendar-panel class="calendar" />
  </div>
</template>

<script>
import CalendarPanel from './components/CalendarPanel'

export default {
  name: 'EventIndex',
  components: {
    CalendarPanel
  }
}
</script>

<style lang="scss" scoped>

.event-calendar {
  margin: 10px auto;
  max-width: 80%;

  display: flex;

  .calendar {
    flex-grow: 1
  }
}
</style>
