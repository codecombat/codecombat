<template>
  <div
    id="cinematic-canvas-div"
    ref="cinematic-canvas-el"
    class="cinematic-container"
  >
    <div
      id="cinematic-div"
      ref="cinematic-div"
      :style="{ width: width+'px', height: height+'px' }"
    >
      <div
        id="cinematic-nav"
        :class="{ hiding: showInstructionalTooltip && loaded }"
      >
        <div v-if="showInstructionalTooltip && loaded" id="cinematic-instruction-tooltip">
          <div class="close-btn"
            @click="() => { this.showInstructionalTooltip = false }"
          ></div>
          <span>
            {{ $t('cinematic.instructional_tooltip') }}
          </span>
          <img src="/images/ozaria/cinematic/navigation/Keyboard.svg" alt="Keyboard showing cinematic navigation with left and right keys"/>
        </div>
        <div id="cinematic-backer" v-if="loaded">
          <div
            id="back-btn"
            :class="{ disabled: !canUndo }"
            @click="() => userAction('backInteraction')"
          ></div>
          <div
            id="forward-btn"
            @click="() => {
              this.showInstructionalTooltip = false
              this.userAction('forwardInteraction')
            }"
          ></div>
        </div>
      </div>
      <chalkboard />
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
import { WIDTH, HEIGHT, CINEMATIC_ASPECT_RATIO } from '../../../../engine/cinematic/constants'
import Chalkboard from './Chalkboard'
import _ from 'lodash'

const BACK_INTERACTION = 'backInteraction'
const FORWARD_INTERACTION = 'forwardInteraction'

