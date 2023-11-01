<script>

import BaseCloudflareVideo from './BaseCloudflareVideo'
const VueYoutube = require('vue-youtube')

const TYPES = {
  YOUTUBE: 'youtube',
  CLOUDFLARE: 'cloudflare'
}

export default {
  components: {
    BaseCloudflareVideo
  },

  props: {
    youtubeProps: {
      type: Object
    },
    cloudflareProps: {
      type: Object
    },
    defaultType: {
      type: String,
      default: TYPES.YOUTUBE
    }
  },

  data () {
    return {
      activeType: this.defaultType,
      TYPES
    }
  },
  beforeCreate () {
    Vue.use(VueYoutube.default)
  },
  methods: {
    youtubeError () {
      this.activeType = TYPES.CLOUDFLARE
    }
  }
}
</script>

<template>
  <div class="video-div">
    <youtube
        v-if="activeType==TYPES.YOUTUBE"
        @error="youtubeError"
        v-bind="youtubeProps"
    />
    <base-cloudflare-video
        v-if="activeType==TYPES.CLOUDFLARE"
        v-bind="cloudflareProps"
    />
  </div>
</template>
