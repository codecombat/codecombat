<script>
import LayoutAspectRatioContainer from '../../common/LayoutAspectRatioContainer'
import LayoutCenterContent from '../../common/LayoutCenterContent'
import { log } from '../../../common/logger'

export default {
  components: {
    LayoutAspectRatioContainer,
    LayoutCenterContent
  },

  props: {
    cutscene: {
      type: Object,
      required: true
    },

    cloudflareID: {
      type: String,
      required: true
    },

    soundOn: {
      type: Boolean,
      required: false,
      default: true
    }
  },

  data: () => ({
    cloudflareCaptionUrl: null,
    checkEndedIntervalFailsafe: null,
    currentTimeFrozenCheck: 0,
    lastCurrentTime: null
  }),

  watch: {
    soundOn () {
      const video = this.$refs['cloudflareVideo']
      if (!video) {
        return
      }
      video.muted = !this.soundOn
    }
  },

  // TODO refactor to use `../../common/BaseCloudflareVideo` component
  mounted () {
    const cutscene = this.cutscene
    /**
     * Create and attach the script that streams the video.
     */
    const cloudflareScript = document.createElement('script')
    cloudflareScript.setAttribute('src', `https://embed.videodelivery.net/embed/r4xu.fla9.latest.js?video=${this.cloudflareID}`)
    cloudflareScript.defer = true
    cloudflareScript.setAttribute('type', 'text/javascript')
    cloudflareScript.setAttribute('data-cfasync', 'false')
    cloudflareScript.onload = this.onVideoLoaded
    document.body.appendChild(cloudflareScript)

    /**
     * Cloudflare video player only supports a single caption track.
     * Thus pick out the specific caption file for the user based on preferred language.
     */
    let captionSrc = (cutscene.captions || {}).src
    const localizedCaption = (((cutscene.i18n || {})[me.get('preferredLanguage')] || {}).captions || {}).src

    if (localizedCaption) {
      captionSrc = localizedCaption
    }

    if (captionSrc) {
      this.cloudflareCaptionUrl = `/file/${captionSrc}`
    }
  },

  beforeDestroy () {
    clearInterval(this.checkEndedIntervalFailsafe)
  },

  methods: {
    onVideoLoaded () {
      const video = this.$refs['cloudflareVideo']
      if (video) {
        video.muted = !this.soundOn
        video.addEventListener('ended', () => this.onCompleted())

        // Check allows us to catch edge cases where the player fails
        // to emit an ended event. These cases occur when the currentTime
        // stops advancing about 0.2sec on either side of the total duration.
        // The cloudflare player gets stuck making 204 requests and doesn't
        // trigger an ended event.
        clearInterval(this.checkEndedIntervalFailsafe)
        this.checkEndedIntervalFailsafe = setInterval(() => {
          const { currentTime, duration, paused } = this.$refs['cloudflareVideo']
          if (!this.lastCurrentTime || this.lastCurrentTime !== currentTime) {
            this.lastCurrentTime = currentTime
            this.currentTimeFrozenCheck = 0
          } else {
            if (this.lastCurrentTime === currentTime && !paused) {
              this.currentTimeFrozenCheck += 1
            }
          }

          // Only trigger failsafe if the video is within a second of the duration.
          // Prevents failsafe triggering due to video buffering.
          const isVideoNearEnd = Math.abs(duration - currentTime) < 1

          if (isVideoNearEnd && this.currentTimeFrozenCheck > 3) {
            log('Cutscene Ended Failsafe triggered')
            this.onCompleted()
          }
        }, 500)
      }
    },

    onCompleted () {
      clearInterval(this.checkEndedIntervalFailsafe)
      this.$emit('completed')
    },

    pauseVideo () {
      const video = this.$refs['cloudflareVideo']
      if (video && typeof video.pause === 'function') {
        video.pause()
      }
    }
  }
}
</script>

<template>
  <layout-center-content>
    <layout-aspect-ratio-container
      class="cutscene-container"
      :aspect-ratio="16 / 9"
    >
      <div class="cutscene">
        <stream ref="cloudflareVideo" :src="cloudflareID" controls preload="auto">
          <track v-if="cloudflareCaptionUrl" kind="captions" :src="cloudflareCaptionUrl" default />
        </stream>
      </div>
    </layout-aspect-ratio-container>
  </layout-center-content>
</template>
