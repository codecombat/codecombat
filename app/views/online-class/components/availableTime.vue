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
        :key="t"
        class="radio"
      >
        <label>
          <input
            v-model="time"
            name="time"
            type="radio"
            :value="t"
          >
          <span> {{ `${t}:00` }}</span>
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
        :disabled="!time"
        @click="emitInfo"
      >
        Continue
      </button>
    </div>
  </div>
</template>

<script>
import { fetchAvailableTime } from '../../../core/api/online-classes'
import StylishCalendar from '../../events/components//stylishCalendar'

export default {
  name: 'AvailableTime',
  components: {
    StylishCalendar
  },
  props: {
    classInfo: {
      type: Object,
      required: true
    }
  },
  data () {
    return {
      events: [],
      times: [],
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
    async emitInfo () {
      this.$emit('next', { date: this.date, time: this.time })
    },
    async checkTime () {
      try {
        const times = await fetchAvailableTime(this.classInfo)
        this.events = times.map((t, i) => this.formatEvent(t, i))
      } catch (e) {
        if (e.code === 404) {
          window.noty({
            type: 'warning',
            text: 'Sorry, no available time for this class, please select another one.',
            timeout: 5000,
            layout: 'center'
          })
          this.$emit('back')
        }
      }
    },
    formatEvent (time, index) {
      return {
        id: 'available-time-' + index,
        start: new Date(time.date),
        end: new Date(time.date),
        title: '',
        extendedProps: time,
      }
    },
    selectDate (info) {
      this.date = info.event.extendedProps.date
      this.times = info.event.extendedProps.times
    }
  }
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
    display: grid;
    grid-template-columns: repeat(2, 1fr);
  }

}
</style>
