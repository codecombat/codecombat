<template lang="pug">
  li(:class="goalClass" v-if="showGoal")
    i(v-if="state.status === 'incomplete' && isConceptGoal")=" • "
    i.glyphicon(:class="iconClass" v-else)
    | {{ goalText }}
</template>

<script lang="coffee">
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
    }
  })
</script>

<style lang="sass" scoped>
  li
    list-style: none
    margin-right: 5px
    i
      margin-right: 5px

  li.status-incomplete
    color: #333

  li.status-failure
    color: darkred

  li.status-success
    color: darkgreen
</style>
