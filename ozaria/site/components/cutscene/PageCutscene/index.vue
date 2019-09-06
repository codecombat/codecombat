<script>
import { mapGetters } from 'vuex'

import LayoutChrome from '../../common/LayoutChrome'
import BaseVideo from '../common/BaseVideo'
import { getCutscene } from '../../../api/cutscene'

module.exports = Vue.extend({
  props: {
    cutsceneId: {
      type: String,
      required: true
    }
  },

  data: () => ({
    vimeoId: null,
    cutscene: {}
  }),

  components: {
    LayoutChrome,
    BaseVideo
  },

  mounted: function() {
    this.loadCutscene()

    // TODO: Do we still need this localhost workaround for private videos?
    // Provides a way to skip cutscenes via the terminal.
    window.forceCutsceneCompleted = this.onCompleted
  },

  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn'
    }),
  },

  methods: {
    async loadCutscene() {
      // TODO handle_error_ozaria - What if unable to fetch cutscene?
      this.cutscene = await getCutscene(this.cutsceneId)
      this.vimeoId = this.cutscene.vimeoId
    },

    onCompleted() {
      this.$emit('completed', this.cutscene)
    }
  }
})
</script>

<template>
  <layout-chrome
    :title="cutscene.name"
  >
    <button id="skip-btn" @click="onCompleted">Skip Video</button>
    <base-video
      v-if="vimeoId"

      id="cutscene-player"
      :vimeoId="vimeoId"
      :soundOn="soundOn"

      v-on:completed="onCompleted"
    />
  </layout-chrome>
</template>

<style lang="sass">
  @import "ozaria/site/styles/common/variables.scss"

  button#skip-btn
    position: fixed
    top: 100px
    right: 100px
    height: 35px
    font-size: 18px
    font-family: Work Sans
    color: $acodus-glow
    background-color: rgba(0, 0, 0, 0.7)
    border: unset
    min-width: 150px
    height: 39px

  #cutscene-player
    width: calc(100vw - #{$chromeRightPadding + $chromeLeftPadding})
    height: calc(100vh - #{$chromeTopPadding + $chromeBottomPadding})

</style>

