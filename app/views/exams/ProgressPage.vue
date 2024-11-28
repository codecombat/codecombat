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
          :key="level._id"
          :level="level"
          :language="userExam.codeLanguage"
          :index="index + 1"
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
    async counter () {
      const oneMin = 60 * 1000
      const startDate = new Date(this.userExam.startDate)
      const minsElapse = parseInt((new Date() - startDate) / oneMin)
      let minsLeft = this.limitedDuration - minsElapse
      if (minsLeft <= 0) {
        clearInterval(this.counterInterval)
        minsLeft = 0
        this.submit(true)
      }
      this.timeLeft = `${this.paddingZero(minsLeft / 60 | 0)}:${this.paddingZero(minsLeft % 60)}`
      try {
        const res = await examsApi.getSubmissionsStatus(this.examId)
        console.log('res', res)
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
  grid-template-columns: repeat(3, 1fr);
  row-gap: 3rem;
  column-gap: 5rem;
  list-style: none;
  padding: 0;
}
.level-grid-item {
  text-align: center;
}
</style>
