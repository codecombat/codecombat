<template>
  <div class="calendar-panel">
    <div id="calendar" />
    <div class="split"></div>
    <div id="event-details">
    </div>
  </div>
</template>

<script>
import Calendar from '@event-calendar/core'
import DayGrid from '@event-calendar/day-grid'
import Interaction from '@event-calendar/interaction'
import randomColor from 'randomcolor'
import { mapGetters, mapMutations } from 'vuex'

export default {
  name: 'ClientCalendar',
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
    colorMap () {
      return randomColor({
        luminosity: 'dark',
        alpha: 0.7,
        count: this.events.length
      })
    }
  },
  methods: {
    ...mapMutations({
      openEventPanel: 'events/openEventPanel'
    }),
    mapEventToCalendar (event, index) {
      return event.instances.map(instance => {
        return {
          id: instance._id?.toString(),
          start: instance.startDate,
          end: instance.endDate,
          title: event.name,
          extendedProps: event,
          backgroundColor: this.colorMap[index]
        }
      })
    },
    calendarOptions () {
      const that = this
      return {
        view: 'dayGridMonth',
        eventSources: [{ events: that.createEvents }],
        headerToolbar: { start: 'prev', center: 'title', end: 'next' },
      }
    },
    createEvents () {
      const _pad = (num) => {
        const norm = Math.floor(Math.abs(num))
        return (norm < 10 ? '0' : '') + norm
      }

      const today = new Date()
      const greyOut = {
        start: '1970-01-01',
        end: today.getFullYear() + '-' + _pad(today.getMonth() + 1) + '-' + _pad(today.getDate()),
        display: 'background',
        backgroundColor: '#f00'
      }

      return [
        { start: '2023-03-03', end: '2023-03-03', display: 'info' },
        { start: '2023-03-10', end: '2023-03-10', display: 'info' },
        { start: '2023-03-17', end: '2023-03-17', display: 'info' },
        { start: '2023-03-24', end: '2023-03-24', display: 'info' },
      ]
    }
  },
  watch: {
    events () {
      this.ec?.refetchEvents()
    }
  },
  mounted () {
    this.ec = new Calendar({
      target: document.querySelector('#calendar'),
      props: {
        plugins: [DayGrid, Interaction],
        options: this.calendarOptions()
      }
    })
  }
}
</script>

<style lang="scss" scoped>
.calendar-panel {
  box-shadow: 3px 0px 8px rgba(0, 0, 0, 0.15), -1px 0px 1px rgba(0, 0, 0, 0.06);
  border-radius: 14px;
  padding-left: 20px;
  display: flex;
  align-items: center;
}
.split {
  border: 1px solid #D8D8D8;
  box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);

  height: 570px;
  width: 0px;
  margin-left: 20px;
  margin-right: 20px;
}
#calendar {
  width: 520px;
  font-family: 'Work Sans';
  font-weight: 600;

  ::v-deep .ec-toolbar {
    border-bottom: 1px solid #d8d8d8;
    padding-bottom: 20px;
    margin-top: 50px;
    margin-bottom: 26px;

    .ec-title {
      font-size: 24px;
      line-height: 28px;
      letter-spacing: 0.56px;
      margin-bottom: 10px;
    }

    .ec-button {
      &.ec-prev, &.ec-next{
        width: 3.8em;
        height: 3.8em;
        border: unset;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        background: #476FB1;
        box-shadow: 3px 4px 6px rgba(0, 0, 0, 0.54);
      }

      .ec-icon {
        position: relative;
        width: 0;

        &.ec-prev::before {
          content: '';
          position: absolute;
          top: -1em;
          left: -1em;
          width: 1em;
          height: 2em;
          transform: unset;
          border-right: #f6d157 1em solid;
          border-top: 1em solid transparent;
          border-bottom: 1em solid transparent;
        }
        &.ec-next::before {
          content: '';
          position: absolute;
          top: -1em;
          width: 1em;
          height: 2em;
          transform: unset;
          border-left: #f6d157 1em solid;
          border-top: 1em solid transparent;
          border-bottom: 1em solid transparent;
        }

        &::after {
          transform: unset;
          border: unset;
          content: '';
          position: absolute;
          top: -0.25em;
          width: 1.2em;
          height:0.5em;
          background: #f6d157;
        }

        &.ec-next::after {
          left: -1.2em;
        }
      }
    }
  }
  ::v-deep .ec-header {
    border: none;

    .ec-day {
      border: none;
      font-size: 18px;
      line-height: 30px;
    }
  }

  ::v-deep .ec-body{
    border: none;

    .ec-other-month {
      opacity: 0;
      pointer-events: none;
    }

    .ec-today {
      background-color: unset;

      .ec-day-foot {
        width: 7px;
        height: 7px;
        background-color: #379B8D;
        border-radius: 50%;
        bottom: 15px;
      }
    }
    .ec-days {
      border: none;
    }

    .ec-day {
      flex-direction: column;
      color: #adadad;
      width: 4em;
      height: 4em;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      border: none;

      &:has(.ec-event) {
        .ec-day-head {
          color: #379B8D;
        }
      }
    }
    .ec-events {
      position: absolute;

      &:has(.ec-event) {
        width: 60px;
        height: 60px;
        border-radius: 50%;
        margin: 0;
        background: rgba(93, 185, 172, 0.4);

        .ec-event {
          display: none;
        }
      }
    }
  }
}
</style>
