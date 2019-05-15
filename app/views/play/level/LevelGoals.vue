<template lang="pug">
  div
    // TODO: Split this into two components, one the ul, the other the goals-status
    ul#primary-goals-list(dir="auto")
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
      
    div.goals-status.rtl-allowed(v-if="showStatus")
      span {{ $t("play_level.goals") }}
      span.spr :
      span(v-if="classToShow === 'running'").goal-status.running {{ $t("play_level.running") }}
      span(v-if="classToShow === 'success'").goal-status.success {{ $t("play_level.success") }}
      span(v-if="classToShow === 'incomplete'").goal-status.incomplete {{ $t("play_level.incomplete") }}
      span(v-if="classToShow === 'timed-out'").goal-status.timed-out {{ $t("play_level.timed_out") }}
      span(v-if="classToShow === 'failing'").goal-status.failure {{ $t("play_level.failing") }}

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
      classToShow: ->
        classToShow = 'success' if @overallStatus is 'success'
        classToShow = 'incomplete' if @overallStatus is 'failure'
        classToShow ?= 'timed-out' if @timedOut
        classToShow ?= 'incomplete'
        classToShow = 'running' if @casting
        return classToShow
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
      LevelGoal
    }
  })
</script>

<style lang="sass" scoped>
  .goals-status
    margin: 5px 0 0 0
    position: absolute
    color: white
    text-transform: uppercase

    &[dir="rtl"]
      right: 0

    .success
      color: lightgreen
      text-shadow: 1px 1px 0px black
    .timed-out
      color: rgb(230, 230, 230)
    .failure
      color: rgb(239, 61, 71)
      text-shadow: 1px 1px 0px black
    .incomplete
      color: rgb(245, 170, 49)
    .running
      color: rgb(200, 200, 200)
  
  ul
    padding-left: 0
    margin-bottom: 0
    color: black

    body[lang="he"] &, body[lang="ar"] &, body[lang="fa"] &, body[lang="ur"] &
      padding-right: 0
  
  #concept-goals-list
    margin-left: 20px



</style>
