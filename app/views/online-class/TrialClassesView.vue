<template>
  <div class="trial-classes">
    <h1>Trial Classes</h1>
    <div class="lists">
      <div
        v-for="tr in trialClasses"
        :key="tr._id"
        class="class"
      >
        <div class="title">
          <h2>{{ tr.name }}</h2>
          <p>{{ tr.description }}</p>
        </div>

        <div class="teacher">
          <p>teacher: {{ tr.ownerName }}</p>
        </div>
        <div class="students">
          <p>student: {{ tr.properties.studentInfo.studentName }}</p>
          <p>guardian: {{ tr.properties.studentInfo.guardianName }}</p>
          <p>phone: {{ tr.properties.studentInfo.guardianPhone }}</p>
        </div>
        <div class="time-and-status">
          <p>{{ tr.startDate }}</p>
          <p>state: {{ tr.state }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getTrialClasses } from '../../core/api/online-classes'
export default {
  name: 'TrialClasses',
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
      this.trialClasses = await getTrialClasses()
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

  .class {
    margin: 20px;
    display: flex;
    width: 1200px;
    border: 1px solid #ccc;
    border-radius: 8px;

    .title {
      flex-basis: 25%;
    }
    .teacher {
      flex-basis: 25%;
    }
    .students {
      flex-basis: 25%;
    }
    .time-and-status {
      flex-basis: 25%;
    }
  }
}
</style>
