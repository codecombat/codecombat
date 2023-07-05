<template>
  <div class="header">
    <span class="header__text">
      Welcome to Online Classes!
    </span>
    <span
      v-if="nextEventDate && child"
      class="header__date header__text"
    >
      {{ child.broadName }}'s next class is on {{ nextEventDateFormatted }}.
    </span>

  </div>
</template>

<script>
import moment from 'moment'
export default {
  name: 'HeaderComponent',
  props: {
    events: {
      type: Array,
      default () {
        return []
      }
    },
    child: {
      type: Object
    }
  },
  computed: {
    nextEventDate () {
      if (this.events.length === 0) return null
      let nextDate = null
      const current = moment()
      this.events.forEach((event) => {
        const instances = event.instances || []
        instances.forEach(({ startDate }) => {
          const mStart = moment(startDate)
          if (mStart.isAfter(current)) {
            if (nextDate && mStart.isBefore(nextDate)) {
              nextDate = mStart
            } else if (!nextDate) {
              nextDate = mStart
            }
          }
        })
      })
      return nextDate
    },
    nextEventDateFormatted () {
      return moment(this.nextEventDate).format('LLL')
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";

.header {
  display: flex;
  padding: 2.2rem 4rem;
  align-items: center;
  background: $color-blue-1;
  box-shadow: 0 4px 10px 0 rgba(0, 0, 0, 0.25);

  &__text {
    color: $color-white;
    font-size: 2rem;
    font-style: normal;
    font-weight: 600;
    line-height: 3rem;
    letter-spacing: 0.444px;
  }

  &__date {
    font-weight: lighter;
    margin-left: 5px;
  }
}
</style>
