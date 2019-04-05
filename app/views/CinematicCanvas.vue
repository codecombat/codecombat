<style>
#cinematic-div {
  position: relative;
  display: inline-block;
}

#cinematic-div canvas {
  display: block;
  position: absolute;
}
</style>

<template>
  <div :height="this.height" id="cinematic-div" ref="cinematic-div">
    <canvas :width="this.width" :height="this.height" id="cinematic-canvas" ref="cinematic-canvas"></canvas>
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
    width: Number,
    height: Number
  },
  data: () => ({
    controller: null
  }),
  mounted: function() {
    const canvas = this.$refs['cinematic-canvas']
    const canvasDiv = this.$refs['cinematic-div']
    this.controller = new CinematicController(canvas, canvasDiv)
  },
  // methods: {
  //   clickHandler () {
  //     console.log(this)
  //     this.controller.use()
  //   }
  // }
}
</script>
