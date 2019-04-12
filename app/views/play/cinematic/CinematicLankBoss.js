import anime from 'animejs/lib/anime.es.js'
import Promise from 'bluebird'
import AbstractCommand, { Noop } from './ByteCode/AbstractCommand'

const Lank = require('lib/surface/Lank')

Promise.config({
  cancellation: true
})

/**
 * Creates a mock thang. Looking left by default. 0 is looking right.
 * @param {Number} rotation - Rotation of thang in radians.
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

class MoveLank extends AbstractCommand {
  constructor (runFn, skipTweenFn) {
    super()
    this.run = runFn
    this.skipTweenFn = skipTweenFn
  }

  preCancel () {
    this.skipTweenFn()
    return 'cancel'
  }
}

/**
 * Registers the thangs and ThangTypes onto Lanks.
 * Then animates these Lanks to create a cinematic.
 * Instead of immediately executing methods, instead returns a Command that
 * can be run by the cinematic runner.
 */
export default class CinematicLankBoss {
  constructor ({ groundLayer, layerAdapter, camera }) {
    this.groundLayer = groundLayer
    this.layerAdapter = layerAdapter
    this.camera = camera
    this.stageBounds = {
      topLeft: this.camera.canvasToWorld({ x: 0, y: 0 }),
      bottomRight: this.camera.canvasToWorld({ x: this.camera.canvasWidth, y: this.camera.canvasHeight })
    }
  }

  registerLank (side, lank) {
    assertSide(side)
    this[side] = lank
  }

  /**
   * Moves either the left or right lank to a given co-ordinates **instantly**.
   * @param {'left'|'right'} side - the lank being moved.
   * @param {{x, y}} pos - the position in meters to move towards.
   * @param {Number} ms - the time it will take to move.
   */
  moveLank (side, pos = {}, ms = 0) {
    assertSide(side)

    // normalize parameters
    this[side].thang.pos.x = pos.x || this[side].thang.pos.x
    this[side].thang.pos.y = pos.y || this[side].thang.pos.y

    // Ensures lank is rendered.
    this[side].thang.stateChanged = true
  }

  /**
   * Returns a command that will move the lank.
   * @param {string} side - 'left' or 'right'
   * @param {Object} pos
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
      update: () => { this[side].thang.stateChanged = true }
    })

    const runFn = () => new Promise((resolve, reject) => {
      animation.complete = resolve
      animation.play()
    })

    const cancelFn = () => {
      animation.seek(animation.duration)
    }

    return new MoveLank(runFn, cancelFn)
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
   * Needs to be able to check if there is an existing
   * lank and handle appropriately.
   * If a lank is created, it's always created offscreen.
   *
   * TODO: Handle existing lank
   *
   * @param {string} side - 'left' or 'right
   * @param {*} thangType
   * @param {*} systems
   */
  addLank (side, thangType, systems) {
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
      camera: systems.camera,
      groundLayer: this.groundLayer
    })

    this.layerAdapter.addLank(lank)
    this.registerLank(side, lank)
  }
}

function assertSide (side) {
  if (!['left', 'right'].includes(side)) {
    throw new Error(`Expected one of 'left' or 'right', got ${side}`)
  }
}
