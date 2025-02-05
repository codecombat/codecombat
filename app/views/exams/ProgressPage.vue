<template>
  <div class="progress-page center-div">
    <div class="header">
      <div class="code-language">
        {{ programmingLanguageDisplay }}
      </div>
      <div class="timer">
        {{ $t('exams.time_left') }} {{ timeLeft }}
      </div>
    </div>

    <div class="levels">
      <ul class="level-grid">
        <exam-level
          v-for="(level, index) in problems"
          :key="`${level.slug}-${index}`"
          :level="level"
          :language="userExam.codeLanguage"
          :index="index + 1"
          :is-completed="!!submissionStatus[level.slug]"
          class="level-grid-item"
        />
      </ul>
    </div>
    <div v-if="loading">
      {{ $t('common.loading') }}
    </div>

    <div class="submit center-div">
      <input
        type="button"
        class="btn btn-lg btn-success"
        value="End Exam"
        @click="() => submit(false)"
      >
    </div>
    <div class="notes">
      <p class="note">
        *Submissions status gets updated every 1 minute on this page.
      </p>
      <p class="note">
        *Don't worry if it's not updated immediately, your code will still be submitted.
      </p>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import ExamLevel from './components/ExamLevel'
const courseInstancesApi = require('../../core/api/course-instances')
const { levelsOfExam } = require('../../lib/user-utils')
const examsApi = require('../../core/api/exams')

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
      courseInstanceMap: null,
      loading: false,
      submissionStatus: {},
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
      if (!this.exam || !this.courseInstanceMap) {
        return []
      }
      const levels = levelsOfExam(this.exam)
      levels.forEach((level) => {
        const instanceId = this.courseInstanceMap[level.courseId]
        if (!instanceId) {
          noty({
            text: `Course instance not found for course ${level.courseId}`,
            type: 'error',
            timeout: 5000,
          })
          return
        }
        level.instanceId = instanceId
      })
      return levels
    },
    limitedDuration () {
      return this.userExam?.duration || this.exam?.duration
    },
    programmingLanguageDisplay () {
      const lang = this.userExam?.codeLanguage
      if (!lang) return ''
      return lang[0].toUpperCase() + lang.slice(1)
    },
  },
  async mounted () {
    if (this.userExam?.submitted) {
      noty({
        text: 'Exam has ended',
        type: 'error',
        timeout: 5000,
      })
      return
    }
    this.loading = true
    await this.fetchCourseInstanceMap()
    await this.counter()
    const oneMin = 60 * 1000
    this.counterInterval = setInterval(this.counter, oneMin)
    this.loading = false
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
    getMinsElapsed () {
      const oneMin = 60 * 1000
      const startDate = new Date(this.userExam.startDate)
      const minsElapse = parseInt((new Date() - startDate) / oneMin)
      return minsElapse
    },
    async counter () {
      const minsElapse = this.getMinsElapsed()
      let minsLeft = this.limitedDuration - minsElapse
      if (minsLeft <= 0) {
        clearInterval(this.counterInterval)
        minsLeft = 0
        this.submit(true)
      }
      this.timeLeft = `${this.paddingZero(minsLeft / 60 | 0)}:${this.paddingZero(minsLeft % 60)}`
      await this.refetchSubmissionsStatus()
    },
    async refetchSubmissionsStatus () {
      try {
        const res = await examsApi.getSubmissionsStatus(this.examId)
        this.submissionStatus = { ...res.result }
      } catch (err) {
        noty({
          text: 'Failed to fetch submissions status',
          type: 'error',
          timeout: 5000,
        })
      }
    },
    async submit (expires) {
      if (!expires) {
        if (!confirm(this.$t('exams.submit_tip'))) {
          return
        }
      }
      const minMinutesBeforeSubmission = 5
      if (this.getMinsElapsed() < minMinutesBeforeSubmission) {
        window.tracker?.trackEvent(`Early Exam Submission - ${this.examId}`, {
          userId: me.id,
          duration: this.timeLeft,
          autoSubmit: expires,
          currentTime: new Date().toISOString(),
        })
        noty({
          text: `You must wait at least ${minMinutesBeforeSubmission} minutes before submitting`,
          type: 'error',
          timeout: 5000,
        })
        return
      }
      window.tracker?.trackEvent(`Exam End - ${this.examId}`, {
        userId: me.id,
        duration: this.timeLeft,
        autoSubmit: expires,
        currentTime: new Date().toISOString(),
      })
      await this.submitExam({
        userExamId: this.userExam._id,
        expires,
      })
      application.router.navigate(window.location.pathname.replace(/progress$/, 'end'), { trigger: true })
    },
    async fetchCourseInstanceMap () {
      const courseInstances = await courseInstancesApi.fetchByClassroom(this.userExam.classroomId)
      this.courseInstanceMap = courseInstances.reduce((acc, courseInstance) => {
        acc[courseInstance.courseID] = courseInstance._id
        return acc
      }, {})
    },
    getCourseInstance (courseId) {
      return this.courseInstanceMap[courseId]
    },
  },
}

</script>

<style scoped lang="scss">
.center-div {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
}

.progress-page {
  .header {
    display: flex;
    min-width: 800px;
    justify-content: space-around;
  }
}

.levels {
  padding: 10px;
}

.level-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  row-gap: 3rem;
  column-gap: 6rem;
  list-style: none;
  padding: 0;
}
.level-grid-item {
  text-align: center;
}
.notes {
  display: flex;
  flex-direction: column;
  margin-top: 10px;

  .note {
    font-size: 14px;
    margin-bottom: 5px;
  }
}
</style>
