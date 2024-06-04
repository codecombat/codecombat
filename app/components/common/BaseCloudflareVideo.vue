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
  computed: {
    videoUrl () {
      const baseUrl = `https://customer-burj9xtby325x4f1.cloudflarestream.com/${this.videoCloudflareId}/iframe`
      const params = {}
      if (this.thumbnailUrl) {
        params.poster = encodeURIComponent(this.thumbnailUrl)
      }
      if (this.autoplay) {
        params.autoplay = true
      }
      if (this.loop) {
        params.loop = true
      }
      if (!this.soundOn) {
        params.muted = true
      }
      params.preload = this.preload
      const arr = []
      for (const [key, val] of Object.entries(params)) {
        arr.push(`${key}=${val}`)
      }
      return `${baseUrl}?${arr.join('&')}`
    }
  }
}
</script>

<template>
  <div class="cloudflare-video-div">
    <iframe
      :src="videoUrl"
      loading="lazy"
      style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
      allowfullscreen="true"
    />
  </div>
</template>
