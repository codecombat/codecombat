<template>
  <div class="timeInfo">
    <div class="calendar">
      <stylish-calendar
        :events="events"
        @event-click="selectDate"
      />
    </div>
    <div class="times">
      <div
        v-for="t in times"
        :key="t.format('LT')"
        class="radio"
      >
        <label>
          <input
            v-model="time"
            name="time"
            type="radio"
            :value="t.get('hour') + t.get('minute') / 60"
          >
          <span> {{ t.format('LT') }}</span>
        </label>
      </div>
    </div>
    <div class="buttons">
      <button
        class="btn btn-secondary"
        @click="back"
      >
        Back
      </button>
      <button
        class="btn btn-primary"
        :disabled="time === null"
        @click="emitInfo"
      >
        Continue
      </button>
    </div>
  </div>
</template>

<script>
import { fetchAvailableTime } from '../../../core/api/online-classes'
import StylishCalendar from '../../events/components/StylishCalendar'
import moment from 'moment-timezone'

export default {
  name: 'AvailableTime',
  components: {
    StylishCalendar
  },
  props: {
    classInfo: {
      type: Object,
      required: true
    },
    serverTz: {
      type: String,
      required: true
    },
    userTz: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      events: [],
      times: [],
      allTimes: [],
      time: null,
      date: null
    }
  },
  mounted () {
    this.checkTime()
  },
  methods: {
    back () {
      this.$emit('back')
    },
    getDates () {
      const dates = new Set()
      this.allTimes.forEach(t => {
        dates.add(t.format('YYYY-MM-DD'))
      })
      return Array.from(dates)
    },
    toServerDateTime (date, time) {
      const serverTime = moment.tz(date, this.userTz).set({
        hour: Math.floor(time),
        minute: Math.floor((time - Math.floor(time)) * 60),
        second: 0,
        millisecond: 0
      }).tz(this.serverTz)
      return [serverTime.format('YYYY-MM-DD'), serverTime.get('hour') + serverTime.get('minute') / 60]
    },
    emitInfo () {
      const [serverDate, serverTime] = this.toServerDateTime(this.date, this.time)
      this.$emit('next', { date: serverDate, time: serverTime })
    },
    async checkTime () {
      try {
        const times = await fetchAvailableTime(this.classInfo)
        if (times.length === 0) {
          window.noty({
            type: 'warning',
            text: 'Sorry, no available time for this class, please select another one.',
            timeout: 5000,
            layout: 'center'
          })
          this.$emit('back')
        }
        this.allTimes = this.convertTimeToLocaleTime(times)
        this.events = this.getDates().map((d, i) => this.formatEvent(d, i))
      } catch (e) {
        console.error(e)
      }
    },
    convertTimeToLocaleTime (times) {
      const localeTime = []
      times.forEach(t => {
        t.times.forEach(ti => {
          localeTime.push(moment.tz(t.date, this.serverTz).set({
            hour: Math.floor(ti),
            minute: Math.floor((ti - Math.floor(ti)) * 60),
            second: 0,
            millisecond: 0
          }).tz(this.userTz))
        })
      })
      return localeTime
    },
    formatEvent (date, index) {
      return {
        id: 'available-time-' + index,
        start: new Date(date),
        end: new Date(date),
        title: '',
        extendedProps: date,
      }
    },
    getTimesIDay () {
      if (this.date) {
        return this.allTimes.filter(t => t.format('YYYY-MM-DD') === this.date)
      } else {
        return []
      }
    },
    selectDate (info) {
      this.date = info.event.extendedProps
      this.times = this.getTimesIDay()
      this.time = null
    }
  },
}
</script>
<style lang="scss" scoped>
@import "common";
.timeInfo {
  min-width: 600px;
  display: flex;
  flex-direction: column;
  align-items: center;

  .calendar {
    min-width: 600px;
  }
  .times {
    display: flex;
    flex-wrap: wrap;
    .radio {
      margin-top: 0;
      flex-basis: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
  }

}
</style>
