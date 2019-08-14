<template>
  <LayoutChrome
    :title="title"
    :displayRestartMenuItem="canRestart()"
    :displayOptionsMenuItem=true
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
  import { mapGetters } from 'vuex'
  import PlayLevelView from 'ozaria/site/views/play/level/PlayLevelView'
  import BackboneViewHarness from 'app/views/common/BackboneViewHarness'
  import LayoutAspectRatioContainer from 'ozaria/site/components/common/LayoutAspectRatioContainer'
  import LayoutChrome from 'ozaria/site/components/common/LayoutChrome'
  import LayoutCenterContent from '../../common/LayoutCenterContent'
  import store from 'core/store'

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
    data: function () {
      return {
        backboneView: PlayLevelView
      }
    },
    methods: {
      clickRestart: function () {
        if (this.canRestart()) {
          Backbone.Mediator.publish('level:open-restart-modal', {})
        }
      },
      canRestart: function () {
        const level = Object.values(this.levelsList).find((l) => l.levelID === this.levelID)
        const isCapstone = level ? level.ozariaType === 'capstone' : false
        return me.isAdmin() || !isCapstone
      },
      clickOptions: function () {
        Backbone.Mediator.publish('level:open-options-modal', {})
      }
    },
    computed: {
      ...mapGetters({ levelsList: 'unitMap/getCurrentLevelsList' }),
      title () {
        return (store.state.game.level || {}).name
      }
    }
  })
</script>
