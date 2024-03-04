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
    },

    thumbnailUrl: {
      type: String,
      default: null
    },

    preload: {
      default: 'none',
      validator: value => ['auto', 'metadata', 'none'].includes(value)
    },
    loop: {
      type: Boolean,
      default: false
    },
    autoplay: {
      type: Boolean,
      default: false
    },
    controls: {
      type: Boolean,
      default: true
    },
    playWhenVisible: {
      type: Boolean,
      default: false
    },
    title: {
      type: String,
      default: 'Your descriptive text here',
      required: false
    }
  },

  watch: {
    soundOn () {
      const video = this.$refs.cloudflareVideo
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
      const video = this.$refs.cloudflareVideo

      if (video) {
        if (this.playWhenVisible) {
          const observer = new IntersectionObserver((entries, opts) => {
            entries.forEach(entry => {
              if (entry.isIntersecting) {
                this.playVideo()
              } else {
                this.pauseVideo()
              }
            })
          }, {
            root: null, // default is the viewport
            threshold: 0.5 // percentage of target's visible area. 0.5 means when 50% of the target is visible
          })

          // Use the observer to observe an element
          observer.observe(video)
        }

        video.muted = !this.soundOn
        video.addEventListener('ended', () => this.onCompleted())

        // Check if the video is in the viewport on page load
        if (this.playWhenVisible && this.isInViewport(video)) {
          this.playVideo()
        }

        this.setTitleForIframe(video)
      }
      this.$emit('loaded')
    },

    isInViewport (element) {
      const rect = element.getBoundingClientRect()
      return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.right <= (window.innerWidth || document.documentElement.clientWidth)
      )
    },

    setTitleForIframe (video) {
      // Find the iframe inside the <stream> element
      const iframe = video.querySelector('iframe')

      // Set the title attribute of the iframe
      if (iframe) {
        iframe.setAttribute('title', this.title)
      }
    },

    onCompleted () {
      this.$emit('completed')
    },

    playVideo () {
      const video = this.$refs.cloudflareVideo
      if (video && typeof video.pause === 'function') {
        video.play()
      }
    },

    pauseVideo () {
      const video = this.$refs.cloudflareVideo
      if (video && typeof video.pause === 'function') {
        video.pause()
      }
    },

    getVideo () {
      return this.$refs.cloudflareVideo
    }
  }
}
</script>

<template>
  <div class="cloudflare-video-div">
    <stream
      ref="cloudflareVideo"
      :preload="preload"
      :poster="thumbnailUrl"
      :src="videoCloudflareId"
      letterbox-color="transparent"
      :loop="loop"
      :autoplay="autoplay"
      :controls="controls"
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
