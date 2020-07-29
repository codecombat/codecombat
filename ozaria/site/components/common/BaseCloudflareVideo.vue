<script>
  export default {
    props: {
      videoCloudflareId: {
        type: String,
        required: true
      },

      soundOn: {
        type: Boolean,
        default: true
      },

      cloudflareCaptionUrl: {
        type: String,
        default: null
      }
    },

    watch: {
      soundOn () {
        const video = this.$refs['cloudflareVideo']
        if (!video) {
          return
        }
        video.muted = !this.soundOn
      }
    },

    mounted () {
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
    },

    methods: {
      onVideoLoaded () {
        const video = this.$refs['cloudflareVideo']
        if (video) {
          video.muted = !this.soundOn
          video.addEventListener('ended', () => this.onCompleted())
        }
        this.$emit('loaded')
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
  <div class="cloudflare-video-div">
    <stream
      ref="cloudflareVideo"
      :src="videoCloudflareId"
      controls
    >
      <track
        v-if="cloudflareCaptionUrl"
        kind="captions"
        :src="cloudflareCaptionUrl"
        default
      >
    </stream>
  </div>
</template>
