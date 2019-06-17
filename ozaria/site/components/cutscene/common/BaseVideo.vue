<script>
const Plyr = require('plyr')
const VimeoPlayer = require('@vimeo/player').default
import 'plyr/dist/plyr.css'

export default {
  props: {
    vimeoId: {
      type: Number,
      required: false
    },
    width: {
      type: Number,
      required: true
    },
    height: {
      type: Number,
      required: true
    },
    videoSrc: {
      type: String,
      required: false
    },
    captions: {
      type: Array,
      default: [],
      required: false
    }
  },
  mounted: function() {
    if (!(this.vimeoId || this.videoSrc)) {
      throw new Error('You must pass in a "vimeoId" or a "videoSrc"')
    }

    if (this.vimeoId) {
      new VimeoPlayer('vimeo-player')
    } else if (this.videoSrc) {
      new Plyr(this.$refs['player'], { captions: {active: true } })
    }
  }
}

</script>

<template>
  <div>
    <iframe v-if="vimeoId" id="vimeo-player" :src="`https://player.vimeo.com/video/${vimeoId}`" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen :width="width" :height="height"></iframe>
    <div v-else :style="{ width: width+'px', height: height+'px' }">
      <video id="player" ref="player" playsinline controls>
        <source :src="videoSrc" type="video/mp4" />

        <!-- Captions are optional -->
        <template v-for="caption in captions">
          <track :key="caption.label" kind="captions" :label="caption.label" :src="caption.src" :srclang="caption.srclang" default />
        </template>
    </video>
    </div>
  </div>
</template>

<style>

</style>
