<template lang="jade">
  div
    ul#primary-goals-list(dir="auto")
      level-goal(
        v-for="goal in goals",
        :goal="goal",
        :state="goalStates[goal.id]",
        :level="level"
      )
    div.goals-status.rtl-allowed
      span {{ $t("play_level.goals") }}
      span.spr :
      span(v-if="classToShow === 'running'").goal-status.running {{ $t("play_level.running") }}
      span(v-if="classToShow === 'success'").goal-status.success {{ $t("play_level.success") }}
      span(v-if="classToShow === 'incomplete'").goal-status.incomplete {{ $t("play_level.incomplete") }}
      span.goal-status.complete-one(v-if="classToShow === 'complete-one'") 1 MORE REQUIRED
      span(v-if="classToShow === 'timed-out'").goal-status.timed-out {{ $t("play_level.timed_out") }}
      span(v-if="classToShow === 'failing'").goal-status.failure {{ $t("play_level.failing") }}

</template>

<script lang="coffee">
  {me} = require 'core/auth'
  utils = require 'core/utils'
  LevelGoal = require('./LevelGoal').default

  module.exports = Vue.extend({
    data: -> {
      overallStatus: ''
      timedOut: false
      goals: []
      goalStates: {}
      casting: false
      level: {}
    },
    
    computed: {
      classToShow: ->
        classToShow = 'success' if @overallStatus is 'success'
        classToShow = 'incomplete' if @overallStatus is 'failure'
        classToShow ?= 'timed-out' if @timedOut
        classToShow ?= 'incomplete'
        if @level.assessment is 'cumulative' and classToShow in ['failure', 'timed-out']
          classToShow = 'complete-one'
        classToShow = 'running' if @casting
        return classToShow
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
    .incomplete, .complete-one
      color: rgb(245, 170, 49)
    .running
      color: rgb(200, 200, 200)
  
  ul
    padding-left: 0
    margin-bottom: 0
    color: black

    body[lang="he"] &, body[lang="ar"] &, body[lang="fa"] &, body[lang="ur"] &
      padding-right: 0



</style>
