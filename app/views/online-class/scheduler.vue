<template>
  <div class="scheduler">
    <div class="header">
      {{ header }}
    </div>
    <div class="body">
      <class-info
        v-if="step === 'class'"
        @change-class-info="changClassInfo"
      />
      <student-info
        v-else-if="step === 'student'"
        @change-student-info="changeStudentInfo"
      />
      <next-step
        v-else
      />
    </div>
  </div>
</template>

<script>
import classInfo from './components/classInfo.vue'
import studentInfo from './components/studentInfo.vue'
import nextStep from './components/nextStep.vue'
export default {
  name: 'Scheduler',
  components: {
    classInfo,
    studentInfo,
    nextStep,
  },
  data () {
    return {
      header: 'Book live online class',
      step: 'class'
    }
  },
  methods: {
    changClassInfo (data) {
      console.log(data)
      this.step = 'student'
    },
    changeStudentInfo (data) {
      console.log(data)
      this.step = 'final'
      this.header = 'One More Step'
    }
  }
}
</script>

<style lang="sass">
</style>
