<script>
import LayoutChrome from '../../common/LayoutChrome'
import LayoutCenterContent from '../../common/LayoutCenterContent'
import BaseVideo from '../common/BaseVideo'
import { getCutscene } from '../../../api/cutscene';

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
    vimeoId: null
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
    this.loadCutscene()
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
    },
    async loadCutscene() {
      const cutscene = await getCutscene(this.cutsceneId)
      this.vimeoId = cutscene.vimeoId

      window.addEventListener('resize', this.onResize)
      this.onResize()
    }
  }
})
</script>

<template>
  <layout-chrome>
    <layout-center-content>
      <div id="cutscene-player"
      :style="{ width: width+'px', height: height+'px' }" v-if="vimeoId">
      <!-- Currently this video is a hard coded example, that will be fetched from Cutscene collection -->
        <base-video
          :vimeoId="vimeoId"
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

