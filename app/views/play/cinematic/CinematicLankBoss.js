import anime from 'animejs/lib/anime.es.js'
import AbstractCommand, { Noop, SyncFunction } from './Command/AbstractCommand'
import { getLeftCharacterThangTypeSlug, getRightCharacterThangTypeSlug, leftHero, rightHero } from '../../../schemas/selectors/cinematic'

// Throws an error if `import ... from ..` syntax.
const Promise = require('bluebird')
const Lank = require('lib/surface/Lank')

Promise.config({
  cancellation: true
})

/**
 * @typedef {import(./Command/CinematicParser).System} System
 */

/**
 * Registers the thangs and ThangTypes onto Lanks.
 * Then animates these Lanks to create a cinematic.
 * Instead of immediately executing methods, instead returns a Command that
 * can be run by the cinematic runner.
 *
 * @implements {System}
 */
export default class CinematicLankBoss {
  constructor ({ groundLayer, layerAdapter, camera, loader }) {
    this.groundLayer = groundLayer
    this.layerAdapter = layerAdapter
    this.camera = camera
    this.stageBounds = {
      topLeft: this.camera.canvasToWorld({ x: 0, y: 0 }),
      bottomRight: this.camera.canvasToWorld({ x: this.camera.canvasWidth, y: this.camera.canvasHeight })
    }
    this.loader = loader
  }

  /**
   * Returns a list of commands that correctly set up the shot.
   * @param {Shot} shot - the cinematic shot data.
   */
  parseSetupShot (shot) {
    const leftCharSlug = getLeftCharacterThangTypeSlug(shot)
    const commands = []

    const moveCharacter = (side, resource, enterOnStart, position) => {
      if (enterOnStart) {
        commands.push(this.moveLankCommand(side, resource, position))
      } else {
        commands.push(this.moveLank(side, resource, position))
      }
    }

    if (leftCharSlug) {
      const { slug, enterOnStart, position } = leftCharSlug
      moveCharacter('left', slug, enterOnStart, position)
    }

    const lHero = leftHero(shot)
    if (lHero) {
      const { original, enterOnStart, position } = lHero
      moveCharacter('left', original, enterOnStart, position)
    }

    const rightCharSlug = getRightCharacterThangTypeSlug(shot)
    if (rightCharSlug) {
      const { slug, enterOnStart, position } = rightCharSlug
      moveCharacter('right', slug, enterOnStart, position)
    }

    const rHero = rightHero(shot)
    if (rHero) {
      const { original, enterOnStart, position } = rHero
      moveCharacter('right', original, enterOnStart, position)
    }

    return commands
  }

  registerLank (side, lank) {
    assertSide(side)
    this[side] = lank
  }

  /**
   * Moves either the left or right lank to a given co-ordinates **instantly**.
   * @param {'left'|'right'} side - the lank being moved.
   * @param {{x, y}} pos - the position in meters to move towards.
   */
  moveLank (side, resource, pos = {}) {
    assertSide(side)

    return new SyncFunction(() => {
      this.addLank(side, this.loader.getThangType(resource))

      // normalize parameters
      this[side].thang.pos.x = pos.x !== undefined ? pos.x : this[side].thang.pos.x
      this[side].thang.pos.y = pos.y !== undefined ? pos.y : this[side].thang.pos.y

      // Ensures lank is rendered.
      this[side].thang.stateChanged = true
    })
  }

  /**
   * Returns a command that will move the lank.
   * @param {'left'|'right'} side
   * @param {{x, y}} pos
   * @param {number} ms
   */
  moveLankCommand (side, resource, pos = {}, ms = 1000) {
    assertSide(side)
    return new MoveLank((commandCtx) => {
      this.addLank(side, this.loader.getThangType(resource))

      // normalize parameters
      pos.x = pos.x !== undefined ? pos.x : this[side].thang.pos.x
      pos.y = pos.y !== undefined ? pos.y : this[side].thang.pos.y
      if (this[side].thang.pos.x === pos.x && this[side].thang.pos.y === pos.y) {
        return new Noop()
      }

      const animation = anime({
        targets: this[side].thang.pos,
        x: pos.x,
        y: pos.y,
        duration: ms,
        autoplay: false,
        delay: 500, // Hack to provide some time for lank to load.
        easing: 'easeInOutQuart',
        // Inform update engine to rerender thang at new position.
        update: () => { this[side].thang.stateChanged = true },
        complete: () => { this[side].thang.stateChanged = true }
      })

      commandCtx.animation = animation
      return new Promise((resolve, reject) => {
        animation.play()
        animation.complete = resolve
      })
    })
  }

  queueAction (side, action) {
    assertSide(side)
    this[side].queueAction(action)
    return Promise.resolve(null)
  }

  /**
   * Updates the left and right lank if they exist.
   * @param {bool} frameChanged - Needs to be true for Lank updates to occur.
   */
  update (frameChanged) {
    this.left && this.left.update(frameChanged)
    this.right && this.right.update(frameChanged)
  }

  /**
   * Adds a lank to the given side.
   * Needs to be able to check if there is an existing lank and handle appropriately.
   * If a lank is created, it's always created offscreen.
   *
   * Handles existing lank by removing it.
   *
   * @param {'left'|'right'} side
   * @param {Object} thangType
   * @param {Object} systems
   */
  addLank (side, thangType) {
    assertSide(side)
    if (this[side] && this[side].thangType) {
      const original = this[side].thangType.get('original')
      if (thangType.get('original') === original) {
        // It's the same thangType. Don't add a new Lank.
        return
      } else {
        // Remove old lank.
        const lank = this[side]
        lank.layer.removeLank(lank)
        delete this[side]
        lank.destroy()
      }
    }

    const thang = side === 'left'
      ? createThang({ pos: {
        x: this.stageBounds.topLeft.x - 2,
        y: this.stageBounds.bottomRight.y
      }
      })
      : createThang({ pos: {
        x: this.stageBounds.bottomRight.x + 2,
        y: this.stageBounds.bottomRight.y
      },
      rotation: Math.PI
      })
    const lank = new Lank(thangType, {
      resolutionFactor: 60,
      preloadSounds: false,
      thang,
      camera: this.camera,
      groundLayer: this.groundLayer
    })

    this.layerAdapter.addLank(lank)
    this.registerLank(side, lank)
  }
}

/**
 * Creates a mock thang. Looking left by default.
 * You can pass in options to override default thang properties.
 *
 * A rotation of `Math.PI` is looking right.
 *
 * @param {Object} options - is merged onto default thang options
 * @returns {Object} thang object
 */
const createThang = (options) => {
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
 * @param {string} side - string enum of either 'left' or 'right'.
 */
function assertSide (side) {
  if (!['left', 'right'].includes(side)) {
    throw new Error(`Expected one of 'left' or 'right', got ${side}`)
  }
}

/**
 * Run methods initialized the Lank and then runs the animation.
 */
class MoveLank extends AbstractCommand {
  /**
   * Loads relevant Lanks via CinematicLankBoss.
   * @param {Function} runFn takes the command instance as an argument.
   */
  constructor (runFn) {
    super()
    this.run = () => runFn(this)
  }

  cancel (promise) {
    const animation = this.animation
    if (!animation) {
      throw new Error('Incorrect use of MoveLank. Must attach animation.')
    }
    animation.seek(animation.duration)
    return promise
  }
}
