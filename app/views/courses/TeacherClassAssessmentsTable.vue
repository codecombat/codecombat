<template lang="jade">
  table.table.table-condensed.assessments-table
    tbody
      tr(v-if="levels.length === 0")
        td No assessment levels available for this course yet.
      tr(v-else)
        th
        th(v-for="level in levels")
          span(v-if="level.assessment === 'cumulative'") Combo
          span(v-else) {{ $t("concepts."+(level.primaryConcepts||[])[0]) }}
      tr(v-for="student in students")
        td.name {{ broadName(student) }}
        td(v-for="level in levels")
          student-level-progress-dot(
            :level="level",
            :progress="progress[level.original][student._id]",
            :student="student",
            :courseInstance="courseInstance",
            :course="course",
            :classroom="classroom",
          )
  
</template>

<script lang="coffee">
  User = require('models/User')
  StudentLevelProgressDot = require('./StudentLevelProgressDot').default
  
  module.exports = Vue.extend({
    props: [
      'students',
      'levels',
      'progress',
      'course',
      'courseInstance',
      'classroom',
    ],
    methods: {
      broadName: User.broadName,
      courseInstanceForLevel: (level) ->
        
    },
    components: {
      StudentLevelProgressDot
    }
  })
</script>

<style lang="sass">
  #teacher-class-assessments-table
    color: red
</style>
