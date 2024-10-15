<template>
  <div class="progress-page center-div">
    <div class="header">
      <div class="code-language">
        {{ myExam.codeLanguage }}
      </div>
      <div class="timer">
        Time Left: {{ timeLeft }}
      </div>
    </div>
    <div class="levels">
      <exam-level
        v-for="(level, index) in problems"
        :key="level._id"
        :level="level"
        :index="index + 1"
      />
    </div>

    <div class="submit center-div">
      <input
        type="button"
        value="Mark as Complete"
        @click="submit"
      >
      <div class="tip">
        Are you sure you want to mark as complete? You will not be able to play the levels again.
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import ExamLevel from './components/ExamLevel'
export default {
  components: {
    ExamLevel,
  },
  data () {
    return {
      timeLeft: '00:00',
      myExam: {},
      counterInterval: null,
    }
  },
  computed: {
    ...mapGetters({
      /* exam: 'exam/exam', */
    }),
    exam () {
      return {
        _id: '123',
        duration: 120,
        levels: [
          { _id: '1', name: 'Level 1', description: 'This is level 1' },
          { _id: '2', name: 'Level 2', description: 'This is level 2' },
          { _id: '3', name: 'Level 3', description: 'This is level 3' },
        ],
      }
    },
    problems () {
      const problems = this.exam.problems
      const levels = []
      Object.entries(problems).forEach(([key, value]) => {
        value.levels.forEach((level, index) => {
          levels.push({
            ...level,
            courseId: key,
            instanceId: value.instanceId,
          })
        })
      })
      return levels
    },
  },
  mounted () {
    /* this.myExam = me.getExam(this.exam?._id) */
    this.myExam = {
      codeLanguage: 'python',
      duration: 25, // min
    }
    this.counter()
    this.counterInterval = setInterval(this.counter, 60000)
  },
  beforeDestroy () {
    clearInterval(this.counterInterval)
  },
  methods: {
    ...mapActions('exams', [
      'submitExam',
    ]),
    paddingZero (num) {
      return `00${num}`.slice(-2)
    },
    counter () {
      const startDate = new Date(this.exam.startDate)
      const minsElapse = (new Date() - startDate) / 60000
      let minsLeft = this.exam.duration - minsElapse
      if (minsLeft <= 0) {
        clearInterval(this.counterInterval)
        minsLeft = 0
        this.submit(true)
      }
      this.timeLeft = `${this.paddingZero(minsLeft / 60 | 0)}:${this.paddingZero(minsLeft % 60)}`
    },
    async submit (expires) {
      // todo: submit exam
      await this.submitExam({
        userExamId: this.userExam._id,
        expires,
      })
      application.router.navigate(window.location.pathname.replace(/progress$/, 'end'), { trigger: true })
    },
  },
}

</script>

<style scoped lang="scss">
.progress-page {

  .header {
    display: flex;
    min-width: 800px;
    justify-content: space-around;
  }
}
</style>