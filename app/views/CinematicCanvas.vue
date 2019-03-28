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


const CENTER = {x: 200, y: 400}

export default {
  mounted() {
    this.initStage();
},
  data: () => ({
    stage: null,
    layerAdapter: null,
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
    },
    lank: null,
  }),
  methods: {
    createLankFromThang() {
      console.log("call createLankFromThang")
      const lank = this.lank = new Lank(this.thangType, {
        resolutionFactor: 60,
        preloadSounds: false,
        thang: this.mockThang
      })

      this.showLank(lank)

      lank.queueAction('attack')
      lank.sprite.x = 100
      lank.sprite.y = 100
    },
    showLank(lank) {
      // this.layerAdapter.resetSpriteSheet()
      this.layerAdapter.addLank(lank)
      this.layerAdapter.updateLayerOrder()
    },
    initStage () {
      const canvas = this.$refs['cinematic-canvas']
      this.stage = new createjs.StageGL(canvas)

      // Camera requires a jquery object to work
      const camera = new Camera($(canvas))

      this.layerAdapter = new LayerAdapter({name: 'Default', webGL: true, camera: camera})
      this.layerAdapter.on("new-spritesheet", (spritesheet) =>{
        console.log("SPRITE SHEET BUILT")
        this.onNewSpriteSheet(spritesheet)
      })

      this.layerAdapter.container.x = CENTER.x;
      this.layerAdapter.container.y = CENTER.y;

      this.stage.addChild(this.layerAdapter.container)


      createjs.Ticker.framerate = 30;
      createjs.Ticker.addEventListener('tick', () => {
        this.stage.update();
        if (this.lank) {
          this.lank.thang.stateChanged = true;
          this.lank.update(true)
        }
      })


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
        })

    },
    onNewSpriteSheet(spritesheet) {
      this.layerAdapter.container.x = 0;
      this.layerAdapter.container.y = 0;
      for (let image of this.layerAdapter.spriteSheet._images) {
        $("#debug").append(image)
      }
    }
  }
}
</script>

<style>

</style>
