<script>
  import { createThang } from '../../../../engine/cinematic/CinematicLankBoss'
  const createjs = require('lib/createjs-parts')
  const LayerAdapter = require('lib/surface/LayerAdapter')
  const Camera = require('lib/surface/Camera')
  const Lank = require('lib/surface/Lank')

  const SURFACE_SPRITE_RESOLUTION_FACTOR = 1

  export default {
    props: {
      loadedThangTypes: {
        type: Object,
        required: true
      },

      selectedThang: {
        type: String,
        required: true
      },

      thang: {
        type: Object,
        default: () => ({
          scaleFactorX: 1,
          scaleFactorY: 1,
          pos: { y: -37 }
        })
      },

      width: {
        type: Number,
        default: 400
      },

      height: {
        type: Number,
        default: 700
      }
    },
    data: () => ({
      defaultLayer: null,
      layerBackground: null,
      stage: null,
      onTickHandler: null,
      currentLank: null
    }),
    mounted () {
      // TODO: There is still a Vue reactivity leak in this file.
      const canvas = this.$refs['canvas']
      // TODO: Investigate why jquery is required
      const camera = new Camera($(canvas))
      this.stage = new createjs.StageGL(canvas)
      Vue.nonreactive(this.stage)

      this.defaultLayer = new LayerAdapter({
        name: 'Default',
        webGL: true,
        camera: camera
      })
      Vue.nonreactive(this.defaultLayer)

      this.defaultLayer.resolutionFactor = SURFACE_SPRITE_RESOLUTION_FACTOR

      this.layerBackground = new LayerAdapter({
        name: 'Ground',
        webGL: true,
        camera: camera
      })
      Vue.nonreactive(this.layerBackground)

      this.stage.addChild(this.layerBackground.container)
      this.stage.addChild(this.defaultLayer.container)

      // TODO MAKE TRANSPARENT
      this.stage.setClearColor("#FFFFFF00")

      createjs.Ticker.framerate = 20
      this.onTickHandler = () => {
        this.stage.update()
        if (this.currentLank) {
          this.currentLank.update(true)
        }
      }
      createjs.Ticker.addEventListener('tick', this.onTickHandler)

      const thang = createThang(this.thang)
      const lank = new Lank(this.loadedThangTypes[this.selectedThang], {
        preloadSounds: false,
        thang,
        camera: camera,
        groundLayer: this.layerBackground
      })

      this.defaultLayer.addLank(lank)
      this.currentLank = lank
      Vue.nonreactive(this.currentLank)

      camera.zoomTo({ x: 0, y: 0 }, 1, 0)
    },

    beforeDestroy () {
      createjs.Ticker.removeAllEventListeners()
      this.currentLank.options.camera.destroy()
      this.layerBackground.destroy()
      this.defaultLayer.destroy()
      this.currentLank.destroy()
      // Defensive coding to try to avoid stage/graphics leaks
      this.stage.clear()
      this.stage.removeAllChildren()
      this.stage.removeAllEventListeners()
      this.stage.enableDOMEvents(false)
      this.stage.enableMouseOver(0)
      this.stage.canvas.width = this.stage.canvas.height = 0
      this.stage.canvas = undefined
      this.stage = undefined
    }
  }
</script>

<template>
  <canvas
    ref="canvas"
    :width="`${width}px`"
    :height="`${height}px`"
  />
</template>

<style>

</style>
