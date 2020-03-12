<template>
  <div
    id="cinematic-canvas-div"
    ref="cinematic-canvas-el"
    class="cinematic-container"
  >
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
      <div v-if="!loaded" id="cinematic-loading-pane">
        <div id="cinematic-loading-container">
          <div class="progress-or-start-container">
            <img src="/images/ozaria/level/Logo_Bevelled@4x.png" alt="Ozaria logo">
            <p>{{ $t("common.LOADING") }}</p>
            <div class="load-progress">
              <div class="progress">
                <div class="progress-background"></div>
                <div class="progress-bar-container">
                  <div class="progress-bar progress-bar-success"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
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
import _ from 'lodash'

export default {
  props: {
    cinematicData: {
      type: Object,
      required: true
    },

    userOptions: {
      type: Object,
      required: false
    }
  },

  data: () => ({
    controller: null,
    cinematicPlaying: false,
    width: WIDTH,
    height: HEIGHT,
    loaded: false,
    initialTime: null
  }),

  mounted () {
    const canvas = this.$refs['cinematic-canvas']
    const canvasDiv = this.$refs['cinematic-div']
    this.initialTime = Date.now()
    this.controller = new CinematicController({
      canvas,
      canvasDiv,
      cinematicData: this.cinematicData,
      userOptions: this.userOptions,
      handlers: {
        onPlay: this.handlePlay,
        onPause: this.handleWait,
        onCompletion: () => {
          this.$emit('completed')
          window.tracker.trackEvent('Completed Cinematic', {cinematicId: (this.cinematicData || {})._id}, ['Google Analytics'])
        },
        onLoaded: this.handleCinematicLoad
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

    userInterruptionEvent: _.throttle(function() {
      if (!this.loaded) { return }

      if (this.cinematicPlaying) {
        this.controller.cancelShot()
      } else {
        this.playNextShot()
      }
    }, 500),

    handleCinematicLoad () {
      this.loaded = true
      this.userInterruptionEvent()
      const loadingTimeSec = Math.floor((Date.now() - this.initialTime) / 1000)
      window.tracker.trackEvent('Loaded Cinematic', {
        cinematicId: (this.cinematicData || {})._id,
        loadingTimeSec
      })
    },

    handleKeyboardCancellation: function(e) {
      const code = e.code || e.key
      if (code === "Enter") {
        this.userInterruptionEvent()
      }
    },

    onResize: _.debounce(function(e) {
      let parentWidth, parentHeight
      const parent = this.$refs['cinematic-canvas-el'].parentElement
      const boundingRect = parent.getBoundingClientRect()

      if (boundingRect) {
        parentWidth = boundingRect.width
        parentHeight = boundingRect.height
      } else {
        parentWidth = parent.clientWidth
        parentHeight = parent.clientHeight
      }

      const height = this.height = Math.min(parentWidth * CINEMATIC_ASPECT_RATIO, HEIGHT, parentHeight)
      const width = this.width = this.height / CINEMATIC_ASPECT_RATIO

      this.controller.onResize({ width, height })
    }, 250)
  },

  beforeDestroy: function()  {
    if (this.controller) {
      this.controller.destroy()
    }
    window.removeEventListener('keypress', this.handleKeyboardCancellation)
    window.removeEventListener('resize', this.onResize)
    window.tracker.trackEvent('Unloaded Cinematic', {cinematicId: (this.cinematicData || {})._id}, ['Google Analytics'])
  },
}
</script>

<style lang="sass">
// This should not be scoped so it works on programmatically created divs like
// speech bubbles.
@import "app/styles/mixins"
@import "ozaria/site/styles/common/common"

#cinematic-div
  position: relative
  .cinematic-speech-bubble-left, .cinematic-speech-bubble-right
    font-size: 24px
    font-size: 3.2vmin
    line-height: 1.42
    color: #0e1111

#cinematic-loading-pane
  position: absolute
  top: 0
  left: 0
  bottom: 0
  right: 0

  color: darkslategray
  font-size: 15px
  text-align: center
  font-family: 'Open Sans Condensed'

  background-color: $eve

#cinematic-loading-container
  display: flex
  align-items: center
  justify-content: center

  width: 100%
  height: 100%

.progress-or-start-container
  color: white
  width: 450px

  img
    width: 144px
  p
    font-size: 22px
    margin-top: 10px
    margin-bottom: 14px

  .load-progress
    width: 100%
    height: 15px

    .progress
      height: 100%
      position: relative
      background-color: transparent
      @include box-shadow(none)
      border-radius: 0

      .progress-background
        width: 100%
        height: 100%
        background-color: $color-primary-brand-white
        position: absolute
        z-index: 0

      .progress-bar-container
        width: 100%
        height: 100%
        position: absolute

        .progress-bar
          width: 1%
          height: 100%
          transition-duration: 0.2s
          background-color: $moon
          @include box-shadow(none)

#cinematic-div canvas
  display: block
  position: absolute

.cinematic-speech-bubble-right
  border-image: url('/images/ozaria/cinematic/Speech_Bubble_Right.svg')
  background-color: white
  border-image-slice: 40 40 40 40 fill
  border-image-width: 4rem
  border-image-outset: 20px 30px 45px 30px

.cinematic-speech-bubble-left
  border-image: url('/images/ozaria/cinematic/Speech_Bubble_Left.svg')
  background-color: white
  border-image-slice: 40 40 40 40 fill
  border-image-width: 4rem
  border-image-outset: 20px 30px 45px 30px

.cinematic-speech-bubble-click-continue
  text-align: center
  color: #1FBAB4
  font-family: "Open Sans"
  font-size: 12px
  font-size: 1.6vmin
  letter-spacing: 0.51px
  line-height: 3.2vmin
  font-style: italic

</style>
