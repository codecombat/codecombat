<template>
  <div class="trial-classes">
    <h1 class="tr-title">
      Trial Classes
    </h1>
    <h3
      v-if="isAdminView"
    >
      Admin View
    </h3>
    <div
      v-if="trialClasses?.length > 0"
      class="lists"
    >
      <div
        v-for="tr in trialClasses"
        :key="tr._id"
        class="trial-class"
      >
        <div class="heading">
          <div class="title">
            {{ tr.name }} <span class="desc">({{ tr.description }})</span>
          </div>

          <div
            v-if="isAdmin()"
            class="teacher"
          >
            <p><span class="s-label">Teacher:</span> {{ tr.ownerName }}</p>
          </div>
        </div>

        <div class="students">
          <p><span class="s-label">Student:</span> {{ tr.properties.studentInfo.studentName || '-' }} </p>
          <span class="split">|</span>
          <p><span class="s-label">Guardian:</span> {{ tr.properties.studentInfo.guardianName || '-' }} </p>
          <span class="split">|</span>
          <p><span class="s-label">Phone:</span> {{ tr.properties.studentInfo.guardianPhone || '-' }}</p>
        </div>
        <div class="time-and-status">
          <p><span class="s-label">Start Time:</span> {{ timeString(tr.startDate) }}</p>
          <span class="split">|</span>
          <p><span class="s-label">Status:</span> {{ tr.state }}</p>
        </div>
      </div>
    </div>
    <div
      v-else
    >
      No trial class booked
    </div>
  </div>
</template>

<script>
import { getTrialClasses } from '../../core/api/online-classes'
const moment = require('moment')

export default {
  name: 'TrialClasses',
  props: {
    isAdminView: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      trialClasses: []
    }
  },
  async mounted () {
    await this.fetchTrialClasses()
  },
  methods: {
    async fetchTrialClasses () {
      this.trialClasses = await getTrialClasses({
        isAdminView: this.isAdminView
      })
    },
    isAdmin () {
      return window.me.isAdmin()
    },
    timeString (time) {
      return moment(time).format('LLL Z')
    }
  }
}
</script>

<style scoped lang="scss">
.trial-classes {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;

  p {
    margin: 0;
  }

  .tr-title {
    border-bottom: 1px solid grey;
    margin-bottom: 10px;
  }

  .trial-class {
    width: 1200px;
    border-bottom: 1px solid black;

    .students {
      display: flex;
    }

    .time-and-status {
      display: flex;
    }

    .split {
      margin-left: 5px;
      margin-right: 5px;
      font-weight: bold;
    }

    .title {
      font-weight: bold;
      font-size: 20px;

      .desc {
        font-size: 16px;
      }
    }

    .s-label {
      font-weight: lighter;
    }
  }
}
</style>
