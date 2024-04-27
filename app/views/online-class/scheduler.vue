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
      <available-time
        v-else-if="step === 'available'"
        :class-info="classInfo"
        @back="step = 'class'"
        @next="selectTime"
      />
      <student-info
        v-else-if="step === 'student'"
        @change-student-info="changeStudentInfo"
        @back="step = 'available'"
      />
      <next-step
        v-else
      />
    </div>
  </div>
</template>

<script>
import classInfo from './components/classInfo.vue'
import availableTime from './components/availableTime.vue'
import studentInfo from './components/studentInfo.vue'
import nextStep from './components/nextStep.vue'

import { tempBookTime, bookTime } from '../../core/api/online-classes'
export default {
  name: 'Scheduler',
  components: {
    classInfo,
    studentInfo,
    nextStep,
    availableTime
  },
  data () {
    return {
      header: 'Book live online class',
      step: 'class',
      classInfo: {},
      time: {},
      studentInfo: {}
    }
  },
  methods: {
    changClassInfo (data) {
      this.classInfo = data
      this.step = 'available'
    },
    selectTime (data) {
      this.time = data
      tempBookTime({
        studentId: me.id,
        date: data.date,
        time: data.time,
        classInfo: this.classInfo
      }).then(res => {
        this.step = 'student'
      }).catch(err => {
        console.log(err)
        // todo: show error message in UI
      })
    },
    changeStudentInfo (data) {
      this.studentInfo = data
      bookTime({
        studentId: me.id,
        date: this.time.date,
        time: this.time.time,
        classInfo: this.classInfo,
        studentInfo: this.studentInfo
      }).then(res => {
        this.step = 'final'
        this.header = 'One More Step'
      }).catch(err => {
        console.log(err)
        // todo: show error message in UI
      })
    }
  }
}
</script>

<style lang="sass">
</style>
