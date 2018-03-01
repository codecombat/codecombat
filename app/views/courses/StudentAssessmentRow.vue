<template lang="jade">
  .row.level-row
    .col-xs-5
      div.level-type
        span(v-if="assessment === 'open-ended' && assessmentPlacement === 'middle'")
          | {{ $t('teacher.mid_course') }}
        span(v-else-if="assessment === 'open-ended' && assessmentPlacement === 'end'")
          | {{ $t('teacher.end_course') }}
        span(v-else-if="primaryConcept")
          | {{ $t('concepts.' + primaryConcept) }}

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
          span(v-if="scoreString")
            img.threshold-icon(:src="scoreIconUrl" v-if="thresholdAchieved")
            =" "
            | ({{ scoreString }})
          br
        span(v-else-if="started")
          span.glyphicon.glyphicon-question-sign.in-progress-symbol.text-gold
          =" "
          | {{ $t('teacher.in_progress') }}
        span(v-else)
          span.glyphicon.glyphicon-question-sign.not-started-symbol.text-gray
          =" "
          | {{ $t('teacher.not_started') }}
      div.small(v-if="assessment === 'open-ended' && started")
        strong {{ $t('courses.concepts_used') }}
        =" "
        span(v-for="(concept, i) in codeConcepts || []")
          span(v-if="i > 0")
            =", "
          span {{ $t("concepts." + concept) }}
        span(v-if="!(codeConcepts && codeConcepts.length)")
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
    'scoreType'

    # session properties
    'complete'
    'started'
    'score'
    'codeConcepts'

    # computed
    'playUrl'
    'thresholdAchieved'
  ],
  
  computed: {
    scoreString: ->
      scoreType = @scoreType
      score = @score
      return '' unless scoreType and score?
      translatedScoreType = @$t("leaderboard.#{_.string.underscored(scoreType)}")
      translation = @$t("leaderboard.score_display", { score, scoreType: translatedScoreType })
      return translation
      
    scoreIconUrl: -> "/images/pages/courses/star-#{@thresholdAchieved}.png"
}
})
</script>

<style lang="sass">
.level-row
  padding: 4px 0
  border-bottom: 1px solid #ccc

  .threshold-icon
    height: 1.2em
    margin-left: 0.3em
    position: relative
    top: -0.1em

  .btn
    min-width: 140px
    margin-top: 7px


</style>
