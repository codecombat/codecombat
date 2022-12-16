<template>
  <div id="calendar" />
</template>

<script>
import Calendar from '@event-calendar/core'
import DayGrid from '@event-calendar/day-grid'
import Interaction from '@event-calendar/interaction'
import { mapMutations } from 'vuex'

export default {
  name: 'SingleCalendar',
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

  },
  methods: {
    ...mapMutations({
      openEventPanel: 'events/openEventPanel'
    }),
    calendarOptions () {
      const that = this
      return {
        view: 'dayGridMonth',
        scrollTime: '09:00:00',
        events: that.createEvents(),
        pointer: true,
        eventContent: function (info) {
          switch (info.event.display) {
          case 'background':
            return ''
          case 'pointer':
            return '<div class="ec-event-empty icon-plus blue" />'
          default:
            return '<div class="ec-event-time">' + info.timeText + '</div>' +
              '<div class="ec-event-title">' + info.event.title + '</div>'
          }
        },
        dateClick (info) {
          that.openEventPanel({ type: 'new' })
        }
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
        greyOut
      ]
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
@import '~node_modules/@event-calendar/core/index.css';
#calendar {
}
::v-deep .ec-event-empty {
  cursor: pointer;
  pointer-events: auto;
}

::v-deep  .icon-plus {
  $outer-width: 24px;
  $inner-width: 16px; /* (outer-$this)%2 == 0 */
  $inner-height: 4px; /* (outer-$this)%2 == 0 */

  margin: auto;
  width: $outer-width;
  height: $outer-width;
  border-radius: 50%;

  position: relative;

  &:after, &:before {
    content: '';
    position: absolute;
    background: #FFF;
    border-radius: max(1px, calc(#{$inner-height}/2 - 1px));
    border-radius: 2px;
  }

  &:after { /* horizontal */
    width: $inner-width;
    height: $inner-height;
    left: calc((#{$outer-width} - #{$inner-width})/2);
    top: calc((#{$outer-width} - #{$inner-height})/2);
  }

  &:before { /* vertical */
    width: $inner-height;
    height: $inner-width;
    top: calc((#{$outer-width} - #{$inner-width})/2);
    left: calc((#{$outer-width} - #{$inner-height})/2);
  }

  &.orange {
    background: #FD7901;
  }

  &.blue {
    background: #3498db;
  }

}

</style>
