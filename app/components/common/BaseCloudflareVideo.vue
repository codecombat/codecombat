<script>
const BASE_CLOUDFLARE_STREAM = 'https://customer-burj9xtby325x4f1.cloudflarestream.com'
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
    },
    thumbnailUrlTime: {
      type: Number,
      default: null,
      description: 'Time from which the thumbnail should be taken for the video in seconds'
    },
    backgroundColor: {
      type: String,
      default: null,
      description: 'Background color for the video'
    },
    aspectRatio: {
      type: String,
      default: '16 / 9'
    }
  },
  computed: {
    videoUrl () {
      const baseUrl = `${BASE_CLOUDFLARE_STREAM}/${this.videoCloudflareId}/iframe`
      const params = {}
      if (this.thumbnailUrl) {
        params.poster = encodeURIComponent(this.thumbnailUrl)
      } else if (this.thumbnailUrlTime) {
        params.poster = `${BASE_CLOUDFLARE_STREAM}/${this.videoCloudflareId}/thumbnails/thumbnail.jpg?time=${this.thumbnailUrlTime}s`
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

      params.controls = Boolean(this.controls)

      params.preload = this.preload

      if (this.backgroundColor) {
        params.letterboxColor = encodeURIComponent(this.backgroundColor)
      }

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
  <div
    class="cloudflare-video-div"
    :style="`aspect-ratio:${aspectRatio}`"
  >
    <iframe
      :src="videoUrl"
      loading="lazy"
      :style="`border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;aspect-ratio:${aspectRatio}`"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
      allowfullscreen="true"
    />
  </div>
</template>
