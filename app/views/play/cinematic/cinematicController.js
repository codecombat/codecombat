const createjs = require('lib/createjs-parts')
const LayerAdapter = require('lib/surface/LayerAdapter')
const Camera = require('lib/surface/Camera')

const ThangType = require('models/ThangType')
const Lank = require('lib/surface/Lank')

// Takes in a lank and a position. Returns lank with new position.
function moveLank (lank, pos) {
  lank.thang.stateChanged = true
  lank.thang.pos = pos
  return lank
}

const mockThang = () => ({
  health: 10.0,
  maxHealth: 10.0,
  acts: true,
  stateChanged: true,
  pos: {
    x: 2.5,
    y: 1,
    z: 1
  },
  shadow: 0,
  action: 'attack',
  rotation: Math.PI / 2,
  exists: true
})

// export class Test {
//   constructor (canvas) {
//     console.log('initiating the cinematic system')
//     this.stage = new createjs.StageGL(canvas)
//     this.camera = new Camera($(canvas))
//   }
//   use () {
//     console.log('using me')
//     console.log(this)
//     console.log(this.camera)
//   }
// }

/**
 * Takes a reference to a canvas and uses this to construct
 * the cinematic experience.
 * This controller loads a json file and plays cinematics.
 */
export class CinematicController {
  constructor (canvas) {
    this.lank = []
    console.log('initiating the cinematic system')
    this.stage = new createjs.StageGL(canvas)
    const camera = this.camera = new Camera($(canvas))
    this.stubRequiredLayer = new LayerAdapter({ name: 'Ground', webGL: true, camera: camera })
    this.layerAdapter = new LayerAdapter({ name: 'Default', webGL: true, camera: camera })
    this.stage.addChild(this.layerAdapter.container)

    // Count the number of times we are making a new spritesheet
    let count = 0
    this.layerAdapter.on('new-spritesheet', (_spritesheet) => {
      // Now we have a working Anya that we can move around.
      // Potentially use this for loading behavior.
      // By counting how many times this is triggerred by ThangsTypes being loaded.
      console.log('Got a new spritesheet. Count:', ++count)
      // Only register the first time.
      if (count === 1) this.stage.addEventListener('stagemousemove', this.moveHandler.bind(this))
    })

    /**
     * Initialize an example Thang.
     */
    // https://codecombat.com/db/thang.type/cinematic-anya
    const anyaPromise = new Promise((resolve, reject) => new ThangType({ _id: 'cinematic-anya' }).fetch({
      success: resolve,
      error: reject
    }))
    const narrativeSpeaker = new Promise((resolve, reject) => new ThangType({ _id: 'narrative-speaker' }).fetch({
      success: resolve,
      error: reject
    }))

    Promise.all([
      anyaPromise,
      narrativeSpeaker
    ])
      .then((results) => {
        for (const thangType of results) {
          thangType.buildSpriteSheet({
            resolutionFactor: 20,
            async: true
          })
          this.createLankFromThang({ thangType })
        }
      })
      .then(() => this.initTicker(), e => console.error(e))
      .then(() => this.camera.zoomTo({ x: 0, y: 0 }, 7, 0))
      .catch(e => {
        throw new Error(`Failure when loading Anya`)
      })
  }

  initTicker () {
    createjs.Ticker.framerate = 30
    const listener = {
      handleEvent: () => {
        for (const lank of this.lank) {
          lank.update(true)
        }

        this.stage.update()
      }
    }
    createjs.Ticker.addEventListener('tick', listener)
  }

  moveHandler (e) {
    // We get the X and Y from the event.
    const { stageX, stageY } = e
    // Transform mouse coordinates to world meters.
    const result = this.camera.canvasToWorld({ x: stageX, y: stageY })
    // we move the lank.
    for (const lank of this.lank) {
      moveLank(lank, _.clone(result))
      result.x += 2
    }
  }

  createLankFromThang ({ thangType }) {
    console.log(`Creating thang for ${thangType.get('name')}`)
    const lank = new Lank(thangType, {
      resolutionFactor: 60,
      preloadSounds: false,
      thang: mockThang(),
      camera: this.camera,
      // This must be passed in as `new Mark` uses a groundLayer.
      // Without this nothing works. In this case I am using a dummy layer.
      // Cinematics doesn't require Marks
      groundLayer: this.stubRequiredLayer
    })

    // Register lank to the controller.
    this.lank.push(lank)

    return this.showLank(lank)
  }

  showLank (lank) {
    this.layerAdapter.addLank(lank)
    this.layerAdapter.updateLayerOrder()
  }
}
