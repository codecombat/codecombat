<template>
  <!-- TODO: Canvas needs to be responsive to scaling up and down. -->
  <!-- Currently fixed size to the aspect ratio of our play view. -->
  <div id="cinematic-canvas-div">
    <div id="cinematic-div" ref="cinematic-div" v-on:click="userInterruptionEvent">
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
    width: 1366,
    height: 768
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
    }
  },
  beforeDestroy: function()  {
    if (this.controller) {
      this.controller.destroy()
    }
    window.removeEventListener('keypress', this.handleKeyboardCancellation)
  },
}
</script>

<style scoped>

#cinematic-div {
  margin-left: auto;
  margin-right: auto;
  position: relative;
  font-size: 1.5em;
  height: 768px;
  width: 1366px;
}

#cinematic-div canvas {
  display: block;
  position: absolute;
}
</style>
