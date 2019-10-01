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

    soundOn: {
      type: Boolean,
      default: true
    },

    captions: {
      type: Array,
      default: ()=>([]),
      required: false
    }
  },

  data: () => ({
    vimeoPlayer: null
  }),

  async mounted () {
    if (!(this.vimeoId || this.videoSrc)) {
      throw new Error('You must pass in a "vimeoId" or a "videoSrc"')
    }

    if (this.vimeoId) {
      const player = this.vimeoPlayer = new VimeoPlayer(this.$refs['vimeo-player'])
      await player.ready()
      try {
        await player.setVolume(this.soundOn ? 1 : 0)
        await player.play()
      } catch (e) {
        console.warn(`Wasn't able to auto play video.`)
      }
      // TODO: Instead of emitting completed, requires end screen UI.
      //        Currently a stop gap to provide Intro support.
      player.on('ended', () => this.$emit('completed'))
    } else if (this.videoSrc) {
      new Plyr(this.$refs['player'], { captions: {active: true } })
    }
  },

  methods: {
    updateVideoSound () {
      // TODO: This can sometimes pause the video when turning on the volume.
      this.vimeoPlayer.setVolume(this.soundOn ? 1 : 0)
        .catch((e) => console.warn(`Couldn't set volume of cutscene`))
    }
  },

  watch: {
    soundOn() {
      if (!this.vimeoPlayer) {
        return
      }
      this.updateVideoSound()
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
