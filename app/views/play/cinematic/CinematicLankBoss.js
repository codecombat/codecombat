import anime from 'animejs/lib/anime.es.js'
import Promise from 'bluebird'
import AbstractCommand, { Noop } from './ByteCode/AbstractCommand'

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
  registerLank (side, lank) {
    assertSide(side)
    this[side] = lank
  }

  /**
   * Moves either the left or right lank to a given co-ordinates.
   * @param {'left'|'right'} side - the lank being moved.
   * @param {{x, y}} pos - the position in meters to move towards.
   * @param {Number} ms - the time it will take to move.
   */
  moveLank (side, pos = {}, ms = 0) {
    assertSide(side)
    // normalize parameters
    pos.x = pos.x || this[side].thang.pos.x
    pos.y = pos.y || this[side].thang.pos.y
    if (this[side].thang.pos.x === pos.x && this[side].thang.pos.y === pos.y) {
      return
    }
    // Slides a lank to a given position, returning a promise
    // that completes when the tween is complete.
    return new Promise((resolve, reject) => {
    })
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
}

function assertSide (side) {
  if (!['left', 'right'].includes(side)) {
    throw new Error(`Expected one of 'left' or 'right', got ${side}`)
  }
}
