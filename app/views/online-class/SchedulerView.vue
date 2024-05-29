<template>
  <page-template>
    <div
      v-if="loading"
      class="scheduler"
    >
      Loading ...
    </div>
    <div
      v-else
      class="scheduler"
    >
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
import moment from 'moment'
import PageTemplate from '../parents/PageTemplate.vue'
import ClassInfo from './components/ClassInfo.vue'
import AvailableTime from './components/AvailableTime.vue'
import StudentInfo from './components/StudentInfo.vue'
import NextStep from './components/NextStep.vue'

import { tempBookTime, bookTime, getGoogleCalendarSync } from '../../core/api/online-classes'
export default {
  name: 'SchedulerView',
  components: {
    PageTemplate,
    ClassInfo,
    StudentInfo,
    NextStep,
    AvailableTime
  },
  data () {
    return {
      loading: true,
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
      // todo: confirm with timezones
      const date = moment(this.time.date).set({ hour: this.time.time, minute: 0 })
      const dateTime = date.format('YYYY-MM-DD HH:mm A')
      return [lang, codeLang, level, dateTime].join(' &bull; ')
    }
  },
  created () {
    getGoogleCalendarSync().then(res => {
      this.loading = false
    }).catch(err => {
      this.loading = false
      console.log(err)
    })
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
