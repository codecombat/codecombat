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
        class="btn btn-primary"
        @click="back"
      >
        Back
      </button>
      <button
        class="btn btn-primary"
        @click="emitInfo"
      >
        Next
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
      const times = await fetchAvailableTime(this.classInfo)
      this.events = times.map((t, i) => this.formatEvent(t, i))
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
.timeInfo {
  width: 800px;
  display: flex;
  flex-direction: column;
  align-items: center;

  .calendar {
    width: 500px;
  }
  .times {
    align-self: flex-start;
  }

}
</style>