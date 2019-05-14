<template lang="pug">
  a.student-level-progress-dot-link.student-level-progress-dot(
    :href="link",
    data-html='true',
    :data-title='titleTemplate',
    :data-student-id="student._id",
    :data-level-slug="level.slug",
    :data-level-progress="progressAttribute",
    :data-course-id="course._id"
  )
    pie-chart.progress-dot.level-progress-dot(
      v-if="level.assessment === 'cumulative' && percentConceptsCompleted",
      :percent='percentConceptsCompleted',
      :stroke-width="10",
      color="#20572B",
      :opacity="1"
    )
    span.progress-dot.level-progress-dot(
      :class="dotClass",
      v-else
    )
      .dot-label.text-center
        .dot-label-inner {{ labelText }}
    

</template>

<script lang="coffee">
  LevelSession = require('models/LevelSession')
  Level = require('models/Level')
  utils = require 'core/utils'
  urls = require('core/urls')
  translateTemplateText = (template, context) => $('<div />').html(template(context)).i18n().html()
  singleStudentLevelProgressDotTemplate = _.wrap(require('templates/teachers/hovers/progress-dot-single-student-level'), translateTemplateText)
  PieChart = require('core/components/PieComponent').default

  module.exports = Vue.extend({
    props: [
      'progress',
      'level',
      'levelNumber',
      'student',
      'courseInstance',
      'course',
      'classroom',
      'readOnly'
    ],
    components: {
      PieChart
    }
    computed: { 
      progressAttribute: -> 
        return 'complete' if @progress.completed
        return 'started' if @progress.started
        return 'not started' 
      dotClass: ->
        classes = {}
        if @progress.completed
          if Level.isProject(@level)
            classes['navy'] = true
          else
            classes['forest'] = true
        else if @progress.started
          classes['gold'] = true
        if Level.isLadder(@level) or Level.isProject(@project)
          classes['progress-dot-lg'] = true
        if @level.practice
          classes['practice'] = true
        return classes
      levelName: ->
        utils.i18n(@level, 'name')
      link: ->
        if @progress.started
          if @readOnly
            link = '/school-administrator/teacher/' + @classroom.ownerID + '/classroom/' + @classroom._id
          else
            link = '/teachers/classes/' + @classroom._id
          link += '/' + @student._id + '#' + @level.slug
        if Level.isLadder(@level) and @courseInstance
          link = urls.courseArenaLadder({@level, @courseInstance});
        if Level.isProject(@level) and @progress.started
          link = urls.playDevLevel({@level, session: @progress.session, @course})
        return link
      labelText: ->
        labelText = @levelNumber || ''
        if Level.isLadder(@level)
          labelText = $.i18n.t('courses.arena')
        if Level.isProject(@level)
          if @progress.started
            labelText = $.i18n.t('teacher.view_project')
            if @progress.completed and not @progress.session.published
              labelText += " " + $.i18n.t('teacher.unpublished')
          else
            labelText = $.i18n.t('teacher.project')
        if @level.practice and not (@progress.completed or @progress.started)
          labelText = ''
        return labelText
      titleTemplate: ->
        context = _.merge(
          @progress,
          { 
            @levelName,
            moment,
            practice: @level.practice
            isLadder: Level.isLadder(@level)
            isProject: Level.isProject(@level),
            assessment: @level.assessment,
            primaryConcept: _.first(@level.primaryConcepts),
            translate: $.i18n.t
            conceptGoals: @conceptGoals
            goalStates: @progress.session?.state.goalStates
          }
        )
        return singleStudentLevelProgressDotTemplate(context)
      conceptGoals: ->
        return (@level.goals || []).filter((g) => g.concepts?.length)
      conceptGoalsCompleted: ->
        return @conceptGoals.filter((g) => @progress.session?.state.goalStates?[g.id]?.status is 'success').length
      percentConceptsCompleted: ->
        res = 100 * @conceptGoalsCompleted / @conceptGoals.length
        return if _.isNaN(res) then 0 else res
    }
    mounted: ->
      $(@$el).tooltip({ html: true })
  })

</script>

<style lang="sass">
  .student-level-progress-dot-link
    display: inline-block
    position: relative
    top: 15px
</style>
