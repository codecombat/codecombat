<template lang="pug">
  #teacher-class-assessments-table(v-if="courseInstance && courseInstance.members.length > 0")
    div.table-row(v-if="levels.length === 0")
      div.table-cell No assessment levels available for this course yet.
    div.freeze-column(v-if="levels.length > 0")
      div(v-for="(student, index) in students")
        div.table-row.table-header-row(v-if="index % 8 === 0")
          div.table-header
        div.prev-arrow(@click="onClickArrow(-1)", v-if="index % 8 === 0", :style="{display: showPrevArrows ? 'block' : 'none'}")
          span.glyphicon.glyphicon-circle-arrow-left
        div.next-arrow(@click="onClickArrow(1)", v-if="index % 8 === 0", :style="{display: showNextArrows ? 'block' : 'none'}")
          span.glyphicon.glyphicon-circle-arrow-right
        div.table-row(:class="backgroundClass(index)")
          div.table-cell.name
            div
              strong
                a(v-if="!readOnly" :href="studentLink(student._id)") {{ broadName(student) }}
                span(v-else) {{ broadName(student) }}
            div.student-email {{ student.email || student.name }}
    div.data-column(ref="dataColumn", @scroll="updateArrows" v-if="levels.length > 0")
      div(v-for="(student, index) in students")
        div.small.table-row.table-header-row.alternating-background(v-if="index % 8 === 0")
          div.table-header(v-for="level in levels", :class="{'combo-cell': level.assessment === 'cumulative'}")
            div(v-if="level.assessment === 'cumulative'")
              span
                | {{ $t('teacher.combo') }}
                =" "
                i.glyphicon.glyphicon-question-sign(data-html='true', :data-title="$t('teacher.combo_explanation')")
            div(v-else-if="!(level.primaryConcepts||[]).length")
              span ?
            div(v-else)
              span {{ $t("concepts."+(level.primaryConcepts||[])[0]) }}
        .table-row(:class="backgroundClass(index)")
          div.table-cell(v-for="level in levels", :class="{'combo-cell': level.assessment === 'cumulative'}")
            student-level-progress-dot(
              v-if="progress[level.original]",
              :level="level",
              :progress="progress[level.original][student._id]",
              :student="student",
              :courseInstance="courseInstance",
              :course="course",
              :classroom="classroom",
              :readOnly="readOnly"
            )
  div(v-else)
    h2.text-center
      i(data-i18n='teacher.no_student_assigned')
  
</template>

<script lang="coffee">
  User = require('models/User')
  StudentLevelProgressDot = require('./StudentLevelProgressDot').default
  
  module.exports = Vue.extend({
    props: {
      students: {}
      levels: {}
      progress: { default: -> {} }
      course: {}
      courseInstance: {}
      classroom: {},
      readOnly: Boolean
    },
    data: ->
      showPrevArrows: false
      showNextArrows: false
    methods: {
      broadName: User.broadName,
      onClickArrow: (dir) ->
        @$refs.dataColumn.scrollLeft += @$refs.dataColumn.offsetWidth * dir
      updateArrows: ->
        col = @$refs.dataColumn
        return unless col
        @showPrevArrows = col.scrollLeft > 0
        @showNextArrows = (col.scrollWidth > col.offsetWidth) and (col.offsetWidth + col.scrollLeft < col.scrollWidth)
      backgroundClass: (index) ->
        if index % 2
          return { 'darker': true }
        else
          return { 'lighter': true }
      studentLink: (studentId) ->
        "/teachers/classes/#{@classroom._id}/#{studentId}"
    },
    components: {
      StudentLevelProgressDot
    },
    mounted: ->
      @updateArrows()
      $('.glyphicon-question-sign', @$el).each (i, el) ->
        $(el).tooltip({ html: true, container: '#teacher-class-assessments-table' })
  })
</script>

<style lang="sass">
  @import "app/styles/bootstrap/variables"

  #teacher-class-assessments-table
    .table-row.lighter
      .table-cell
        background: $gray-lighter
    .table-row.darker
      .table-cell
        background: #EFEBEF
    
    display: flex
    position: relative
    .table-row, .table-cell
      height: 62px
    .freeze-column
      .table-cell, .table-header
        width: 200px
    .data-column
      overflow: scroll
      .table-row
        white-space: nowrap
      .table-cell, .table-header
        text-align: center
        
    .next-arrow, .prev-arrow
      position: absolute
      z-index: 1
      width: 30px
      cursor: pointer
      margin-top: -13px
      text-align: center
      color: #0b93d5
      font-size: 30px

      
    .next-arrow
      right: -9px
    .prev-arrow
      left: 198px
    .table-cell, .table-header
      display: inline-block
      width: 134.3px
      box-sizing: border-box
    .table-header-row, .table-header
      height: 45px
    .table-header-row
      position: relative
    .table-header
      background: white
      white-space: normal
      font-weight: bold
      position: relative
      div 
        display: flex
        position: absolute
        left: 0
        right: 0
        top: 0
        bottom: 0
        overflow: hidden
        span
          width: 100%
          align-self: flex-end
    .student-email
      font-size: 15px
      line-height: 19px
      text-overflow: ellipsis
      overflow: hidden
    .table-row.lighter .table-cell.combo-cell
      background: #e0eaf0
    .table-row.darker .table-cell.combo-cell
      background: #cedee8
    .table-header.combo-cell
      background: #cedee8
    .table-cell.name
      padding-left: 10px
      padding-top: 5px
    svg.progress-dot, svg
      width: 34px
      padding: 0
      background: transparent
</style>
