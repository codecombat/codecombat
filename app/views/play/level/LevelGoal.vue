<template lang="pug">
  li(:class="goalClass" v-if="showGoal" :title="goalTitle")
    i(v-if="state.status === 'incomplete' && isConceptGoal")=" • "
    i(v-else-if="product === 'codecombat-junior' && !iconClass") …
    i.glyphicon(:class="iconClass" v-else)
    span(v-if="goalIconImages && goalIconImages.length")
      img.goal-icon(
        v-for="goalIconImage in goalIconImages"
        :src="goalIconImage"
        alt="")
    span(v-if="goalText") {{ goalText }}
</template>

<script lang="coffee">
  {me} = require 'core/auth'
  utils = require 'core/utils'

  stateIconMap =
    success: 'glyphicon-ok'
    failure: 'glyphicon-remove'

  goalIconImageMap =
    saveThangs: '/images/level/goal-icons/save-thangs.png'
    saveThangsEmpty: '/images/level/goal-icons/save-thangs-empty.png'
    killThangs: '/images/level/blocks/block-hit.png'
    collectThangs: '/images/pages/play/level/modal/reward_icon_gems.png'
    getToLocations: '/images/level/goal-icons/get-to-locations.png'  # TODO: raft
    getAllToLocations: '/images/level/goal-icons/get-to-locations.png'  # TODO: raft
    #codeProblems: ''
    linesOfCode: '/images/level/goal-icons/lines-of-code.png'

  goalIconMap =
    #getToLocations: '⛵'
    #getAllToLocations: '⛵'
    codeProblems: '🐛'

  module.exports = Vue.extend({
    props: {
      goal: {type: Object}
      state: {type: Object, default: () -> { status: 'incomplete' }}
      product: {type: String}
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

      goalIconImages: ->
        result = []
        return result unless @product is 'codecombat-junior'
        for key, icon of goalIconImageMap when @goal[key]
          if key is 'saveThangs' and not (_.values(@state.killed).length > 1) and @$store.state.game.heroHealth.max
            # saveThangs with just the hero; show hearts
            fullHearts = @$store.state.game.heroHealth.current || 0
            emptyHearts = (@$store.state.game.heroHealth.max || 1) - fullHearts
            result.push(icon) for i in [0 ... fullHearts]
            result.push(goalIconImageMap.saveThangsEmpty) for i in [0 ... emptyHearts]
          else
            result.push(icon)
          break
        return result

      goalTitle: -> utils.i18n @goal, 'name'

      goalText: ->
        text = ''
        if @product is 'codecombat-junior'
          for key, value of goalIconMap when @goal[key] and not text
            text = value
        else
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
            if @product is 'codecombat-junior'
              text = text + "#{completed}/#{targeted}"
            else
              text = text + " (#{completed}/#{targeted})"
        if @state.collected and @product is 'codecombat-junior'
          collected = _.filter(_.values(@state.collected)).length
          targeted = _.values(@state.collected).length
          if targeted > 1
            completed = collected
            text = text + "#{completed}/#{targeted}"
        if @state.lines and @product is 'codecombat-junior'
          text = text + " #{@state.lines.used}/#{@state.lines.allowed}"

        return text

      goalClass: -> "status-#{@state.status} #{@product}"

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

  li.codecombat-junior
    margin-right: 15px

  li.status-incomplete
    color: #333

  li.status-failure
    color: darkred

  li.status-success
    color: darkgreen

  img.goal-icon
    width: 1.3em
    margin-top: -0.4em
</style>
