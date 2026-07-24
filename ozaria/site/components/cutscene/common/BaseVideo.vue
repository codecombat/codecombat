<script>
import 'vendor/styles/plyr.css'
import BaseModal from 'ozaria/site/components/common/BaseModal'
const Plyr = require('vendor/scripts/plyr')

export default {

  components: {
    BaseModal
  },
  props: {
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
      default: () => ([]),
      required: false
    }
  },

  data: () => ({
    vimeoPlayer: null,
    videoUnavailable: false,
    skipping: false
  }),

  async mounted () {
    if (!this.videoSrc) {
      throw new Error('You must pass in a "videoSrc"')
    }
    const vid = new Plyr(this.$refs.player, { captions: { active: true } })
    vid.on('ended', () => this.$emit('completed'))
  },

  methods: {
    skip () {
      this.skipping = true
      this.$emit('completed')
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
        <p class="instructions">
          {{ $t('interactives.console_instructions') }}
        </p>
      </div>
    </template>

    <template #footer>
      <button
        class="ozaria-button ozaria-primary-button"
        data-dismiss="modal"
        @click="skip"
      >
        {{ $t('interactives.skip_video') }}
      </button>
    </template>
  </base-modal>
  <iframe
    v-else-if="vimeoId && !skipping"
    ref="vimeo-player"
    :src="`https://player.vimeo.com/video/${vimeoId}`"
    frameborder="0"
    webkitallowfullscreen
    mozallowfullscreen
    allowfullscreen
  />
  <div v-else-if="videoSrc && !skipping">
    <video
      id="player"
      ref="player"
      playsinline
      controls
    >
      <source
        :src="videoSrc"
        type="video/mp4"
      >

      <!-- Captions are optional -->
      <template v-for="caption in captions">
        <track
          :key="caption.label"
          kind="captions"
          :label="caption.label"
          :src="caption.src"
          :srclang="caption.srclang"
          default
        >
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
