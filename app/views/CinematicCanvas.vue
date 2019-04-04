<template>
<div>
  <canvas :width="this.width" :height="this.height" id="cinematic-canvas" ref="cinematic-canvas"></canvas>
  <div id="debug"></div>
 </div>
</template>

<script>
// This file is the entry to the cinematics canvas.
const createjs = require('lib/createjs-parts')
const LayerAdapter = require('lib/surface/LayerAdapter')
const Camera = require('lib/surface/Camera')

const ThangType = require('models/ThangType')
const Lank = require('lib/surface/Lank')
import {controller} from './play/cinematic/cinematicController'
const CENTER = {
  x: 300,
  y: 175
}
controller()


// Takes in a lank and a position. Returns lank with new position.
function moveLank(lank, pos)  {
  lank.thang.stateChanged = true
  lank.thang.pos = pos
  return lank
}

export default {
  mounted() {
    this.initStage();
},
  data: () => ({
    stage: null,
    layerAdapter: null,
    stubRequiredLayer: null,
    topLayer: null,
    width: 600,
    height: 350,
    thangType: null,
    mockThang: {
      health: 10.0,
      maxHealth: 10.0,
      hudProperties: ['health'],
      acts: true,
      stateChanged: true,
      pos: {
        x: 2.5,
        y: 1,
        z: 1
      },
      shadow: 0,
      action: 'attack',
      health: 20,
      maxHealth: 20,
      rotation: Math.PI/2,
      exists: true,
    },
    lank: null,
    camera: null,
  }),
  methods: {
    moveHandler(e) {
      // We get the X and Y from the event.
      const {stageX, stageY} = e;
      // Transform mouse coordinates to world meters.
      const result = this.camera.canvasToWorld({x: stageX, y: stageY})
      // we move the lank.
      moveLank(this.lank, result)
    },
    createLankFromThang() {
      console.log("call createLankFromThang")
      const lank = this.lank = new Lank(this.thangType, {
        resolutionFactor: 60,
        preloadSounds: false,
        thang: this.mockThang,
        camera: this.camera,
        // This must be passed in as `new Mark` uses a groundLayer.
        // Without this nothing works. In this case I am using a dummy layer.
        // Cinematics doesn't require Marks
        groundLayer: this.stubRequiredLayer
      })

      this.showLank(lank)
    },
    showLank(lank) {
      this.layerAdapter.resetSpriteSheet()
      this.layerAdapter.addLank(lank)
      this.layerAdapter.updateLayerOrder()
    },
    initStage () {
      const canvas = this.$refs['cinematic-canvas']
      this.stage = new createjs.StageGL(canvas)
      
      // Camera requires a jquery object to work???
      const camera = this.camera = new Camera($(canvas))
      this.stubRequiredLayer = new LayerAdapter({name: 'Ground', webGL: true, camera: camera})
      this.layerAdapter = new LayerAdapter({name: 'Default', webGL: true, camera: camera})
      
      this.layerAdapter.on("new-spritesheet", (spritesheet) => {
        // Now we have a working Anya that we can move around.
        // Potentially use this for loading behavior.
        // By counting how many times this is triggerred by ThangsTypes being loaded.
        this.stage.addEventListener('stagemousemove', this.moveHandler)
      })

      this.stage.addChild(this.layerAdapter.container)

      /**
       * Initialize an example Thang.
       */
      // https://codecombat.com/db/thang.type/cinematic-anya
      const anya_url = new ThangType({_id: "cinematic-anya"}).getURL()

      fetch(anya_url)
        .then(res => res.json())
        .then(data => {
          this.thangType = new ThangType(data)
          this.createLankFromThang()
        }).then(this.initTicker)
        .then(() => {
          // Set the camera zoom.
          this.camera.zoomTo({x: 0, y: 0}, 7, 0)
        })

    },

    initTicker() {
      createjs.Ticker.framerate = 30;
      
      const listener = {
        handleEvent: () => {
          if (!this.lank) {
            return
          }
          this.lank.update(true);

          this.stage.update()
        }
      }
      createjs.Ticker.addEventListener("tick", listener)

    }
  }
}
</script>

<style>

</style>