export default {
  components: {
    Chalkboard
  },

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
    initialTime: null,
    cinematicCompleted: false,
    showInstructionalTooltip: false
  }),

  mounted () {
    const canvas = this.$refs['cinematic-canvas']
    const canvasDiv = this.$refs['cinematic-div']
    this.initialTime = Date.now()
    if (this.cinematicData.showInstructionalTooltip) {
      this.showInstructionalTooltip = true
    }

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
          this.cinematicCompleted = true
          window.tracker.trackEvent('Completed Cinematic', { cinematicId: (this.cinematicData || {})._id }, ['Google Analytics'])
        },
        onLoaded: this.handleCinematicLoad
      }})
    window.addEventListener('resize', this.onResize)
    this.onResize()
  },

  computed: {
    canUndo () {
      if (!this.controller) {
        return false
      }
      if (this.cinematicPlaying) {
        return false
      }
      return this.controller.undoCommands.canUndo
    }
  },

  methods: {
    // Note: This is called between dialogue nodes when autoplay system is used.
    handlePlay: function() {
      this.cinematicPlaying = true
    },

    handleWait: function() {
      this.cinematicPlaying = false
    },

    playNextShot: function() {
      this.controller && this.controller.runShot()
    },

    userAction: _.throttle(function (interactionType) {
      if (this.cinematicCompleted) {
        // Ignore user interaction when cinematic completion modal showing.
        return
      }
      if (!interactionType || interactionType === FORWARD_INTERACTION) {
        this.userInterruptionEvent()
      } else if (interactionType === BACK_INTERACTION) {
        this.pressBackwardsNavigation()
      } else {
        throw new Error('cant handle interaction')
      }
    }, 500),

    pressBackwardsNavigation: function () {
      if (this.canUndo && this.controller) {
        this.controller.undoShot()
      }
    },

    userInterruptionEvent: function (e) {
      if (!this.loaded) { return }
      if (e && e.preventDefault) {
        e.preventDefault()
      }

      // When a user prompts to play the cinematic we ensure the cinematic
      // state is correct. This defends against a devastating bug where the
      // user cannot progress because the view has incorrect state.
      if (!this.controller.hasActiveRunner) {
        this.handleWait()
      }

      if (this.cinematicPlaying) {
        this.controller.cancelShot()
      } else {
        this.playNextShot()
      }
    },

    handleCinematicLoad () {
      this.loaded = true
      window.addEventListener('keydown', this.handleKeyboard)
      const loadingTimeSec = Math.floor((Date.now() - this.initialTime) / 1000)
      this.userAction(FORWARD_INTERACTION)
      const cinematicId = (this.cinematicData || {})._id
      window.tracker.trackEvent('Loaded Cinematic', {
        cinematicId,
        loadingTimeSec
      })
      if (application.tracker) {
        application.tracker.trackTiming(Date.now() - this.initialTime, 'Cinematic Load Time', cinematicId, cinematicId)
      }
    },

    handleKeyboard: function (e) {
      const code = e.code || e.key
      if (code === 'Enter' || code === 'ArrowRight') {
        this.userAction(FORWARD_INTERACTION)
      } else if (code === 'ArrowLeft') {
        this.userAction(BACK_INTERACTION)
      }
    },

    onResize: _.debounce(function (e) {
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

  beforeDestroy: function () {
    if (this.controller) {
      this.controller.destroy()
    }
    window.removeEventListener('keydown', this.handleKeyboard)
    window.removeEventListener('resize', this.onResize)
    window.tracker.trackEvent('Unloaded Cinematic', {cinematicId: (this.cinematicData || {})._id}, ['Google Analytics'])
  }
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
    font-family: "Work Sans"
    font-size: 2.6vmin
    line-height: 1.42
    color: #0e1111
    min-width: 4rem

    @media screen and (min-width: 1366px) and (min-height: 768px)
      font-size: 24px

  #cinematic-nav
    width: 100%
    height: 100%
    position: absolute
    z-index: 10

    display: flex
    justify-content: center
    align-items: flex-end
    transition: background-color 0.3s ease

    &.hiding
      background-color: rgba(0,0,0,0.7)

    #cinematic-backer
      background-image: url('/images/ozaria/cinematic/navigation/Backer.svg')
      background-repeat: no-repeat
      width: 23%
      height: 9%
      padding: 0 18px

      display: flex
      align-items: center
      justify-content: space-around

      transform: translateY(2px)
    #back-btn, #forward-btn
      width: 16%
      height: 60%
      cursor: pointer

      background-repeat: no-repeat
      background-size: contain

    #back-btn
      background-image: url('/images/ozaria/cinematic/navigation/ActiveL.svg')

      &.disabled
        background-image: url('/images/ozaria/cinematic/navigation/InactiveL.svg')
        cursor: unset

      &:hover:not(.disabled)
        background-image: url('/images/ozaria/cinematic/navigation/HoverL.svg')

    #forward-btn
      background-image: url('/images/ozaria/cinematic/navigation/ActiveR.svg')

      &:hover
        background-image: url('/images/ozaria/cinematic/navigation/HoverR.svg')

    #cinematic-instruction-tooltip
      position: absolute
      width: 440px
      height: 140px
      background-image: url('/images/ozaria/cinematic/navigation/TooltipBacker.svg')
      z-index: 1
      background-position: center
      background-repeat: no-repeat
      bottom: 10%

      display: flex
      flex-direction: row
      align-items: center
      padding: 0 20px 20px

      span
        font-family: Work Sans
        font-style: normal
        font-weight: normal
        font-size: 16px
        line-height: 22px

      .close-btn
        background-image: url('/images/ozaria/cinematic/navigation/CloseButton.svg')
        background-repeat: no-repeat

        cursor: pointer

        position: absolute
        right: 10px
        top: 9px

        width: 23px
        height: 21px

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
  border-image-width: 2vw
  border-image-outset: 4vh 3vw 4vh 3vw

.cinematic-speech-bubble-left
  border-image: url('/images/ozaria/cinematic/Speech_Bubble_Left.svg')
  background-color: white
  border-image-slice: 40 40 40 40 fill
  border-image-width: 2vw
  border-image-outset: 4vh 3vw 4vh 3vw

</style>
