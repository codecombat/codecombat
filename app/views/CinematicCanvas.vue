<template>
  <!-- TODO: Canvas needs to be responsive to scaling up and down. -->
  <!-- Currently fixed size to the aspect ratio of our play view. -->
  <div height="514px" id="cinematic-div" ref="cinematic-div">
    <canvas width="800" height="514" id="cinematic-canvas" ref="cinematic-canvas"></canvas>
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
    slug: {
      type: String,
      required: true
    }
  },
  data: () => ({
    controller: null
  }),
  mounted: function() {
    const canvas = this.$refs['cinematic-canvas']
    const canvasDiv = this.$refs['cinematic-div']
    this.controller = new CinematicController({ canvas, canvasDiv, slug: this.slug })
  }
}
</script>

<style scoped>
#cinematic-div {
  position: relative;
  display: inline-block;
  font-size: 1.5em;
}

#cinematic-div canvas {
  display: block;
  position: absolute;
}
</style>
