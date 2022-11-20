<template>
  <div id="calendar" />
</template>

<script>
import Calendar from '@event-calendar/core'
import DayGrid from '@event-calendar/day-grid'

export default {
  name: 'SingleCalendar',
  props: {
    events: {
      type: Array,
      default: () => []
    }
  },
  data () {
    return {
      ec: null
    }
  },
  computed: {
    calendarOptions () {
      return {
        view: 'dayGridMonth',
        events: this.events
      }
    }
  },
  mounted () {
    this.ec = new Calendar({
      target: document.querySelector('#calendar'),
      props: {
        plugins: [DayGrid],
        options: this.calendarOptions
      }
    })
  }
}
</script>

<style lang="scss" scoped>
@import '~node_modules/@event-calendar/core/index.css';
#calendar {
}
</style>
