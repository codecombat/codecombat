import CinematicLankBoss from './CinematicLankBoss'
import DialogSystem from './dialogSystem'
import Loader from './Loader'
import { parseShot } from './Command/CinematicParser'
import CommandRunner from './Command/CommandRunner'

const createjs = require('lib/createjs-parts')
const LayerAdapter = require('lib/surface/LayerAdapter')
const Camera = require('lib/surface/Camera')

/**
 * Takes a reference to a canvas and uses this to construct
 * the cinematic experience.
 * This controller loads a json file and plays cinematics.
 */
export class CinematicController {
  constructor ({ canvas, canvasDiv, slug }) {
    this.systems = {}

    this.stage = new createjs.StageGL(canvas)
    const camera = this.systems.camera = new Camera($(canvas))
    this.stubRequiredLayer = new LayerAdapter({ name: 'Ground', webGL: true, camera: camera })
    this.layerAdapter = new LayerAdapter({ name: 'Default', webGL: true, camera: camera })
    this.stage.addChild(this.layerAdapter.container)

    // Count the number of times we are making a new spritesheet
    let count = 0
    this.startupLocks = []
    this.startupLocks.push(new Promise((resolve, reject) => {
      this.layerAdapter.on('new-spritesheet', (_spritesheet) => {
        resolve()
        // Now we have a working Anya that we can move around.
        // Potentially use this for loading behavior.
        // By counting how many times this is triggerred by ThangsTypes being loaded.
        console.log('Got a new spritesheet. Count:', ++count)
        // Only register the first time.
        // if (count === 1) this.stage.addEventListener('stagemousemove', this.moveHandler.bind(this))
      })
    }))

    this.systems.camera.zoomTo({ x: 0, y: 0 }, 7, 0)

    this.systems.cinematicLankBoss = new CinematicLankBoss({
      groundLayer: this.stubRequiredLayer,
      layerAdapter: this.layerAdapter,
      camera: this.systems.camera
    })

    this.systems.dialogSystem = new DialogSystem({ canvasDiv, camera })
    this.systems.loader = new Loader({ slug })

    this.startUp()
  }

  /**
   * Currently this function handles the asynchronous startup of the cinematic.
   * Hard coding some position starts.
   */
  async startUp () {
    const data = await this.systems.loader.loadAssets()

    const commands = parseShot(data.shots[0], this.systems)
    console.log('commands', commands)

    // TODO: I hate this. There must be a better way than an array of locks!
    await Promise.all(this.startupLocks)
    this.initTicker()

    const runner = new CommandRunner(commands)
    await runner.run()
  }

  /**
   * Starts the render loop of the stage.
   */
  initTicker () {
    createjs.Ticker.framerate = 30
    const listener = {
      handleEvent: () => {
        this.systems.cinematicLankBoss.update(true)
        this.stage.update()
      }
    }
    createjs.Ticker.addEventListener('tick', listener)
  }
}
