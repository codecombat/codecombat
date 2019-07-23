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
    vimeoId: null
  }),

  components: {
    LayoutChrome,
    BaseVideo
  },

  mounted: function() {
    if (!me.hasCutsceneAccess()) {
      return application.router.navigate('/', { trigger: true })
    }
    this.loadCutscene()
  },

  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn'
    }),
  },

  methods: {
    async loadCutscene() {
      // TODO handle_error_ozaria - What if unable to fetch cutscene?
      const cutscene = await getCutscene(this.cutsceneId)
      this.vimeoId = cutscene.vimeoId
    },

    onCompleted() {
      this.$emit('completed')
    }
  }
})
</script>

<template>
  <layout-chrome>
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
  @import "ozaria/site/styles/common/variables.sass"

  #cutscene-player
    width: calc(100vw - #{$chromeRightPadding + $chromeLeftPadding})
    height: calc(100vh - #{$chromeTopPadding + $chromeBottomPadding})

</style>

