<template>
  <!-- TODO: Canvas needs to be responsive to scaling up and down. -->
  <!-- Currently fixed size to the aspect ratio of our play view. -->
  <div>
    <div height="514px" id="cinematic-div" ref="cinematic-div" v-on:click="skipShot">
      <canvas width="800" height="514" id="cinematic-canvas" ref="cinematic-canvas"></canvas>
    </div>
    <button :disabled="enterDisabled" v-on:click="nextShot">Enter</button>
  </div>
</template>

<script>
/**
 * This vue component initializes the cinematic experience via the
 * CinematicController.
 */
import { CinematicController } from './play/cinematic/cinematicController'

export default {
  props: {
    cinematicData: {
      type: Object,
      required: true
    }
  },
  data: () => ({
    controller: null,
    enterDisabled: false
  }),
  mounted: function() {
    if (!me.hasCinematicAccess()) {
      // TODO: VOYAGER FEATURE: Remove when ready for production use.
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
      }})
    window.addEventListener('keypress', this.handleKeyboardCancellation)
  },
  methods: {
    handlePlay: function() {
      this.enterDisabled = true
    },
    handleWait: function() {
      this.enterDisabled = false
    },
    nextShot: function() {
      this.controller && this.controller.runShot()
    },
    skipShot: function() {
      this.controller.cancelShot()
    },
    handleKeyboardCancellation: function(e) {
      const code = e.code || e.key
      if (code === "Enter") {
        this.skipShot()
      }
    }
  },
  beforeDestroy: function()  {
    window.removeEventListener('keypress', this.handleKeyboardCancellation)
  },
}
</script>

<style scoped>
#cinematic-div {
  position: relative;
  font-size: 1.5em;
  height: 514px;
  width: 800px;
}

#cinematic-div canvas {
  display: block;
  position: absolute;
}
</style>
