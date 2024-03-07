<template>
  <base-cloudflare-video
    ref="video"
    :video-cloudflare-id="videoId"
    :sound-on="false"
    preload="none"
    :loop="true"
    :autoplay="true"
    :controls="false"
    :play-when-visible="true"
    :title="title"
    @loaded="onVideoLoaded"
  />
</template>

<script>
import BaseCloudflareVideo from 'app/components/common/BaseCloudflareVideo'

export default {
  name: 'VideoBox',
  components: {
    BaseCloudflareVideo
  },
  props: {
    videoId: {
      type: String,
      required: true
    },
    title: {
      type: String,
      default: 'Your descriptive text here',
      required: false
    }
  },
  methods: {
    onVideoLoaded () {
      this.$emit('loaded')
    }
  },
}
</script>

<style scoped lang="scss">
iframe,
div {
    min-width: 100%;
    min-height: 100%;
    object-fit: cover;
}

iframe {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
}
</style>
