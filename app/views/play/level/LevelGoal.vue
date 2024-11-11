<template lang="pug">
  li(:class="goalClass" v-if="showGoal" :title="goalTitle")
    i(v-if="state.status === 'incomplete' && isConceptGoal")=" • "
    img(v-else-if="product === 'codecombat-junior' && iconImageSrc" :src="iconImageSrc" alt="" class="goal-icon goal-icon-status")
    i.glyphicon(v-else-if="product !== 'codecombat-junior'" :class="iconClass")
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

  stateIconImageMap =
    success: '/images/level/goal-icons/checkmark.png'
    failure: '/images/level/goal-icons/red-x.png'

  goalIconImageMap =
    heart: '/images/level/goal-icons/heart.png'
    heartEmpty: '/images/level/goal-icons/heart-empty.png'
    saveThangs: '/images/level/goal-icons/save-thangs.png'
    killThangs: '/images/level/goal-icons/kill-thangs.png'
    collectThangs: '/images/level/goal-icons/collect-thangs.png'
    getToLocations: '/images/level/goal-icons/get-to-locations.png'
    getAllToLocations: '/images/level/goal-icons/get-to-locations.png'
    codeProblems: '/images/level/goal-icons/clean-code.png'
    linesOfCode: '/images/level/goal-icons/lines-of-code.png'

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
        return false if @state.lines and not @state.lines.allowed?
        return true

      isConceptGoal: ->
        @goal.concepts?.length

      goalIconImages: ->
        result = []
        return result unless @product is 'codecombat-junior'
        for key, icon of goalIconImageMap when @goal[key]
          if key is 'saveThangs' and @$store.state.game.heroHealth.max and @goal.saveThangs?[0] in ['Hero Placeholder', 'humans']
            # saveThangs with just the hero; show hearts
            fullHearts = Math.max 0, @$store.state.game.heroHealth.current || 0
            emptyHearts = (@$store.state.game.heroHealth.max || 1) - fullHearts
            result.push(goalIconImageMap.heart) for i in [0 ... fullHearts]
            result.push(goalIconImageMap.heartEmpty) for i in [0 ... emptyHearts]
          else
            result.push(icon)
          break
        return result

      goalTitle: -> utils.i18n @goal, 'name'

      goalText: ->
        text = ''
        if @product isnt 'codecombat-junior'
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
              if @goal.saveThangs?[0] not in ['Hero Placeholder', 'humans']
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
          if @state.lines.used? and @state.lines.allowed?
            text = text + " #{@state.lines.used}/#{@state.lines.allowed}"
          else
            text = text + '...'

        return text

      goalClass: -> "status-#{@state.status} #{@product}"

      iconClass: -> stateIconMap[@state.status] or ''

      iconImageSrc: -> stateIconImageMap[@state.status] or ''
    }
  })
</script>

<style lang="sass" scoped>
  li
    list-style: none
    margin-right: 5px
    i
      margin-right: 5px
    position: relative

  li.codecombat-junior
    margin-right: 15px
    background-color: rgb(166, 144, 115)
    border-radius: 8px
    padding-left: 9px
    padding-right: 9px

  li.status-incomplete
    color: #333

  li.status-failure
    color: darkred

  li.status-success
    color: darkgreen

  img.goal-icon
    width: 1.3em
    margin-top: -0.2em

  img.goal-icon.goal-icon-status
    position: absolute
    top: 0.1em
    right: -0.3em
    width: 0.8em
</style>
