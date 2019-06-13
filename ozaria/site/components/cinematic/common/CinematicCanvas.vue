<template>
  <!-- TODO: Canvas needs to be responsive to scaling up and down. -->
  <!-- Currently fixed size to the aspect ratio of our play view. -->
  <div id="cinematic-canvas-div">
    <div
      id="cinematic-div"
      ref="cinematic-div"
      v-on:click="userInterruptionEvent"
      :style="{ width: width+'px', height: height+'px' }"
    >
      <canvas
        id="cinematic-canvas"
        ref="cinematic-canvas"
        :width="width"
        :height="height"
        :style="{ width: width+'px', height: height+'px' }">
      </canvas>
    </div>
  </div>
</template>

<script>
/**
 * This vue component initializes the cinematic experience via the
 * CinematicController.
 */
import { CinematicController } from '../../../../engine/cinematic/cinematicController'
import { WIDTH, HEIGHT, CINEMATIC_ASPECT_RATIO} from '../../../../engine/cinematic/constants'

export default {
  props: {
    cinematicData: {
      type: Object,
      required: true
    }
  },
  data: () => ({
    controller: null,
    cinematicPlaying: false,
    width: WIDTH,
    height: HEIGHT
  }),
  mounted: function() {
    if (!me.hasCinematicAccess()) {
      return application.router.navigate('/', { trigger: true })
    }
    const canvas = this.$refs['cinematic-canvas']
    const canvasDiv = this.$refs['cinematic-div']
    this.controller = new CinematicController({
      canvas,
      canvasDiv,
      cinematicData: this.cinematicData,
      handlers: {
        onPlay: this.handlePlay,
        onPause: this.handleWait,
        onCompletion: () => this.$emit('completed'),
        onLoaded: this.userInterruptionEvent
      }})
    window.addEventListener('keypress', this.handleKeyboardCancellation)
    window.addEventListener('resize', this.onResize)
    this.onResize()
  },
  methods: {
    handlePlay: function() {
      this.cinematicPlaying = true
    },
    handleWait: function() {
      this.cinematicPlaying = false
    },
    playNextShot: function() {
      this.controller && this.controller.runShot()
    },
    userInterruptionEvent: function() {
      if (this.cinematicPlaying) {
        this.controller.cancelShot()
      } else {
        this.playNextShot()
      }
    },
    handleKeyboardCancellation: function(e) {
      const code = e.code || e.key
      if (code === "Enter") {
        this.userInterruptionEvent()
      }
    },
    onResize: function(e) {
      const userWidth = Math.min(window.innerWidth
        || document.documentElement.clientWidth
        || document.body.clientWidth, WIDTH)

      const userHeight = Math.min(window.innerHeight
        || document.documentElement.clientHeight
        || document.body.clientHeight, HEIGHT)

      const height = this.height = Math.min(userWidth * CINEMATIC_ASPECT_RATIO, HEIGHT, userHeight)
      const width = this.width = this.height / CINEMATIC_ASPECT_RATIO

      this.controller.onResize({ width, height })
    }
  },
  beforeDestroy: function()  {
    if (this.controller) {
      this.controller.destroy()
    }
    window.removeEventListener('keypress', this.handleKeyboardCancellation)
    window.removeEventListener('resize', this.onResize)
  },
}
</script>

<style lang="sass">
//   This should not be scoped so it works on
//   programmatically created divs.

#cinematic-canvas-div
  transform: translateX(-20px)

#cinematic-div
  margin-left: auto
  margin-right: auto
  position: relative
  .cinematic-speech-bubble-left, .cinematic-speech-bubble-right
    font-size: 24px
    line-height: 1.42
    color: #0e1111

#cinematic-div canvas
  display: block
  position: absolute

.cinematic-speech-bubble-right
  border-image: url('/images/ozaria/cinematic/bubble_right_slice.png')
  border-image-slice: 50 100 50 50 fill
  border-image-width: 40px 80px 40px 40px
  border-image-outset: 10px 58px 15px 15px

.cinematic-speech-bubble-left
  border-image: url('/images/ozaria/cinematic/bubble_left_slice.png')
  border-image-slice: 50 50 50 100 fill
  border-image-width: 40px 40px 40px 80px
  border-image-outset: 10px 15px 15px 58px

</style>
