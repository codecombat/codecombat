<script>
const Plyr = require('plyr')
const VimeoPlayer = require('@vimeo/player').default
import 'plyr/dist/plyr.css'

export default {
  props: {
    vimeoId: {
      type: String,
      required: false
    },
    videoSrc: {
      type: String,
      required: false
    },
    captions: {
      type: Array,
      default: ()=>([]),
      required: false
    }
  },
  mounted: function() {
    if (!(this.vimeoId || this.videoSrc)) {
      throw new Error('You must pass in a "vimeoId" or a "videoSrc"')
    }

    if (this.vimeoId) {
      const player = new VimeoPlayer(this.$refs['vimeo-player'])
      player.ready().then(() => player.play()).catch(() => {
        console.warn(`Wasn't able to auto play video.`)
      })
      // TODO: Instead of emitting completed, requires end screen UI.
      //        Currently a stop gap to provide Intro support.
      player.on('ended', () => this.$emit('completed'))
    } else if (this.videoSrc) {
      new Plyr(this.$refs['player'], { captions: {active: true } })
    }
  }
}

</script>

<template>
  <iframe v-if="vimeoId" ref="vimeo-player" :src="`https://player.vimeo.com/video/${vimeoId}`" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
  <div v-else>
    <video id="player" ref="player" playsinline controls>
      <source :src="videoSrc" type="video/mp4" />

      <!-- Captions are optional -->
      <template v-for="caption in captions">
        <track :key="caption.label" kind="captions" :label="caption.label" :src="caption.src" :srclang="caption.srclang" default />
      </template>
  </video>
  </div>
</template>

<style>

</style>
