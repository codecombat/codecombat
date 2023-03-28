<template>
  <div class="calendar-panel">
    <client-calendar v-if="type==='my-classes'" :events="eventsArray" />
    <single-calendar v-else :events="eventsArray" />
  </div>
</template>

<script>
import SingleCalendar from './SingleCalendar'
import ClientCalendar from './ClientCalendar'
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
    SingleCalendar,
    ClientCalendar
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
