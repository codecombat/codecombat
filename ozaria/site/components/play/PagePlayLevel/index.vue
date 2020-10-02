<template>
  <LayoutChrome
    :title="title"
    :displayRestartMenuItem="canRestart()"
    :displayOptionsMenuItem=true
    :chromeOn="isChromeOn"
    @click-restart="clickRestart"
    @click-options="clickOptions"
  >
    <LayoutCenterContent>
      <LayoutAspectRatioContainer
        :aspect-ratio="1266 / 668"
      >
        <backbone-view-harness
          :backbone-view="backboneView"
          :backbone-options="{}"
          :backbone-args="[ levelID ]"
        />
      </LayoutAspectRatioContainer>
    </LayoutCenterContent>
  </LayoutChrome>
</template>

<script>
  import PlayLevelView from 'ozaria/site/views/play/level/PlayLevelView'
  import BackboneViewHarness from 'app/views/common/BackboneViewHarness'
  import LayoutAspectRatioContainer from 'ozaria/site/components/common/LayoutAspectRatioContainer'
  import LayoutChrome from 'ozaria/site/components/common/LayoutChrome'
  import LayoutCenterContent from '../../common/LayoutCenterContent'
  import store from 'core/store'
  import utils from 'core/utils'

  module.exports = Vue.extend({
    components: {
      LayoutAspectRatioContainer,
      LayoutChrome,
      BackboneViewHarness,
      LayoutCenterContent
    },
    props: {
      levelID: {
        type: String,
        required: true
      }
    },
    data () {
      return {
        backboneView: PlayLevelView
      }
    },
    methods: {
      clickRestart () {
        if (this.canRestart()) {
          Backbone.Mediator.publish('level:open-restart-modal', {})
        }
      },
      canRestart () {
        const isCapstone = (store.state.game.level || {}).ozariaType === 'capstone'
        return me.isAdmin() || !isCapstone
      },
      clickOptions () {
        Backbone.Mediator.publish('level:open-options-modal', {})
      }
    },
    computed: {
      title () {
        let levelData = store.state.game.level || {}
        return utils.i18n(levelData, "displayName") || utils.i18n(levelData, "name")
      },
      isChromeOn () {
        return (store.state.game.level || {}).ozariaType === 'capstone'
      },
    }
  })
</script>
