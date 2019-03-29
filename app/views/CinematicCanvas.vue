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

const CENTER = {
  x: 300,
  y: 175
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
        x: 0,
        y: 0,
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
    createLankFromThang() {
      console.log("call createLankFromThang")
      const lank = this.lank = new Lank(this.thangType, {
        resolutionFactor: 60,
        preloadSounds: false,
        thang: this.mockThang,
        camera: this.camera,
        isCinematic: true,
        // This must be passed in as `new Mark` uses a groundLayer.
        // Without this nothing works. In this case I am using a dummy layer.
        groundLayer: this.stubRequiredLayer
      })

      this.showLank(lank)

      lank.queueAction('idle')
    },
    showLank(lank) {
      this.layerAdapter.resetSpriteSheet()
      this.layerAdapter.addLank(lank)
      this.layerAdapter.updateLayerOrder()
    },
    initStage () {
      const canvas = this.$refs['cinematic-canvas']
      this.stage = new createjs.StageGL(canvas)
      // Camera requires a jquery object to work
      const camera = this.camera = new Camera($(canvas))
      this.stubRequiredLayer = new LayerAdapter({name: 'Ground', webGL: true, camera: camera})
      this.layerAdapter = new LayerAdapter({name: 'Default', webGL: true, camera: camera})
      
      this.layerAdapter.on("new-spritesheet", (spritesheet) =>{
        // Creating a new spritesheet changes x and y of layer.
        this.layerAdapter.container.x = CENTER.x;
        this.layerAdapter.container.y = CENTER.y;
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

    },

    initTicker() {
      let ticks = 0;
      createjs.Ticker.framerate = 30;
      
      const listener = {
        handleEvent: () => {
          if (ticks >= 100000) {
            return;
          }
          ticks ++;
          if (!this.lank) {
            return
          }
          this.lank.update(true);
          // console.log("UPdate", this.lank)
          // console.log({x: this.lank.sprite.x, y: this.lank.sprite.y})
          this.stage.update()
        }
      }
      createjs.Ticker.addEventListener("tick", listener)

      /** INITIATE Camera random movement */
      setInterval(() => {
        const pos = {x: Math.random() * CENTER.x * 2, y: Math.random() * CENTER.y * 2}
        console.log("move camera", pos)
        this.camera.zoomTo(pos)
        this.lank.queueAction(['idle', 'bash', 'move', 'die'][Math.floor(Math.random() * 4)])
      }, 3000)
    }
  }
}
</script>

<style>

</style>
