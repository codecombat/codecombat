<template>
  <div class="event-calendar">
    <secondary-nav
      :title-i18n="nav.titleI18n"
      :urls="nav.urls"
    />
    <div
      class="container body"
      :class="{'trans-left': sidePanelOpen}"
    >
      <calendar-panel
        class="calendar"
        :type="eventType"
      />
    </div>
    <event-panel />
  </div>
</template>

<script>
import CalendarPanel from './components/CalendarPanel'
import SecondaryNav from '../../components/common/SecondaryNav'
import EventPanel from './components/EventPanel'
import { mapGetters } from 'vuex'

export default {
  name: 'EventIndex',
  components: {
    CalendarPanel,
    SecondaryNav,
    EventPanel
  },
  props: {
    eventType: {
      type: String,
      default: ''
    }
  },
  computed: {
    ...mapGetters({
      sidePanelOpen: 'events/eventPanelVisible'
    })
  },
  data () {
    return {
      nav: {
        titleI18n: 'events.dashboard',
        urls: [
          { url: '/event-calendar/classes', action: 'Event Nav Click Online Classes', i18n: 'events.online_classes' },
          { url: '/event-calendar/my-classes', action: 'Event Nav Click My Classes', i18n: 'events.my_classes' }
        ]
      }
    }
  },
  mounted () {
    console.log('event type:', this.eventType)
    if (!this.eventType) {
      if (me.isStudent()) {
        application.router.navigate('/event-calendar/classes', { trigger: true })
      }
    }
  }
}
</script>

<style lang="scss" scoped>
$width: min(40vw, 800px);

.body {
  display: flex;

  &.trans-left {
    max-width: 60vw;
    margin-right: $width;
  }

  .calendar {
    flex-grow: 1;
  }
}
</style>
