<template>
  <div class="progress-page center-div">
    <div class="header">
      <div class="code-language">
        {{ userExam.codeLanguage }}
      </div>
      <div class="timer">
        {{ $t('exams.time_left') }} {{ timeLeft }}
      </div>
    </div>
    <div class="levels">
      <exam-level
        v-for="(level, index) in problems"
        :key="level._id"
        :level="level"
        :language="userExam.codeLanguage"
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
        {{ $t('exams.submit_tip') }}
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
  props: {
    examId: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      timeLeft: '00:00',
      counterInterval: null,
    }
  },
  computed: {
    ...mapGetters('exams', [
      'getExamById',
      'userExam',
    ]),
    exam () {
      return this.getExamById(this.examId)
    },
    problems () {
      if (!this.exam) {
        return []
      }
      const problems = this.exam.problems
      const levels = []
      problems.forEach((courseLevels) => {
        courseLevels.levels.forEach((level, index) => {
          levels.push({
            ...level,
            courseId: courseLevels.courseId,
            instanceId: courseLevels.instanceId,
          })
        })
      })
      return levels
    },
  },
  mounted () {
    this.counter()
    const oneMin = 60 * 1000
    this.counterInterval = setInterval(this.counter, oneMin)
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
      const oneMin = 60 * 1000
      const startDate = new Date(this.exam.startDate)
      const minsElapse = parseInt((new Date() - startDate) / oneMin)
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