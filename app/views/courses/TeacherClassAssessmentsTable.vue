<template lang="jade">
  #teacher-class-assessments-table
    div.freeze-column
      div.table-row.table-header-row
        div.table-header
      div.table-row(v-for="student in students")
        div.table-cell.name {{ broadName(student) }}
    div.data-column
      div.table-row(v-if="levels.length === 0")
        div.table-cell No assessment levels available for this course yet.
      div.table-row.table-header-row(v-else)
        div.table-header(v-for="level in levels")
          div(v-if="level.assessment === 'cumulative'") Combo
          div(v-else-if="!(level.primaryConcepts||[]).length") Long long long long name
          div(v-else) {{ $t("concepts."+(level.primaryConcepts||[])[0]) }}
      div.table-row(v-for="student in students")
        div.table-cell(v-for="level in levels")
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
    display: flex
    .table-row
      height: 44px
    .data-column
      overflow: scroll
      .table-row
        white-space: nowrap
      .table-cell, .table-header
        text-align: center
    .table-cell, .table-header
      height: 44px
      display: inline-block
      width: 142.5px
      border: 1px solid black
      box-sizing: border-box
    .table-header-row, .table-header
      height: 62px
    .table-header
      white-space: normal
      font-weight: bold
      position: relative
      div 
        position: absolute
        left: 0
        right: 0
        top: 0
        bottom: 0
        overflow: hidden
</style>
