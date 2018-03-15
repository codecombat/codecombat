<template lang="jade">
  .modal-content#course-victory-component
    .modal-header
      img.header-img(:src="headerImage")
      #close-modal.btn.well.well-sm.well-parchment(data-dismiss="modal")
        span.glyphicon.glyphicon-remove
  
    .modal-body
      .container-fluid
        .row
          .col-sm-12
            div.clearfix.well.well-sm.well-parchment(v-if="assessmentNext")
              img.lock-banner(src="/images/pages/play/modal/lock_banner.png")
              h5.text-uppercase
                span(v-if="nextAssessment.assessment === 'cumulative'")
                  | {{ $t('play_level.combo_challenge_unlocked') }}:
                span(v-else)
                  | {{ $t('play_level.concept_challenge_unlocked') }}:
              h3.text-uppercase
                | {{ $dbt(nextAssessment, 'name') }}
              div.no-imgs(v-html="marked($dbt(nextAssessment, 'description'))")
                
            div.clearfix.well.well-sm.well-parchment.combo-results(v-else-if="level.assessment === 'cumulative'")
              div.text-center.text-uppercase.pie-container
                pie-chart(:percent='percentConceptsCompleted', :stroke-width="10", label=" ", color="green", :opacity="1")
                h5 {{ $t('play_level.combo_concepts_used', { complete: conceptGoalsCompleted, total: conceptGoals.length }) }}
              div
                h3.text-uppercase {{ $t('play_level.combo_challenge_complete') }}
                div(v-if="allConceptsUsed")
                  | {{ $t('play_level.combo_all_concepts_used') }}
                div(v-else)
                  | {{ $t('play_level.combo_not_all_concepts_used', { complete: conceptGoalsCompleted, total: conceptGoals.length }) }}
              
                
            div.clearfix.well.well-sm.well-parchment(v-else-if="level.assessment")
              h3.text-uppercase {{ $t('play_level.concept_challenge_complete') }}
              div {{ $t('play_level.combo_challenge_complete_body', { concept: primaryConcept }) }}
                
            div.clearfix.well.well-sm.well-parchment(v-else)
              h3.text-uppercase
                | {{ $t('play_level.level_complete') }}: {{ $dbt(level, 'name')}}
              div(v-if="level.victory") {{ $dbt(level.victory, 'body') }}
              
        .row(v-if="assessmentNext")
          .col-sm-5.col-sm-offset-7
            a#start-challenge-btn.btn.btn-illustrated.btn-success.btn-block.btn-lg.text-uppercase(
              @click="onStartChallenge",
              :href="challengeLink"
            )
             | {{ $t('play_level.start_challenge') }}
        .row(v-else-if="level.assessment === 'cumulative'")
          .col-sm-5.col-sm-offset-7
            button#replay-level-btn.btn.btn-illustrated.btn-default.btn-block.btn-lg.text-uppercase(
              @click="onReplayLevel"
            )
              | {{ $t('play_level.replay_level') }}
            
            
        .row
          .col-sm-6.text-uppercase
            .well.well-sm.well-parchment
              h5 {{ $t('play_level.completed_level') }}
              h3 {{ $dbt(level, 'name') }}
              h5 {{ $dbt(course, 'name') }}
              h3(v-if="stats")
                | Levels Complete: {{ stats.levels.numDone }}/{{ stats.levels.size }}
          .col-sm-6(v-if="nextLevel._id")
            .well.well-sm.well-parchment
              h5.text-uppercase {{ $t('play_level.next_level') }}:
              h3.text-uppercase {{ $dbt(nextLevel, 'name') }}
              div.no-imgs(v-html="marked($dbt(nextLevel, 'description'))")
    
        .row
          .col-sm-6.text-uppercase
            a#map-btn.btn.btn-illustrated.btn-primary.btn-block.btn-lg.text-uppercase(
              @click="onBackToMap",
              :href="mapLink"
            )
              | {{ $t('play_level.back_to_map') }}
          .col-sm-6.text-uppercase(v-if="nextLevel._id")
            a#next-level-btn.btn.btn-illustrated.btn-block.btn-lg.text-uppercase(
              @click="onNextLevel",
              :href="nextLevelLink",
              :class="nextLevelLinkClasses"
            )
              | {{ $t('play_level.next_level') }}


