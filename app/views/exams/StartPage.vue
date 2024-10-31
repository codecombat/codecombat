<template>
  <div class="start-page center-div">
    <select
      id="language-select"
      v-model="codeLanguage"
      :disabled="!newUser"
    >
      <option
        v-for="lang in avaliableLanguages"
        :key="lang"
        :value="lang"
      >
        {{ lang }}
      </option>
    </select>
    <div
      v-if="newUser"
      class="timer-tip"
    >
      <input
        v-model="timer"
        name="timer"
        type="checkbox"
      >
      <label for="timer"> {{ $t('exams.timer_tip') }} </label>
    </div>
    <div class="start center-div">
      <input
        v-if="newUser"
        :disabled="!hasPermission || !timer"
        type="button"
        value="Start the Exam"
        @click="localStartExam"
      >
      <input
        v-else
        :disabled="!hasPermission"
        type="button"
        value="Take me to the Exam"
        @click="localStartExam"
      >
      <div v-if="!hasPermission">
        {{ $t('exams.no_permission') }}
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
export default {
  props: {
    examId: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      codeLanguage: 'python',
      timer: false,
      newUser: true,
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
    avaliableLanguages () {
      return this.exam?.languages || ['python', 'javascript']
    },
    hasPermission () {
      if (this.exam?._id === '-') {
        return true
      }
      const clans = me.get('clans') || []
      return clans.includes(this.exam?.clan)
    },
  },
  mounted () {
    this.checkingUserExam()
  },
  methods: {
    ...mapActions('exams', [
      'startExam',
    ]),
    async localStartExam () {
      if (this.newUser) {
        await this.startExam({ examId: this.examId, codeLanguage: this.codeLanguage })
      }
      application.router.navigate(window.location.pathname.replace(/start$/, 'progress'), { trigger: true })
    },
    checkingUserExam () {
      if (!this.userExam) {
        this.newUser = true
        return
      }
      const startDate = new Date(this.userExam.startDate)
      const duration = (new Date().getTime() - startDate.getTime()) / (1000 * 60)
      if (duration < this.exam.duration) {
        this.newUser = false
      } else {
        application.router.navigate(window.location.pathname.replace(/start$/, 'end'), { trigger: true })
      }
    },
  },
}

</script>

<style scoped lang="scss">
</style>