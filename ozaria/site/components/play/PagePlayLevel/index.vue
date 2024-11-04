<template>
  <LayoutChrome
    :title="title"
    :display-restart-menu-item="canRestart()"
    :display-options-menu-item="true"
    :display-ai-hint-button="hasAIEnabled"
    :chrome-on="isChromeOn"
    @click-restart="clickRestart"
    @click-options="clickOptions"
  >
    <LayoutCenterContent>
      <LayoutAspectRatioContainer
        :aspect-ratio="1266 / 668"
      >
        <backbone-view-harness
          :backbone-view="backboneView"
          :backbone-options="{ supermodel: getSupermodel() }"
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
import { mapGetters, mapActions } from 'vuex'

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
      backboneView: PlayLevelView,
      levelNumber: ''
    }
  },
  computed: {
    ...mapGetters({
      getLevelNumber: 'gameContent/getLevelNumber'
    }),
    title () {
      const levelData = store.state.game.level || {}
      const title = utils.i18n(levelData, 'displayName') || utils.i18n(levelData, 'name') || ''
      return `${this.levelNumber ? `${this.levelNumber}.` : ''} ${title || ''}`
    },
    isChromeOn () {
      return (store.state.game.level || {}).ozariaType === 'capstone'
    },
    hasAIEnabled () {
      return store.state.game.aiHintVisible
    },
    campaignId () {
      return (store.state.game.level || {}).campaign
    },
    levelOriginal () {
      return store.state?.game?.level?.original
    },
  },
  watch: {
    campaignId (newCampaign) {
      if (newCampaign) {
        this.fetchLevelNumber()
      }
    },
    levelOriginal () {
      this.fetchLevelNumber()
    },
  },
  mounted () {
    if (this.campaignId) {
      this.fetchLevelNumber()
    }
  },
  methods: {
    ...mapActions({
      generateLevelNumberMap: 'gameContent/generateLevelNumberMap'
    }),
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
    },
    getSupermodel () {
      return window.temporarilyPreservedSupermodel // May be undefined, or may be set for one frame when transitioning from previous level
    },
    fetchLevelNumber () {
      this.generateLevelNumberMap({
        campaignId: store.state.game.level.campaign,
        language: utils.getQueryVariable('codeLanguage') || 'python'
      }).then(() => {
        this.levelNumber = this.getLevelNumber(store.state.game.level.original)
      })
    },
  }
})
</script>
