import anime from 'animejs/lib/anime.es.js'
import { Noop, AnimeCommand } from './Command/AbstractCommand'
import { getLeftCharacterThangTypeSlug, getRightCharacterThangTypeSlug } from '../../../schemas/selectors/cinematic'

const Lank = require('lib/surface/Lank')

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

    if (leftCharSlug) {
      const { slug, enterOnStart, position } = leftCharSlug
      this.addLank('left', this.loader.getThangType(slug))
      if (enterOnStart) {
        commands.push(this.moveLankCommand('left', position))
      } else {
        this.moveLank('left', position)
      }
    }

    const rightCharSlug = getRightCharacterThangTypeSlug(shot)
    if (rightCharSlug) {
      const { slug, enterOnStart, position } = rightCharSlug
      this.addLank('right', this.loader.getThangType(slug))
      if (enterOnStart) {
        commands.push(this.moveLankCommand('right', position))
      } else {
        this.moveLank('right', position)
      }
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
  moveLank (side, pos = {}) {
    assertSide(side)

    // normalize parameters
    this[side].thang.pos.x = pos.x || this[side].thang.pos.x
    this[side].thang.pos.y = pos.y || this[side].thang.pos.y

    // Ensures lank is rendered.
    this[side].thang.stateChanged = true
  }

  /**
   * Returns a command that will move the lank.
   * @param {'left'|'right'} side
   * @param {{x, y}} pos
   * @param {number} ms
   */
  moveLankCommand (side, pos = {}, ms = 1000) {
    assertSide(side)

    // normalize parameters
    pos.x = pos.x || this[side].thang.pos.x
    pos.y = pos.y || this[side].thang.pos.y
    if (this[side].thang.pos.x === pos.x && this[side].thang.pos.y === pos.y) {
      return new Noop()
    }

    const animation = anime({
      targets: this[side].thang.pos,
      x: pos.x,
      y: pos.y,
      duration: ms,
      autoplay: false,
      easing: 'easeInOutQuart',
      // Inform update engine to rerender thang at new position.
      update: () => { this[side].thang.stateChanged = true },
      complete: () => { this[side].thang.stateChanged = true }
    })

    return new AnimeCommand(animation)
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
   * TODO: Handle existing lank
   *
   * @param {'left'|'right'} side
   * @param {Object} thangType
   * @param {Object} systems
   */
  addLank (side, thangType) {
    assertSide(side)
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
