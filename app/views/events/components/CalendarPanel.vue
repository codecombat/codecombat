<template>
  <div class="calendar-panel">
    <client-calendar v-if="type==='my-classes'" :events="eventsArray" />
    <classes-stats
      v-if="type==='classes-stats'"
      :events="eventsArray"
    />
    <single-calendar
      v-if="type==='classes'"
      :events="eventsArray"
    />
  </div>
</template>

<script>
import SingleCalendar from './SingleCalendar'
import ClientCalendar from './ClientCalendar'
import ClassesStats from './ClassesStats'
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'CalendarPanel',
  components: {
    SingleCalendar,
    ClientCalendar,
    ClassesStats
  },
  props: {
    type: {
      type: String,
      default: 'classes'
    }
  },
  computed: {
    ...mapGetters({
      events: 'events/events'
    }),
    eventsArray () {
      return Object.values(this.events)
    }
  },
  mounted () {
    if (!this.eventsArray.length) {
      if (me.isStudent()) {
        this.fetchUserEvents(me.id)
      } else {
        this.fetchAllEvents()
      }
    }
  },
  methods: {
    ...mapActions({
      fetchAllEvents: 'events/fetchAllEvents',
      fetchUserEvents: 'events/fetchUserEvents'
    })
  }
}
</script>

<style lang="scss" scoped>
@import '~node_modules/@event-calendar/core/index.css';
</style>
