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
          <h2>{{ tr.title }}</h2>
          <p>{{ tr.description }}</p>
        </div>

        <div class="teacher">
          <p>{{ tr.teacher.name }}</p>
        </div>
        <div class="students">
          <p>{{ tr.properties.studentInfo.studentName }}</p>
          <p>{{ tr.properties.studentInfo.guardianName }}</p>
          <p>{{ tr.properties.studentInfo.guardianPhone }}</p>
        </div>
        <div class="time-and-status">
          <p>{{ tr.date }}</p>
          <p>{{ tr.status }}</p>
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
      const res = await getTrialClasses()
      this.trialClasses = res.data
    }
  }
}
</script>

<style scoped lang="scss">
.trial-classes {
  display: flex;
  flex-direction: column;
  padding: 20px;

  .class {
    display: flex;

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
