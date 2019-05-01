import CinematicLankBoss from './CinematicLankBoss'
import Loader from './Loader'
import { parseShot } from './Command/CinematicParser'
import CommandRunner from './Command/CommandRunner'
import DialogSystem from './DialogSystem'
import { CameraSystem } from './CameraSystem';

const createjs = require('lib/createjs-parts')
const LayerAdapter = require('lib/surface/LayerAdapter')
const Camera = require('lib/surface/Camera')

/**
 * Takes a reference of the canvas and uses this to set up all the systems.
 * The canvasDiv will be used by the dialogSystem in order to attach the html dialog div
 * and svg image overlaying the base canvas.
 * Finally the slug is used to load the relevant cinematic data.
 */
export class CinematicController {
  constructor ({
    canvas,
    canvasDiv,
    cinematicData,
    handlers: {
      onPlay,
      onPause,
      onCompletion
    }
  }) {
    this.onPlay = onPlay || (() => {})
    this.onPause = onPause || (() => {})
    this.onCompletion = onCompletion || (() => {})

    this.systems = {}

    this.stage = new createjs.StageGL(canvas)
    const camera = new Camera($(canvas))
    // stubRequiredLayer needed by Lanks as a dependency. We don't attach to canvas.
    this.stubRequiredLayer = new LayerAdapter({ name: 'Ground', webGL: true, camera: camera })

    this.layerAdapter = new LayerAdapter({ name: 'Default', webGL: true, camera: camera })
    this.backgroundAdapter = new LayerAdapter({ name: 'Background', webGL: true, camera: camera })
    this.stage.addChild(this.backgroundAdapter.container)
    this.stage.addChild(this.layerAdapter.container)

    camera.zoomTo({ x: 0, y: 0 }, 6, 0)
    this.systems.cameraSystem = new CameraSystem(camera)
    this.systems.loader = new Loader({ data: cinematicData })

    this.systems.dialogSystem = new DialogSystem({
      canvasDiv,
      camera
    })

    this.systems.dialogSystem.templateContext = {
      name: me.get('name') || 'hero'
    }

    this.systems.cinematicLankBoss = new CinematicLankBoss({
      groundLayer: this.stubRequiredLayer,
      layerAdapter: this.layerAdapter,
      backgroundAdapter: this.backgroundAdapter,
      camera: camera,
      loader: this.systems.loader
    })

    this.commands = []

    this.startUp()
  }

  /**
   * Method that loads and initializes the cinematic.
   *
   *
   * Finally we run the cinematic runner.
   */
  async startUp () {
    const data = await this.systems.loader.loadAssets()

    const commands = data.shots
      .map(shot => parseShot(shot, this.systems))
      .filter(commands => commands.length > 0)
      .reduce((acc, commands) => [...acc, ...commands], [])

    attachListener({ cinematicLankBoss: this.systems.cinematicLankBoss, stage: this.stage })

    this.commands = commands
  }

  /**
   * Used to cancel the current shot.
   */
  cancelShot () {
    if (!this.runner) return
    this.runner.cancel()
    this.cleanupRunShot()
  }

  /**
   * Runs the next shot, mutating `this.commands`.
   */
  runShot () {
    if (this.runner) return
    this.onPlay()

    if (!Array.isArray(this.commands) || this.commands.length === 0) {
      return
    }
    const currentShot = this.commands.shift()
    console.log(`Running batch of commands:`, { currentShot })
    this._runShot(currentShot)
  }

  /**
   * Runs the provided shot to completion. Calls the `onPlay` when cinematic starts
   * playing and calls `onPause` on the conclusion of the shot.
   * @param {AbstractCommand[]} commands - List of commands. When user cancels it runs to the end of the list.
   */
  async _runShot (currentShot) {
    if (!Array.isArray(currentShot) || currentShot.length === 0) {
      return
    }

    const [runner, runningCommands] = runCommands(currentShot)
    this.runner = runner

    // Block on running commands
    await runningCommands
    this.cleanupRunShot()
  }

  /**
   * cleanupRun disposes of the runner and calls the `onPause` callback
   * to signal that we're not running a shot.
   * If the entire cinematic has completed we call the `onCompletion`.
   */
  cleanupRunShot () {
    if (!this.runner) return
    this.runner = null
    this.onPause()
    if (Array.isArray(this.commands) && this.commands.length === 0) {
      this.onCompletion()
    }
  }
}

/**
 * Runs an array of commands. If the user cancels it will consume this entire
 * array. Thus you should only call this for ShotSetup + DialogNode 1 or for a
 * single dialogNode.
 *
 * Returns the running commandRunner to handle cancellation.
 *
 * @param {AbstractCommand[]} commands
 * @returns {CommandRunner} the running commandRunner.
 */
function runCommands (commands) {
  const runner = new CommandRunner(commands)
  return [runner, runner.run()]
}

/**
 * Starts the render loop of the stage.
 * Currently configured for 30 frames per second.
 *
 * The returned listener can be removed from the Ticker in order to pause rendering.
 *
 * ```js
 * // Attach listener
 * const listener = attachListener({ cinematicLankBoss, stage })
 * // Remove listener again
 * createjs.Ticker.removeEventListener('tick', listener)
 * ```
 *
 * @returns {Function} listener that was attached to createjs.Ticker
 */
function attachListener ({ cinematicLankBoss, stage }) {
  createjs.Ticker.framerate = 30
  const listener = () => {
    cinematicLankBoss.update(true)
    stage.update()
  }
  createjs.Ticker.addEventListener('tick', listener)
  // Return listener for removing event.
  return listener
}
