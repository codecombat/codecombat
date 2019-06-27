<template>
  <li class="goal">
    <p class="rectangle"></p>
    <img v-if="goalComplete"
         class="check-mark" alt="Checked box"
         src="/images/ozaria/level/check_mark.png" />
    {{ goalText }}
  </li>
</template>

<script lang="coffee">

#  li(:class="goalClass" v-if="showGoal")
#  i(v-if="state.status === 'incomplete' && isConceptGoal")=" • "
#  i.glyphicon(:class="iconClass" v-else)
#  | {{ goalText }}

  {me} = require 'core/auth'
  utils = require 'core/utils'

  stateIconMap =
    success: 'glyphicon-ok'
    failure: 'glyphicon-remove'

  module.exports = Vue.extend({
    props: {
      goal: {type: Object}
      state: {type: Object, default: () -> { status: 'incomplete' }}
    },
    computed: {
      showGoal: ->
        console.log('inside showGoal with status; ', @)
        return false if @goal.optional and @$store.state.game.level.type is 'course' and @state.status isnt 'success'
        if @goal.hiddenGoal
          return false if @goal.optional and @state.status isnt 'success'
          return false if not @goal.optional and @state.status isnt 'failure'
        return false if @goal.team and me.team isnt @goal.team
        return true
      isConceptGoal: ->
        @goal.concepts?.length
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
      iconClass: -> stateIconMap[@state.status] or ''
    }
  })
</script>

<style scoped>
  .goal {
    display: flex;
    font-family: Open Sans;
    height: 23px;
    color: #FFFFFF;
    font-size: 16px;
    letter-spacing: 0.55px;
    line-height: 22px;
    font-weight: lighter;
    margin-bottom: 7px;
  }

  .rectangle {
    height: 19px;
    width: 18px;
    border-radius: 4px;
    margin-right: 5px;
    background-color: #FFFFFF;
    box-shadow: inset 1px 1px 3px 0 #5D73E1;
  }

  .check-mark {
    position: absolute;
    left: 1.2%;
    width: 21px;
  }
</style>
