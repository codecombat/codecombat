<template>
  <div id="calendar" />
</template>

<script>
import Calendar from '@event-calendar/core'
import DayGrid from '@event-calendar/day-grid'
import Interaction from '@event-calendar/interaction'
export default {
  name: 'StylishCalendar',
  props: {
    events: {
      type: Array,
      default: () => []
    }
  },
  watch: {
    events () {
      this.eCalendar?.refetchEvents()
      setTimeout(() => this.selectRecent(), 500)
    }
  },
  mounted () {
    this.$nextTick(() => {
      this.eCalendar = new Calendar({
        target: document.querySelector('#calendar'),
        props: {
          plugins: [DayGrid, Interaction],
          options: this.calendarOptions()
        }
      })
    })
  },
  methods: {
    calendarOptions () {
      return {
        view: 'dayGridMonth',
        eventSources: [{ events: () => this.events }],
        headerToolbar: { start: 'prev', center: 'title', end: 'next' },
        eventClick: (info) => {
          this.selectDate(info)
        },
        eventContent (info) {
          return {
            html: `<div class="ec-event-time">${info.timeText}</div>` +
              `<div class="ec-event-title" data-event-id="${info.event.id}">${info.event.title}</div>`
          }
        }
      }
    },
    selectDate (info) {
      document.querySelectorAll('.date-selected').forEach(el => el.classList.remove('date-selected'))
      info.el.classList.add('date-selected')
      this.$emit('event-click', info)
    },
    selectRecent () {
      const events = Array.from(document.querySelectorAll('.ec-day'))
      const today = _.findIndex(events, e => e.classList.contains('ec-today'))
      let ev
      for (let i = today; i >= 0; i--) {
        if ((ev = events[i].querySelector('.ec-event'))) {
          ev.click()
          break
        }
      }
    },

  }
}
</script>

<style lang="scss" scoped>
@import '~node_modules/@event-calendar/core/index.css';

#calendar {
  font-family: 'Work Sans';
  font-weight: 600;

  ::v-deep .ec-toolbar {
    padding-bottom: 20px;
    margin-top: 50px;

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
        bottom: 20px;
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

        &:has(.date-selected) {
          .ec-day-head {
            color: #fff;
            z-index: 2;
          }
        }
      }
    }
    .ec-events {
      position: absolute;

      &:has(.ec-event) {
        width: 50px;
        height: 50px;
        border-radius: 50%;
        margin: 0;
        background: rgba(93, 185, 172, 0.4);

        &:has(.date-selected) {
          background: #379B8D;
        }

        .ec-event {
          position: absolute;
          top: 0;
          left: 0;
          opacity: 0;
          width: 70px;
          height: 70px;
          border-radius: 50%;
        }
      }
    }
  }
}
</style>
