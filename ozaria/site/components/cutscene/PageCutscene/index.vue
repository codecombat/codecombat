<script>
import { mapGetters } from 'vuex'
import _ from 'lodash'
import utils from 'core/utils'
import LayoutChrome from '../../common/LayoutChrome'
import BaseVideo from '../common/BaseVideo'
import { getCutscene } from '../../../api/cutscene'
import { cutsceneEvent } from '../common/cutsceneUtil'
import LayoutAspectRatioContainer from '../../common/LayoutAspectRatioContainer'
import LayoutCenterContent from '../../common/LayoutCenterContent'
import CloudflareVideoPlayer from '../common/CloudflareVideoPlayer'

const throttledSkippedCutsceneEvent = _.once(cutsceneEvent)

module.exports = Vue.extend({
  props: {
    cutsceneId: {
      type: String,
      required: true
    }
  },

  data: () => ({
    vimeoId: null,
    videoSrc: null,
    captions: ()=>([]),
    cutscene: {},
    cloudflareID: null
  }),

  components: {
    LayoutChrome,
    BaseVideo,
    LayoutAspectRatioContainer,
    LayoutCenterContent,
    CloudflareVideoPlayer
  },

  mounted () {
    this.loadCutscene()
  },

  beforeDestroy () {
    cutsceneEvent('Unloaded Cutscene', {cutsceneId: this.cutsceneId})
  },

  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn'
    }),
    title(){
      return utils.i18n(this.cutscene, 'displayName') || utils.i18n(this.cutscene, 'name')
    }
  },

  methods: {
    async loadCutscene() {
      // TODO handle_error_ozaria - What if unable to fetch cutscene?

      const cutscene = this.cutscene = await getCutscene(this.cutsceneId)

      if (me.showChinaVideo() && cutscene.chinaVideoSrc) {
        this.videoSrc = cutscene.chinaVideoSrc
      } else if (cutscene.cloudflareID) {
        this.cloudflareID = cutscene.cloudflareID
      } else {
        this.vimeoId = cutscene.vimeoId
      }

      /**
       * Captions need to be a valid array, for the Plyr video player.
       */
      this.captions = Object.keys(cutscene.i18n || {})
        .filter((i18nKey) => {
          if (i18nKey === '-' || !cutscene.i18n[i18nKey].captions) {
            return false;
          }
          const { src, label } = cutscene.i18n[i18nKey].captions
          return label && src
        }).map(i18nKey => ({
          label: cutscene.i18n[i18nKey].captions.label,
          src: `/file/${cutscene.i18n[i18nKey].captions.src}`,
          srclang: i18nKey
        }))
      cutsceneEvent('Loaded Cutscene', {cutsceneId: this.cutsceneId})
    },

    onCompleted() {
      this.$emit('completed', this.cutscene)
      cutsceneEvent('Completed Cutscene', {cutsceneId: this.cutsceneId})
    },

    handleSkip() {
      this.pauseCutscene()
      this.onCompleted()
      throttledSkippedCutsceneEvent('Skipped Cutscene', {cutsceneId: this.cutsceneId})
    },

    pauseCutscene () {
      const videoPlayer = this.$refs['china-player'] || this.$refs['vimeo-player'] || this.$refs['cloudflare-player']
      if (videoPlayer) {
        if (this.cloudflareID && videoPlayer && typeof videoPlayer.pauseVideo === 'function') {
          videoPlayer.pauseVideo()
        } else if (videoPlayer.$refs['player']) { // for china player and vimeo player
          videoPlayer.$refs['player'].pause()
        }
      }
    }
  }
})
</script>

<template>
  <layout-chrome
      :title="title"
      @pause-cutscene="pauseCutscene"
  >
    <!-- CLOUDFLARE PLAYER -->
    <CloudflareVideoPlayer
      ref="cloudflare-player"
      v-if="cloudflareID"

      :cutscene="cutscene"
      :cloudflareID="cloudflareID"
      :soundOn="soundOn"

      v-on:completed="onCompleted"
    />
    <!-- VIMEO PLAYER -->
    <base-video
      ref="vimeo-player"
      v-if="vimeoId"

      id="cutscene-player"
      :vimeoId="vimeoId"
      :soundOn="soundOn"

      v-on:completed="onCompleted"
    />
    <!-- FALLBACK CHINA PLAYER -->
    <layout-center-content v-if="videoSrc">
      <layout-aspect-ratio-container
        class="cutscene-container"
        :aspect-ratio="16 / 9"
      >
        <div class="cutscene">
          <base-video
            ref="china-player"
            :videoSrc="videoSrc"
            :captions="captions"

            v-on:completed="onCompleted"
          />
        </div>
      </layout-aspect-ratio-container>
    </layout-center-content>
    <button id="skip-btn" @click="handleSkip">{{ $t("interactives.skip_video") }}</button>
  </layout-chrome>
</template>

<style scoped lang="sass">
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

