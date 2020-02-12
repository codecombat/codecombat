<script>
  import { createThang } from '../../../../engine/cinematic/CinematicLankBoss';
  const createjs = require('lib/createjs-parts')
  const LayerAdapter = require('lib/surface/LayerAdapter')
  const Camera = require('lib/surface/Camera')
  const Lank = require('lib/surface/Lank')

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
        default: 230
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
      const canvas = this.$refs['canvas']
      // TODO: Investigate why jquery is required
      const camera = new Camera($(canvas))
      this.stage = new createjs.StageGL(canvas)

      this.defaultLayer = new LayerAdapter({
        name:  'Default',
        webGL: true,
        camera: camera
      })

      this.layerBackground = new LayerAdapter({
        name:  'Ground',
        webGL: true,
        camera: camera
      })

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
        perloadSounds: false,
        thang,
        camera: camera,
        groundLayer: this.layerBackground
      })

      this.defaultLayer.addLank(lank)
      this.currentLank = lank

      camera.zoomTo({ x: 0, y: 0 }, 1, 0)
    },

    destroyed () {
      createjs.Ticker.removeAllEventListeners()
    }
  } 
</script>

<template>
  <canvas  ref="canvas" :width="`${width}px`" :height="`${height}px`"></canvas>
</template>

<style>

</style>