</template>

<script lang="coffee">
  PieChart = require('core/components/PieComponent').default
  utils = require 'core/utils'
  
  module.exports = Vue.extend({
    # TODO: Move these props to vuex
    props: ['nextLevel', 'nextAssessment', 'session', 'course', 'courseInstanceID', 'stats'],
    components: {
      PieChart
    }
    computed: {
      challengeLink: ->
        if me.isSessionless()
          link = "/play/level/#{@nextAssessment.slug}?course=#{@course._id}&codeLanguage=#{utils.getQueryVariable('codeLanguage', 'python')}"
        else
          link = "/play/level/#{@nextAssessment.slug}?course=#{@course._id}&course-instance=#{@courseInstanceID}"
          link += "&codeLanguage=" + @level.primerLanguage if @level.primerLanguage
        return link
      mapLink: ->
        if me.isSessionless()
          link = "/teachers/courses"
        else
          link = "/play/#{@course.campaignID}?course-instance=#{@courseInstanceID}"
        return link
      nextLevelLink: ->
        if me.isSessionless()
          link = "/play/level/#{@nextLevel.slug}?course=#{@course._id}&codeLanguage=#{utils.getQueryVariable('codeLanguage', 'python')}"
        else
          link = "/play/level/#{@nextLevel.slug}?course=#{@course._id}&course-instance=#{@courseInstanceID}"
          link += "&codeLanguage=" + @level.primerLanguage if @level.primerLanguage
        return link
      nextLevelLinkClasses: ->
        if @assessmentNext
          { 'btn-default': true }
        else
          { 'btn-success': true }
      headerImage: ->
        if @assessmentNext
          return "/images/pages/play/modal/challenge_unlocked.png"
        else if @level.assessment
          return "/images/pages/play/modal/challenge_complete.png"
        else
          return "/images/pages/play/modal/level_complete.png"
      assessmentNext: ->
        @nextAssessment._id
      primaryConcept: ->
        concept = _.first(@level.primaryConcepts)
        if concept
          return @$t("concepts.#{concept}")
        return concept
      conceptGoals: ->
        return @level.goals.filter((g) => g.concepts?.length)
      conceptGoalsCompleted: ->
        return @conceptGoals.filter((g) => @session.state.goalStates[g.id].status is 'success').length
      percentConceptsCompleted: ->
        return 100 * @conceptGoalsCompleted / @conceptGoals.length
      allConceptsUsed: ->
        @conceptGoalsCompleted is @conceptGoals.length
      level: -> @$store.state.game.level
    }
    methods: {
      marked
      onStartChallenge: ->
        window.tracker?.trackEvent(
          'Play Level Victory Modal Start Challenge',
            {
              category: 'Students',
              levelSlug: @level.slug, 
              nextAssessmentSlug: @nextAssessment.slug
            },
            []
        )
      onBackToMap: ->
        window.tracker?.trackEvent(
          'Play Level Victory Modal Back to Map',
            {
              category: 'Students',
              levelSlug: @level.slug
            }, 
            []
        )
      onNextLevel: ->
        window.tracker?.trackEvent(
          'Play Level Victory Modal Next Level',
            {
              category: 'Students'
              levelSlug: @level.slug
              nextLevelSlug: @nextLevel.slug
            },
            []
        )
      onReplayLevel: ->
        document.location.reload()

  }
  })
</script>

<style lang="sass">
  #course-victory-component
    img.header-img
      position: relative
      top: -15px
    
    h3
      margin-top: 0
      
    h5
      font-size: 18px
      margin: 0
      
    h3, h5
      color: black
  
    .lock-banner
      float: left
      width: 120px
      margin-right: 10px
    
    .well
      margin: 10px 0 0
  
    .modal-body
      padding: 0px 20px 0
      position: relative
      top: 80px
      margin-top: 80px
  
      @media screen and ( max-height: 650px )
        padding-top: 10px
  
      .well-parchment
        margin-top: 20px
  
        @media screen and ( max-height: 675px )
          margin-top: 0
    
    svg
      width: 60px
    
    .pie-container
      padding: 0 15px
      width: 250px
    
    .combo-results
      display: flex
    
    .no-imgs  
      // they are not necessarily built for the provided space, eg Wakka Maul
      img
        display: none
  
</style>
