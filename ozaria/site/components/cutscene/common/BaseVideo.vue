<script>
const Plyr = require('vendor/scripts/plyr')
const VimeoPlayer = require('@vimeo/player').default
import 'vendor/styles/plyr.css'
import BaseModal from 'ozaria/site/components/common/BaseModal'
import { cutsceneEvent } from './cutsceneUtil'

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

  components: {
    BaseModal
  },

  data: () => ({
    vimeoPlayer: null,
    videoUnavailable: false,
    skipping: false
  }),

  async mounted () {
    if (!(this.vimeoId || this.videoSrc)) {
      throw new Error('You must pass in a "vimeoId" or a "videoSrc"')
    }

    if (this.vimeoId) {
      const player = this.vimeoPlayer = new VimeoPlayer(this.$refs['vimeo-player'])

      // TODO: Instead of emitting completed, requires end screen UI.
      //        Currently a stop gap to provide Intro support.
      player.on('ended', () => this.$emit('completed'))

      // Unfortunately, we have to use a promise here because the Vimeo error handling
      // does not throw an error like expected. Only the .catch at the end of this chain
      // is really able to handle the 403.
      player.ready().then(async () => {
        try {
          cutsceneEvent('Video Loaded')
          await player.setVolume(this.soundOn ? 1 : 0)
          await player.play()
        } catch (e) {
            console.warn(`Wasn't able to auto play video.`)
        }
      }).catch((e) => {
        console.error(e)
        this.videoUnavailable = true
      })
    } else if (this.videoSrc) {
      const vid = new Plyr(this.$refs['player'], { captions: { active: true } })
      vid.on('ended', () => this.$emit('completed'))
    }
  },

  methods: {
    updateVideoSound () {
      // TODO: This can sometimes pause the video when turning on the volume.
      this.vimeoPlayer.setVolume(this.soundOn ? 1 : 0)
        .catch((e) => console.warn(`Couldn't set volume of cutscene`))
    },
    skip () {
      this.skipping = true
      this.$emit('completed')
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
  <base-modal v-if="videoUnavailable && !skipping">
    <template #header>
      <span class="text-capitalize status-text"> {{ $t('interactives.unavailable') }} </span>
    </template>

    <template #body>
      <div class="video-unavailable-body">
        <p>{{ $t('interactives.cannot_play_video') }}</p>
        <p class="instructions">{{ $t('interactives.console_instructions') }}</p>
      </div>
    </template>

    <template #footer>
      <button class="ozaria-button ozaria-primary-button" v-on:click="skip" data-dismiss="modal">{{ $t('interactives.skip_video')}}</button>
    </template>
  </base-modal>
  <iframe v-else-if="vimeoId && !skipping" ref="vimeo-player" :src="`https://player.vimeo.com/video/${vimeoId}`" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
  <div v-else-if="videoSrc && !skipping">
    <video id="player" ref="player" playsinline controls>
      <source :src="videoSrc" type="video/mp4" />

      <!-- Captions are optional -->
      <template v-for="caption in captions">
        <track :key="caption.label" kind="captions" :label="caption.label" :src="caption.src" :srclang="caption.srclang" default />
      </template>
    </video>
  </div>
</template>

<style lang="sass" scoped>
div.video-unavailable-body
  max-width: 480px
  padding: 0 20px
  p.instructions
    max-width: 400px
</style>
