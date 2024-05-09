<template>
  <page-template>
    <div class="scheduler">
      <div class="header">
        {{ header }}
      </div>
      <div class="body">
        <class-info
          v-if="step === 'class'"
          :code-language-map="codeLanguageMap"
          :levels="levels"
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
          :class-details="classDetails"
          @change-student-info="changeStudentInfo"
          @back="step = 'available'"
        />
        <next-step
          v-else
        />
      </div>
    </div>
  </page-template>
</template>

<script>
import pageTemplate from '../parents/PageTemplate.vue'
import classInfo from './components/classInfo.vue'
import availableTime from './components/availableTime.vue'
import studentInfo from './components/studentInfo.vue'
import nextStep from './components/nextStep.vue'

import { tempBookTime, bookTime } from '../../core/api/online-classes'
export default {
  name: 'SchedulerView',
  components: {
    pageTemplate,
    classInfo,
    studentInfo,
    nextStep,
    availableTime
  },
  data () {
    return {
      header: 'Book Live Online Classes',
      step: 'class',
      classInfo: {},
      time: {},
      studentInfo: {},
      codeLanguageMap: {
        python: 'Python',
        javascript: 'JavaScript',
        html: 'HTML',
        css: 'CSS',
        lua: 'Lua',
        java: 'Java',
        cpp: 'C++',
        coffeescript: 'CoffeeScript',
      },
      levels: ['Beginner', 'Intermediate', 'Advanced']
    }
  },
  computed: {
    classDetails () {
      const lang = this.classInfo.language
      const codeLang = this.codeLanguageMap[this.classInfo.codeLanguage]
      const level = this.levels[this.classInfo.level]
      const dateTime = `${this.time.date.slice(0, 10)} ${this.time.time}:00`
      return [lang, codeLang, level, dateTime].join(' . ')
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

<style lang="scss" scoped>
.scheduler {
  background: #FFFFFF;
  border: 5px solid #1FBAB4;
  border-radius: 3rem;
  padding: 4rem;
  z-index: 1;
  // min-height: 450px;
  min-width: 500px;

  .header{
    font-family: "Arvo", sans-serif;
    font-weight: 700;
    font-size: 2rem;
    line-height: 2.5rem;
    color: #232323;
    margin-bottom: 2rem;
    text-align: center;
  }

  .body {
    font-family: 'Work Sans', sans-serif;
    font-weight: 400;
    font-size: 1.6rem;
    line-height: 1.9rem;
  }
}
</style>
