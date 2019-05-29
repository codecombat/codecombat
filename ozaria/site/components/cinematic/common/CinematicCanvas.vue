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

<style>
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

.speech-left {
  border: 2px solid black;
  border-image:
    url(/images/cinematic/DialogBubble_Left.png);

  /* Values that work for the dev art speech bubble */
  border-image-slice: 27.58% 21.98% 24.35% 52.03% fill;
  border-image-width: 12px; 
  border-image-outset: 12px;
}

.speech-left {
  border: 2px solid black;
  background-color: white;
  border-image:
    url(/images/cinematic/DialogBubble_Left.png);

  /* Values that work for the dev art speech bubble */
  border-image-slice: 27.58% 52.03% 34.01% 35.58% fill;
  border-image-width: 12px;
  border-image-outset: 12px;
  padding: 4px;
}

.speech-right {
  border: 2px solid black;
  background-color: white;
  border-image:
    url(/images/cinematic/DialogBubble_Right.png);

  /* Values that work for the dev art speech bubble */
  border-image-slice: 27.58% 21.98% 24.35% 52.03% fill;
  border-image-width: 12px; 
  border-image-outset: 12px;
  padding: 4px;
}
</style>
