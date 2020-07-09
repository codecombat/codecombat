<script>
import LayoutAspectRatioContainer from '../../common/LayoutAspectRatioContainer'
import LayoutCenterContent from '../../common/LayoutCenterContent'

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
    cloudflareCaptionUrl: null
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

  methods: {
    onVideoLoaded () {
      const video = this.$refs['cloudflareVideo']
      if (video) {
        video.muted = !this.soundOn
        video.addEventListener('ended', () => this.onCompleted())
      }
    },

    onCompleted () {
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
        <stream ref="cloudflareVideo" :src="cloudflareID" controls>
          <track v-if="cloudflareCaptionUrl" kind="captions" :src="cloudflareCaptionUrl" default />
        </stream>
      </div>
    </layout-aspect-ratio-container>
  </layout-center-content>
</template>
