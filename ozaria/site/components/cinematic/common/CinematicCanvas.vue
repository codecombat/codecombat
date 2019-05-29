<template>
  <!-- TODO: Canvas needs to be responsive to scaling up and down. -->
  <!-- Currently fixed size to the aspect ratio of our play view. -->
  <div id="cinematic-canvas-div">
    <div id="cinematic-div" ref="cinematic-div" v-on:click="skipShot">
      <canvas
        id="cinematic-canvas"
        ref="cinematic-canvas"
        :width="width"
        :height="height"
        :style="{ width: width+'px', height: height+'px' }">
      </canvas>
    </div>
    <button :disabled="enterDisabled" v-on:click="nextShot">Enter</button>
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
    enterDisabled: false,
    width: 1280,
    height: 850
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
        onCompletion: () => this.$emit('completed')
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
    if (this.controller) {
      this.controller.destroy()
    }
    window.removeEventListener('keypress', this.handleKeyboardCancellation)
  },
}
</script>

<style scoped>
#cinematic-div {
  position: relative;
  font-size: 1.5em;
  height: 850px;
  width: 1280px;
}

#cinematic-div canvas {
  display: block;
  position: absolute;
}
</style>
