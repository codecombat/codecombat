<template>
  <div>
    <div v-if="showStatus" class="goals-status rtl-allowed">
      <span>{{ $t("play_level.goals") }} : {{ $t("play_level." + goalStatus) }}</span>
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
        @goals.filter((g) => not g.concepts?.length)
      conceptGoals: ->
        @goals.filter((g) => g.concepts?.length)
      conceptStatus: ->
        for goal in @conceptGoals
          state = @goalStates[goal.id]
          if state?.status is 'success'
            return 'success'
        return 'incomplete'
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
    padding: 2%

  ul
    list-style-type: none
    margin: 0
    padding-left: 5px
</style>
