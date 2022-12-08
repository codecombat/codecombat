<template>
  <div class="calendar-panel">
    <single-calendar :events="myEvents" />
  </div>
</template>

<script>
import SingleCalendar from './SingleCalendar'
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'CalendarPanel',
  props: {
    type: {
      type: String,
      default: 'classes'
    }
  },
  components: {
    SingleCalendar
  },
  computed: {
    ...mapGetters({
      myEvents: 'events/myEventInstances'
    })
  },
  mounted () {
    if (!this.myEvents.length) {
      this.fetchAllEvents()
    }
  },
  methods: {
    ...mapActions({
      fetchAllEvents: 'events/fetchAllEvents'
    })
  }
}
</script>

<style lang="scss" scoped>
@import '~node_modules/@event-calendar/core/index.css';
#calendar {
}
</style>
