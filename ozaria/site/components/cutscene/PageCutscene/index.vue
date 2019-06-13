<script>
import LayoutChrome from '../../common/LayoutChrome'
import LayoutCenterContent from '../../common/LayoutCenterContent'
import BaseVideo from '../common/BaseVideo'

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
    'layout-center-content': LayoutCenterContent,
    'base-video': BaseVideo
  },
  mounted: function() {
    if (!me.hasCutsceneAccess()) {
      return application.router.navigate('/', { trigger: true })
    }

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

      this.height = Math.min(userWidth / CUTSCENE_ASPECT_RATIO, userHeight)
      this.width = this.height * CUTSCENE_ASPECT_RATIO
    }
  }
})
</script>

<template>
  <layout-chrome>
    <layout-center-content>
      <div id="cutscene-player"
      :style="{ width: width+'px', height: height+'px' }">
      <!-- Currently this video is a hard coded example, that will be fetched from Cutscene collection -->
        <base-video
          videoSrc="https://assets.koudashijie.com/CoCo%E7%AE%80%E4%BB%8B.mp4"
          :captions="[{
            label:'English captions',
            src:'/captions/example.vtt',
            srclang:'en'
          }]"
          :width="width"
          :height="height"
        />
      </div>
    </layout-center-content>
  </layout-chrome>

</template>

<style lang="sass">

#cutscene-player
  margin-left: auto
  margin-right: auto

</style>

