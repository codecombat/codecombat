<style>
</style>

<template>
  <canvas :width="this.width" :height="this.height" id="cinematic-canvas" ref="cinematic-canvas"></canvas>
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
    this.controller = new CinematicController(canvas)
  },
  // methods: {
  //   clickHandler () {
  //     console.log(this)
  //     this.controller.use()
  //   }
  // }
}
</script>
