import CinematicLankBoss from './CinematicLankBoss'
import Loader from './Loader'
import { parseShot } from './commands/CinematicParser'
import CommandRunner from './commands/CommandRunner'
import DialogSystem from './dialogsystem/DialogSystem'
import { CameraSystem } from './CameraSystem'
import { SoundSystem } from './SoundSystem'
import Autoplay from './systems/autoplay'
import UndoSystem from './UndoSystem'
import { SyncFunction } from './commands/commands'
import VisualChalkboard from './systems/visualChalkboard'
import FadeSystem from './systems/FadeSystem'

const createjs = require('lib/createjs-parts')
const LayerAdapter = require('lib/surface/LayerAdapter')
const Camera = require('lib/surface/Camera')

const UNDO_MODE = Symbol('undo')
const FORWARD_MODE = Symbol('forward')

const CINEMATIC_SPRITE_RESOLUTION_FACTOR = 1
const CINEMATIC_BACKGROUND_OBJECT_RESOLUTION_FACTOR = 3

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
      onCompletion,
      onLoaded
    },
    userOptions: {
      programmingLanguage
    } = {}
  }) {
    this.onPlay = onPlay || (() => {})
    this.onPause = onPause || (() => {})
    this.onCompletion = onCompletion || (() => {})
    this.onLoaded = onLoaded || (() => {})

    this.userOptions = {
      programmingLanguage: programmingLanguage || 'python'
    }

    this.systems = {}

    this.stage = new createjs.StageGL(canvas)
    const camera = new Camera($(canvas))
    // stubRequiredLayer needed by Lanks as a dependency. We don't attach to canvas.
    this.stubRequiredLayer = new LayerAdapter({ name: 'Ground', webGL: true, camera: camera })

    this.layerAdapter = new LayerAdapter({ name: 'Default', webGL: true, camera: camera })
    this.backgroundObjectAdapter = new LayerAdapter({ name: 'Background Object', webGL: true, camera: camera })
    this.backgroundAdapter = new LayerAdapter({ name: 'Background', webGL: true, camera: camera })
    this.layerAdapter.resolutionFactor = CINEMATIC_SPRITE_RESOLUTION_FACTOR
    this.backgroundAdapter.resolutionFactor = CINEMATIC_SPRITE_RESOLUTION_FACTOR
    this.backgroundObjectAdapter.resolutionFactor = CINEMATIC_BACKGROUND_OBJECT_RESOLUTION_FACTOR
    this.stage.addChild(this.backgroundAdapter.container)
    this.stage.addChild(this.backgroundObjectAdapter.container)
    this.stage.addChild(this.layerAdapter.container)

    this.systems.cameraSystem = new CameraSystem(camera)
    this.systems.loader = new Loader({ data: cinematicData })
    this.systems.fadeSystem = new FadeSystem()
    this.systems.sound = new SoundSystem()
    this.systems.autoplay = new Autoplay()
    this.systems.visualChalkboard = new VisualChalkboard()

    this.systems.dialogSystem = new DialogSystem({
      canvasDiv,
      camera
    })

    this.systems.dialogSystem.templateContext = {
      name: (me.get('ozariaUserOptions') || {}).playerHeroName || me.get('name') || 'hero'
    }

    this.systems.cinematicLankBoss = new CinematicLankBoss({
      groundLayer: this.stubRequiredLayer,
      layerAdapter: this.layerAdapter,
      backgroundAdapter: this.backgroundAdapter,
      backgroundObjectAdapter: this.backgroundObjectAdapter,
      camera: camera,
      loader: this.systems.loader
    })

    // This is a singleton. Used so commands can hook into the undo system
    // via dependency injection. Because this is a singleton we need to clear it
    // at the start of every cinematic or the commands will persist between
    // cinematics.
    this.undoCommands = UndoSystem
    this.undoCommands.reset()

    this.commands = []
    this.mode = FORWARD_MODE
    this.wasCancelled = false

    // Explicitly setting class as non reactive for performance benefit.
    Vue.nonreactive(this)

    this.startUp()
  }

  get hasActiveRunner () {
    const hasRunner = !!this.runner
    // Defensive in order to avoid a bad state.
    if (!hasRunner) {
      console.warn(`cinematicController: 'wasCancelled' state unexpected.`)
      this.wasCancelled = false
    }

    return hasRunner
  }

  /**
   * Method that loads and initializes the cinematic.
   *
   * Finally we run the cinematic runner.
   */
  async startUp () {
    const data = await this.systems.loader.loadAssets()

    const commands = data.shots
      .map(shot => parseShot(shot, this.systems, this.userOptions))
      .filter(commands => commands.length > 0)
      .reduce((acc, commands) => [...acc, ...commands], [])

    attachListener({ cinematicLankBoss: this.systems.cinematicLankBoss, stage: this.stage })

    this.commands = commands

    await this.systems.cinematicLankBoss.preloaded() // NOTE: This will always complete after about ~2.5 minutes. It has a failsafe.
    for (const preloadedLank of Object.values(this.systems.cinematicLankBoss.lankCache)) {
      preloadedLank.hide()
    }

    // Provide time for the loaded lanks to be hidden. Otherwise there can be a disruptive flash.
    setTimeout(() => {
      this.onLoaded()
    }, 100)
  }

  /**
   * Used to cancel the current shot.
   */
  cancelShot () {
    if (!this.hasActiveRunner) return
    this.runner.cancel()
    this.wasCancelled = true
  }

  /**
   * Runs the next shot, mutating `this.commands`.
   */
  runShot (autoplaying = false) {
    if (this.hasActiveRunner) return

    if (!Array.isArray(this.commands) || this.commands.length === 0) {
      this.systems.sound.stopAllSounds()
      return
    }
    this.onPlay()

    this.undoCommands.ignoreUndoCommands = false
    this.mode = FORWARD_MODE

    if (autoplaying) {
      // If this shot is being played from an autoplay node, we need to ensure we
      // autoplay back through the undo.
      this.undoCommands.pushUndoCommand(new SyncFunction(() => {
        this.systems.autoplay.autoplay = true
      }))
    }

    const currentShot = this.commands.shift()
    this.undoCommands.pushUsedForwardCommands([...currentShot])

    this._runShot(currentShot)

    if (this.wasCancelled) {
      this.cancelShot()
    }
  }

  undoShot () {
    if (this.hasActiveRunner) return

    if (!this.undoCommands.canUndo) {
      return
    }
    this.mode = UNDO_MODE
    this.undoCommands.ignoreUndoCommands = true

    this.onPlay()

    const { forwardCommands, undoCommands } = this.undoCommands.popUndoCommands()
    this.commands.unshift(forwardCommands)

    // Run side effects that would undo the shot.
    this._runShot(undoCommands)
  }

  /**
   * Runs the provided shot to completion. Calls the `onPlay` when cinematic starts
   * playing and calls `onPause` on the conclusion of the shot.
   * @param {AbstractCommand[]} commands - List of commands. When user cancels it runs to the end of the list.
   */
  async _runShot (shotCommands) {
    if (!Array.isArray(shotCommands) || shotCommands.length === 0) {
      this.onPause()
      return
    }

    const [runner, runningCommands] = runCommands(shotCommands)
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
    if (!this.hasActiveRunner) return
    this.runner = null

    if (Array.isArray(this.commands) && this.commands.length === 0) {
      this.onCompletion()
    }

    // TODO: Do we undo again (autoplay situation???)
    if (this.mode === FORWARD_MODE) {
      this.undoCommands.endPlayingShot()
    }

    if (this.systems.autoplay.autoplay && this.mode === UNDO_MODE) {
      this.systems.autoplay.autoplay = false
      return this.undoShot()
    }

    if (this.systems.autoplay.autoplay) {
      this.systems.autoplay.autoplay = false
      return this.runShot(true)
    }

    this.undoCommands.tryMarkFirstStoppingPoint()

    if (this.wasCancelled) {
      this.wasCancelled = false
      return this.runShot(false)
    }

    this.onPause()
  }

  onResize ({ width, height }) {
    this.stage.updateViewport(width, height)
    this.systems.cameraSystem.camera.onResize(width, height)
  }

  destroy () {
    createjs.Ticker.removeAllEventListeners()
    this.systems.cameraSystem.destroy()
    this.systems.cinematicLankBoss.cleanup()
    this.stage.removeAllEventListeners()
    this.systems.sound.stopAllSounds()
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
  const listener = (e) => {
    cinematicLankBoss.update(true)
    stage.update(e)
  }
  createjs.Ticker.addEventListener('tick', listener)
  // Return listener for removing event.
  return listener
}
