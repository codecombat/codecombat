<template>
  <li class="goal" v-if="showGoal">
    <p class="rectangle"></p>
    <img v-if="goalComplete"
         class="check-mark" alt="Check mark for checkbox"
         src="/images/ozaria/level/check_mark.png" />
    {{ goalText }}
  </li>
</template>

<script lang="coffee">
  {me} = require 'core/auth'
  utils = require 'core/utils'

  module.exports = Vue.extend({
    props: {
      goal: {type: Object}
      state: {type: Object, default: () -> { status: 'incomplete' }}
    },
    computed: {
      showGoal: ->
        return false if @goal.optional and @$store.state.game.level.type is 'course' and @state.status isnt 'success'
        if @goal.hiddenGoal
          return false if @goal.optional and @state.status isnt 'success'
          return false if not @goal.optional and @state.status isnt 'failure'
        return false if @goal.team and me.team isnt @goal.team
        return true
      goalText: ->
        text = utils.i18n @goal, 'name'
        if @state.killed
          dead = _.filter(_.values(@state.killed)).length
          targeted = _.values(@state.killed).length
          if targeted > 1
            # Does this make sense?
            if @goal.isPositive
              completed = dead
            else
              completed = targeted - dead
            text = text + " (#{completed}/#{targeted})"

        return text
      goalComplete: -> @state.status == 'success'
    }
  })
</script>

<style lang="sass" scoped>
  @import "ozaria/site/styles/common/variables"

  .goal
    display: flex
    font-family: $body-font-style
    height: 23px
    color: #FFFFFF
    font-size: 16px
    letter-spacing: 0.55px
    line-height: 22px
    font-weight: lighter

  .rectangle
    height: 19px
    width: 18px
    border-radius: 4px
    margin-right: 10px
    background-color: #FFFFFF
    box-shadow: inset 1px 1px 3px 0 #5D73E1

  .check-mark
    position: absolute
    left: 2.7%
    width: 20px
</style>
