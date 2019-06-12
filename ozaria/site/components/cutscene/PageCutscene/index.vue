<script>
import LayoutChrome from '../../common/LayoutChrome'
import LayoutCenterContent from '../../common/LayoutCenterContent'
const Plyr = require('plyr')
import 'plyr/dist/plyr.css'

const CUTSCENE_ASPECT_RATIO = 16 / 9

module.exports = Vue.extend({
  props: {
    cutsceneId: {
      type: String,
      required: true
    }
  },
  data: () => ({
    width: 1920,
    height: 1080,
  }),
  components: {
    'layout-chrome': LayoutChrome,
    'layout-center-content': LayoutCenterContent
  },
  mounted: function() {
    if (!me.hasCutsceneAccess()) {
      return application.router.navigate('/', { trigger: true })
    }
    const player_div = this.$refs['player']
    new Plyr(player_div);

    window.addEventListener('resize', this.onResize)
    this.onResize()

  },
  destroyed() {
    window.removeEventListener("resize", this.onResize)
  },
  methods: {
    onResize: function() {
      const userWidth = window.innerWidth
        || document.documentElement.clientWidth
        || document.body.clientWidth

      const userHeight = window.innerHeight
        || document.documentElement.clientHeight
        || document.body.clientHeight

      const height = this.height = Math.min(userWidth / CUTSCENE_ASPECT_RATIO, userHeight)
      const width = this.width = Math.min(userWidth, userHeight * CUTSCENE_ASPECT_RATIO)
    }
  }
})
</script>

<template>
  <layout-chrome>
    <layout-center-content>
      <div id="cutscene-player"
      :style="{ width: width+'px', height: height+'px' }">
        <div
          id="player"
          ref="player"
          data-plyr-provider="vimeo"
          v-bind:data-plyr-embed-id="cutsceneId"
        >
      </div>
      </div>
    </layout-center-content>
  </layout-chrome>

</template>

<style lang="sass">

#cutscene-player
  margin-left: auto
  margin-right: auto

</style>

