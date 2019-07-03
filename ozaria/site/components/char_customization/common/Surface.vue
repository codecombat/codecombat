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

      selectedHero: {
        type: String,
        required: true
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

      const thang = createThang({
        scaleFactorX: 1.7,
        scaleFactorY: 1.7,
        pos: { y: -35 },
        shadow: 10
      })
      const lank = new Lank(this.loadedThangTypes[this.selectedHero], {
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
  <canvas  ref="canvas" width="200px" height="700px"></canvas>
</template>

<style>

</style>
