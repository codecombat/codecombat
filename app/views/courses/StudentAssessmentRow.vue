<template lang="pug">
  .row.level-row
    .col-xs-5
      div.level-type
        span(v-if="isCumulative && assessmentPlacement === 'middle'")
          | {{ $t('teacher.combo') }}: {{ $t('teacher.mid_course') }}
        span(v-else-if="isCumulative")
          | {{ $t('teacher.combo') }}: {{ $t('teacher.end_course') }}
        span(v-else-if="primaryConcept")
          | {{ $t('teacher.concept') }}: {{ $t('concepts.' + primaryConcept) }}

      div.small
        strong {{$t('courses.level_name')}}
        =" "
        span {{ name }}
    .col-xs-5
      div.level-status
        span(v-if="complete")
          span.glyphicon.glyphicon-ok-sign.success-symbol.text-forest
          =" "
          | {{ $t('teacher.success') }}
          =" "
          span(v-if="isCumulative")
            =" "
            | ({{ $t('play_level.combo_concepts_used', { complete: conceptGoalsCompleted.length, total: conceptGoals.length }) }})
          br
        span(v-else-if="started")
          span.glyphicon.glyphicon-question-sign.in-progress-symbol.text-gold
          =" "
          | {{ $t('teacher.in_progress') }}
        span(v-else)
      div.small(v-if="isCumulative && started")
        strong {{ $t('courses.concepts_used') }}
        =" "
        span(v-for="(concept, i) in conceptsUsed || []")
          span(v-if="i > 0")
            =", "
          span {{ $t("concepts." + concept) }}
        span(v-if="!(conceptsUsed && conceptsUsed.length)")
          | {{ $t("teacher.none") }}
    .col-xs-2
      div(v-if="playUrl")
        a.play-level-btn.btn.btn-navy-alt(v-if="complete", :href="playUrl")
          | {{ $t('play.replay') }}
        a.play-level-btn.btn.btn-forest(v-else-if="started", :href="playUrl")
          | {{ $t('courses.keep_trying') }}
        a.play-level-btn.btn.btn-navy(v-else, :href="playUrl")
          | {{ $t('courses.start_challenge') }}
      div(v-else)
        a.btn.btn-gray-alt(disabled)
          | {{ $t('courses.locked') }}

</template>

<script lang="coffee">
module.exports = Vue.extend({
  props: [
    # level properties
    'assessment'
    'assessmentPlacement'
    'primaryConcept'
    'name'
    'goals'

    # session properties
    'complete'
    'started'
    'goalStates'

    # computed
    'playUrl'
  ],
  
  computed: {
    isCumulative: -> @assessment is 'cumulative'
    conceptGoals: ->
      return @goals.filter((g) => g.concepts?.length)
    conceptGoalsCompleted: ->
      return @conceptGoals.filter((g) => @goalStates?[g.id].status is 'success')
    conceptsUsed: ->
      return _.uniq(_.flatten(@conceptGoalsCompleted.map((g) => g.concepts)))
}
})
</script>

<style lang="sass">
.level-row
  padding: 4px 0
  border-bottom: 1px solid #ccc

  .btn
    min-width: 140px
    margin-top: 7px


</style>
