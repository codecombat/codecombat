import CinematicLankBoss from './CinematicLankBoss'
import DialogSystem from './dialogSystem'

const createjs = require('lib/createjs-parts')
const LayerAdapter = require('lib/surface/LayerAdapter')
const Camera = require('lib/surface/Camera')

const ThangType = require('models/ThangType')
const Lank = require('lib/surface/Lank')

/**
 * After processing should have a list of promises.
 *
 * Animations need to have a reference kept in case they need to
 * be moved to the end very quickly. Will need a system for
 * keeping track on animations by some generated id's. Once
 * animations complete can remove them from the store.
 *
 * We will need a converted from data -> promise thunks
 */
const hardcodedByteCodeExample = ({ cinematicLankBoss, dialogSystem }) => ([
  () => sleep(2000),
  () => Promise.race([sleep(0), cinematicLankBoss.moveLank('left', { x: -3 }, 2000)]),
  () => sleep(500),
  () => Promise.race([sleep(0), cinematicLankBoss.moveLank('right', { x: 3 }, 2000)]),
  () => sleep(500),
  () => dialogSystem.createBubble({
    htmlString: '<div>Want a high five!?</div>',
    x: 200,
    y: 200
  }),
  () => Promise.all([sleep(500), cinematicLankBoss.queueAction('left', 'attack')]),
  () => cinematicLankBoss.moveLank('right', { x: 10 }, 1000),
  () => dialogSystem.createBubble({
    htmlString: '<div>Oh no! My <b>sword</b> was attached!</div>',
    x: 200,
    y: 200
  }),
  () => cinematicLankBoss.moveLank('left', { x: -10 }, 10000)
])

/**
 * Creates a mock thang. Looking left by default. 0 is looking right.
 * @param {Number} rotation - Rotation of thang in radians.
 */
const mockThang = (options) => {
  const defaults = {
    health: 10.0,
    maxHealth: 10.0,
    acts: true,
    stateChanged: true,
    pos: {
      x: 0,
      y: 0,
      z: 1
    },
    shadow: 0,
    action: 'idle',
    //  Looking left
    rotation: 0
  }
  return _.merge(defaults, options)
}

/**
 * Returns a promise that will resolve after the given milliseconds.
 * @param {Number} ms number of milliseconds before promise resolves
 */
function sleep(ms) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, ms)
  })
}

/**
 * Takes a reference to a canvas and uses this to construct
 * the cinematic experience.
 * This controller loads a json file and plays cinematics.
 */
export class CinematicController {
  constructor (canvas, canvasDiv) {
    this.cinematicLankBoss = new CinematicLankBoss()
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
      // if (count === 1) this.stage.addEventListener('stagemousemove', this.moveHandler.bind(this))
    })

    this.camera.zoomTo({ x: 0, y: 0 }, 7, 0)

    this.stageBounds = {
      topLeft: this.camera.canvasToWorld({ x: 0, y: 0 }),
      bottomRight: this.camera.canvasToWorld({ x: this.camera.canvasWidth, y: this.camera.canvasHeight })
    }

    this.dialogSystem = new DialogSystem({ canvasDiv, camera })

    this.startUp()
  }

  /**
   * Currently this function handles the asynchronous startup of the cinematic.
   * Hard coding some position starts.
   */
  async startUp () {
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

    const [anyaThang, narratorThang] = await Promise.all([
      anyaPromise,
      narrativeSpeaker
    ])

    const leftLank = await this.createLankFromThang({ thangType: anyaThang,
      thang: mockThang({
        pos: {
          x: this.stageBounds.topLeft.x - 2,
          y: this.stageBounds.bottomRight.y
        }
      })
    })
    const rightLank = await this.createLankFromThang({ thangType: narratorThang,
      thang: mockThang({
        rotation: Math.PI / 2,
        pos: {
          x: this.stageBounds.bottomRight.x + 2,
          y: this.stageBounds.bottomRight.y
        }
      })
    })

    this.cinematicLankBoss.registerLank('left', leftLank)
    this.cinematicLankBoss.registerLank('right', rightLank)

    this.initTicker()

    // Consume some hard coded pretend bytecode.
    const promiseThunks = hardcodedByteCodeExample({ cinematicLankBoss: this.cinematicLankBoss, dialogSystem: this.dialogSystem });
    for (const thunk of promiseThunks) {
      await thunk()
    }
  }

  /**
   * Starts the render loop of the stage.
   */
  initTicker () {
    createjs.Ticker.framerate = 30
    const listener = {
      handleEvent: () => {
        this.cinematicLankBoss.update(true)
        this.stage.update()
      }
    }
    createjs.Ticker.addEventListener('tick', listener)
  }

  /**
   * Creates a lank from a thangType and a thang.
   * The ThangType is the art and animation information.
   * The thang is like the instance of the ThangType.
   */
  createLankFromThang ({ thangType, thang }) {
    const lank = new Lank(thangType, {
      resolutionFactor: 60,
      preloadSounds: false,
      thang,
      camera: this.camera,
      // This must be passed in as `new Mark` uses a groundLayer.
      // Without this nothing works. In this case I am using a dummy layer.
      // Cinematics doesn't require Marks
      groundLayer: this.stubRequiredLayer
    })

    this.layerAdapter.addLank(lank)

    return Promise.resolve(lank)
  }
}
