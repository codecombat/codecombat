<template>
  <div class="calendar-panel">
    <client-calendar v-if="type==='my-classes'" :events="eventsArray" />
    <classes-stats
      v-if="type==='classes-stats'"
      :events="eventsArray"
    />
    <template v-if="type === 'classes'">
      <single-calendar
        :events="eventsArray"
      />
      <div class="calendar-panel__link-google">
        <input
          v-if="shouldShowLinkGoogle"
          type="button"
          :value="$t('events.link_google_calendar')"
          :disabled="linkGoogleDisabled"
          @click="linkGoogleCalendar"
        >

        <input
          v-if="false && me.useGoogleCalendar()"
          type="button"
          :value="$t('events.sync_google_calendar')"
          @click="syncGoogleCalendar"
        >
      </div>
    </template>
  </div>
</template>

<script>
import SingleCalendar from './SingleCalendar'
import ClientCalendar from './ClientCalendar'
import ClassesStats from './ClassesStats'
import { mapActions, mapGetters } from 'vuex'
import gcApiHandler from '../../../core/social-handlers/GoogleCalendarHandler'

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
      default: ''
    }
  },
  computed: {
    ...mapGetters({
      events: 'events/events'
    }),
    eventsArray () {
      return Object.values(this.events)
    },
    me () {
      return me
    },
    shouldShowLinkGoogle () {
      return (me.isAdmin() || me.isOnlineTeacher()) && !me.get('gplusID')
    }
  },
  data: function () {
    return {
      linkGoogleDisabled: true
    }
},
  mounted () {
    console.log('mount calendar panel', this.type)
    if (!this.type) {
      return
    }
    if (!this.eventsArray.length) {
      if (me.isStudent()) {
        this.fetchUserEvents(me.id)
      } else {
        this.fetchAllEvents()
      }
    }
    application.gplusHandler?.loadAPI({
      success: () => (this.linkGoogleDisabled = false)
    })
  },
  methods: {
    ...mapActions({
      fetchAllEvents: 'events/fetchAllEvents',
      fetchUserEvents: 'events/fetchUserEvents'
    }),
    linkGoogleCalendar () {
      application.gplusHandler.connect({
        success: (resp = {}) =>
          application.gplusHandler.loadPerson({
            resp,
            success: (gplusAttrs) =>
              me.linkGPlusUser(gplusAttrs.gplusID, gplusAttrs.email, {
                success: () => {
                  application.tracker.identifyAfterNextPageLoad()
                  application.tracker.identify().finally(() =>
                    noty({ text: $.i18n.t('login.gplus_linked'), layout: 'topCenter', type: 'success' })
                  )
                  window.location.reload()
                },
                error: (res, jqxhr) =>
                  noty({ text: $.i18n.t('login.gplus_link_error'), layout: 'topCenter', type: 'error' })
              })
          })
      })
    },
    syncGoogleCalendar () {
      gcApiHandler.importEvents().then((res) => {
        console.log(res)
      })
    },
  }
}
</script>

<style lang="scss" scoped>
@import '~node_modules/@event-calendar/core/index.css';
</style>
