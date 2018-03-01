<template lang="jade">
  #teacher-class-assessments-table
    div.freeze-column
      div(v-for="(student, index) in students")
        div.table-row.table-header-row(v-if="index % 8 === 0")
          div.table-header
        div.table-row
          div.table-cell.name
            div {{ broadName(student) }}
            div.student-email {{ student.email }}
    div.data-column
      div.table-row(v-if="levels.length === 0")
        div.table-cell No assessment levels available for this course yet.
      div(v-for="(student, index) in students")
        div.table-row.table-header-row(v-if="index % 8 === 0")
          div.table-header(v-for="level in levels", :class="{'combo-cell': level.assessment === 'cumulative'}")
            div(v-if="level.assessment === 'cumulative'") Combo
            div(v-else-if="!(level.primaryConcepts||[]).length") Long long long long name
            div(v-else) {{ $t("concepts."+(level.primaryConcepts||[])[0]) }}
        .table-row
          div.table-cell(v-for="level in levels", :class="{'combo-cell': level.assessment === 'cumulative'}")
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
    .table-row, .table-cell
      height: 53px
    .freeze-column
      .table-cell, .table-header
        width: 200px
    .data-column
      overflow: scroll
      .table-row
        white-space: nowrap
      .table-cell, .table-header
        text-align: center
    .table-cell, .table-header
      display: inline-block
      width: 134.3px
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
    .student-email
      font-size: 15px
      line-height: 20px
      text-overflow: ellipsis
      overflow: hidden
    .progress-dot
      margin-top: 9px
    .combo-cell
      background: #eee
</style>
