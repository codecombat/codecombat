<template>
  <div class="header">
    <div class="header__text">
      <span>
        Live Online Coding Classes:
      </span>
      <span
        v-if="nextEventDate && child"
        class="header__date"
      >
      {{ child.broadName }}'s next class is on {{ nextEventDateFormatted }}.
    </span>
    <span
      v-else-if="child"
      class="header__date"
    >
      Try a free online class for {{ child.broadName }} today! Cancel anytime.
    </span>
    <span
      v-else
    >
      Try a free online class today! Cancel anytime.
    </span>
    </div>
    <div
      v-if="!nextEventDate"
      class="header__try"
    >
      <!-- maybe we use different scheduler than timetap if we have clild account info already -->
      <button
        @click="onTryFreeClassClicked"
        class="header__try__btn yellow-btn-black-text"
      >
        Try a Free Online Class
      </button>
      <modal-timetap-schedule
        v-if="showBookClassModal"
        :show="showBookClassModal"
        @close="showBookClassModal = false"
      />
    </div>
  </div>
</template>

<script>
import moment from 'moment'
import ModalTimetapSchedule from '../../landing-pages/parents/ModalTimetapSchedule'
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
  data () {
    return {
      showBookClassModal: false
    }
  },
  components: {
    ModalTimetapSchedule
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
  },
  methods: {
    onTryFreeClassClicked () {
      this.showBookClassModal = true
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
@import "../css-mixins/common";

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

  &__try {
    padding-left: 1rem;

    &__btn {
      padding: 1rem 2.5rem;
    }
  }
}
</style>
