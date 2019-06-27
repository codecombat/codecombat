<template>
  <li class="goal">
    <p class="rectangle"></p>
    <img v-if="complete"
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
      goalClass: -> "status-#{@state.status}"
      iconClass: -> stateIconMap[@state.status] or ''
      complete: -> @state.status == 'complete'
    }
  })
</script>

<style scoped>
  .rectangle {
    height: 18px;
    width: 18px;
    border: 2px solid #000;
    margin-right: 5px;
    background-color: #FFFFFF;
    box-shadow: inset 1px 1px 3px 0 #5D73E1;
  }

  .check-mark {
    position: absolute;
    left: 10%;
    z-index: 5;
    width: 15px;
  }

  .goal {
    display: flex;
  }
</style>
