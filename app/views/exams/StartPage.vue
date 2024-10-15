<template>
  <div class="start-page center-div">
    <select
      id="language-select"
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
      <label for="timer">A timer will start when you click Start the exam</label>
    </div>
    <div class="start">
      <input
        v-if="newUser"
        :disabled="!hasPermission || !timer"
        type="button"
        value="Start the Exam"
        @click="startExam"
      >
      <input
        v-else
        :disabled="!hasPermission"
        type="button"
        value="Take me to the Exam"
        @click="startExam"
      >
      <div v-if="!hasPermission">
        Only users with permission can take the exam
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
      const clans = me.get('clans')
      return clans.includes(this.exam?.clanId)
    },
  },
  mounted () {
    this.checkingUserExam()
  },
  methods: {
    ...mapActions('exams', [
      'startExam',
    ]),
    async startExam () {
      if (this.newUser) {
        await this.startExam(this.examId)
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