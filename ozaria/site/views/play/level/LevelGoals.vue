<template lang="pug">
  div
    div.goals-status.rtl-allowed(v-if="showStatus")
      span {{ $t("play_level.goals") }}
      span.spr :
      span {{ $t("play_level." + goalStatus) }}
    div.level-goals
      // TODO: Split this into two components, one the ul, the other the goals-status
      ul#primary-goals-list(dir="auto")
        level-goal(
          v-for="goal in levelGoals",
          :goal="goal",
          :state="goalStates[goal.id]",
        )
        level-goal(
          v-for="goal in levelGoals",
          :goal="goal",
          :state="goalStates[goal.id]",
        )
      level-goal(
        v-if="conceptGoals.length",
        :goal="{ name: $t('play_level.use_at_least_one_concept') }",
        :state="{ status: conceptStatus }",
      )
      ul#concept-goals-list(dir="auto" v-if="conceptGoals.length")
        level-goal.concept-goal(
          v-for="goal in conceptGoals",
          :goal="goal",
          :state="goalStates[goal.id]",
        )
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
    },
    
    computed: {
      goalStatus: ->
        goalStatus = 'success' if @overallStatus is 'success'
        goalStatus = 'incomplete' if @overallStatus is 'failure'
        goalStatus ?= 'timed-out' if @timedOut
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
  .goals-status
    position: fixed
    width: 100%
    background: black
    color: white
    height: 20px

  .level-goals
    display: inline-block
    margin: 5px 0 0 0
    width: 100%
    background: rgb(60, 60, 60)
    white-space: nowrap
    padding-top: 1.5em

  ul
    list-style-type: none
    margin: 0
    padding-left: 5px
</style>
