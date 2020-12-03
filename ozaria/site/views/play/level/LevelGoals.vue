<template>
  <div>
    <div v-if="showStatus" class="goals-status rtl-allowed">
      <span class="goal-status-text">{{ $t("play_level.goals") }} : {{ $t("play_level." + goalStatus) }}</span>
    </div>
    <div class="level-goals">
      <!-- TODO: Split this into two components, one the ul, the other the goals-status-->
      <ul id="primary-goals-list" dir="auto">
        <level-goal v-for="goal in levelGoals"
                    :key="goal.id"
                    :goal="goal"
                    :state="goalStates[goal.id]">
        </level-goal>
      </ul>
      <level-goal v-if="conceptGoals.length"
                  :goal="{ name: $t('play_level.use_at_least_one_concept') }"
                  :state="{ status: conceptStatus }">
      </level-goal>
      <ul id="concept-goals-list" dir="auto" v-if="conceptGoals.length">
        <level-goal v-for="goal in conceptGoals"
                    :key="goal.id"
                    class="concept-goal"
                    :goal="goal"
                    :state="goalStates[goal.id]">
        </level-goal>
      </ul>
    </div>
  </div>
</template>

<script lang="coffee">
  {me} = require 'core/auth'
  utils = require 'core/utils'
  LevelGoal = require('./LevelGoal').default

  module.exports = Vue.extend({
    props: ['showStatus']

    data: -> {
      overallStatus: ''
      timedOut: false
      goals: [] # TODO: Get goals, goalStates from vuex
      goalStates: {}
      capstoneStage: null
      casting: false
    }

    computed: {
      goalStatus: ->
        goalStatus = 'success' if @overallStatus is 'success'
        goalStatus = 'incomplete' if @overallStatus is 'failure'
        goalStatus ?= 'timed_out' if @timedOut
        goalStatus ?= 'incomplete'
        goalStatus = 'running' if @casting
        return goalStatus
      levelGoals: ->
        filtered = @goals.filter((g) => not g.concepts?.length).filter((g) =>
          # For all non-capstone goals, we how all incomplete goals
          if !@capstoneStage || !g.stage || @goalStates[g.id].status != 'success'
            return true

          # For the current capstone stage, we show all goals:
          return @capstoneStage == g.stage
        )
        # Scroll goals into view if necessary (TODO: better suited as a watch trigger):
        @refreshGoalsView(filtered)

        return filtered
      conceptGoals: ->
        @goals.filter((g) => g.concepts?.length)
      conceptStatus: ->
        for goal in @conceptGoals
          state = @goalStates[goal.id]
          if state?.status is 'success'
            return 'success'
        return 'incomplete'
    }

    methods: {
      refreshGoalsView: (filtered) ->
        # Scroll goals into view if more goals remain
        if filtered.length > 2 and
            filtered.filter((g) => @goalStates[g.id].status == 'success').length > 0 and
            filtered.filter((g) => @goalStates[g.id].status != 'success').length > 0
          goalsView = $('#goals-view')
          # Defensive in case this is somehow rendered when no goals are meant to be displayed
          if goalsView && goalsView.animate
            goalsView.animate({ scrollTop: (goalsView[0].scrollHeight - goalsView[0].clientHeight ) / 2 })
    }

    components: {
      'level-goal': LevelGoal
    }
  })
</script>

<style lang="sass" scoped>
  @import "ozaria/site/styles/common/variables"
  .goals-status
    position: absolute
    display: flex
    align-items: center
    width: 100%
    background: black
    height: 30%
    color: #FFFFFF
    font-family: $title-font-style
    font-size: 20px
    letter-spacing: 0.69px
    line-height: 25px
    z-index: 1
    padding-left: 13px

  .level-goals
    position: absolute
    top: 30%
    display: inline-block
    width: 100%
    background: rgb(60, 60, 60)
    white-space: nowrap
    overflow-x: scroll
    padding: 2% 2% 10px 2%

  ul
    list-style-type: none
    margin: 0
    padding-left: 5px

  .goal-status-text
    white-space: nowrap
    overflow: hidden
</style>
