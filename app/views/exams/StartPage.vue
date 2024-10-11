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
import { mapGetters } from 'vuex'
export default {
  data () {
    return {
      timer: false,
    }
  },
  computed: {
    ...mapGetters({
      exam: 'exam/exam',
    }),
    avaliableLanguages () {
      return this.exam?.languages || ['python', 'javascript', 'cpp', 'java']
    },
    newUser () {
      return true // todo: decide by the user.exams status
    },
    hasPermission () {
      return true // todo: decide by the user.exams
    },
  },
  mounted () {
  },
  methods: {
    startExam () {
      // todo: start the exam
      application.router.navigate(window.location.pathname.replace(/start$/, 'progress'), { trigger: true })
    },
  },
}

</script>

<style scoped lang="scss">
</style>