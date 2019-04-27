import anime from 'animejs/lib/anime.es.js'
import AbstractCommand, { Noop, SyncFunction } from './Command/AbstractCommand'
import { getLeftCharacterThangTypeSlug, getRightCharacterThangTypeSlug, leftHero, rightHero, getBackground, exitCharacter } from '../../../schemas/selectors/cinematic'

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
  constructor ({ groundLayer, layerAdapter, backgroundAdapter, camera, loader }) {
    this.groundLayer = groundLayer
    this.layerAdapters = {
      'Default': layerAdapter,
      'Background': backgroundAdapter
    }
    this.camera = camera
    this.stageBounds = {
      topLeft: this.camera.canvasToWorld({ x: 0, y: 0 }),
      bottomRight: this.camera.canvasToWorld({ x: this.camera.canvasWidth, y: this.camera.canvasHeight })
    }
    this.loader = loader
    this.lanks = {}
  }

  /**
   * Returns a list of commands that correctly set up the shot.
   * @param {Shot} shot - the cinematic shot data.
   */
  parseSetupShot (shot) {
    const commands = []

    const moveCharacter = (side, resource, enterOnStart, pos) => {
      if (enterOnStart) {
        commands.push(this.moveLankCommand({ side, resource, pos }))
      } else {
        commands.push(this.moveLank(side, resource, pos))
      }
    }

    const background = getBackground(shot)
    if (background) {
      commands.push(this.setBackgroundCommand(background))
    }

    const leftCharSlug = getLeftCharacterThangTypeSlug(shot)
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

  parseDialogNode (dialogNode) {
    const commands = []
    const char = exitCharacter(dialogNode)
    if (char === 'left' || char === 'both') {
      commands.push(this.moveLankCommand({ side: 'left', pos: { x: -20, y: 0 } }))
    }
    if (char === 'right' || char === 'both') {
      commands.push(this.moveLankCommand({ side: 'right', pos: { x: 20, y: 0 } }))
    }
    return commands
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
      this.lanks[side].thang.pos.x = pos.x !== undefined ? pos.x : this.lanks[side].thang.pos.x
      this.lanks[side].thang.pos.y = pos.y !== undefined ? pos.y : this.lanks[side].thang.pos.y

      // Ensures lank is rendered.
      this.lanks[side].thang.stateChanged = true
    })
  }

  /**
   * Returns a command that will move the lank.
   * @param {'left'|'right'} side
   * @param {{x, y}} pos
   * @param {number} ms
   */
  moveLankCommand ({ side, resource, pos, ms = 1000 }) {
    assertSide(side)
    return new MoveLank((commandCtx) => {
      if (resource) {
        this.addLank(side, this.loader.getThangType(resource))
      }
      pos = pos || {}
      // normalize parameters
      pos.x = pos.x !== undefined ? pos.x : this.lanks[side].thang.pos.x
      pos.y = pos.y !== undefined ? pos.y : this.lanks[side].thang.pos.y
      if (this.lanks[side].thang.pos.x === pos.x && this.lanks[side].thang.pos.y === pos.y) {
        console.log('noop for', side)
        return new Noop()
      }
      console.log('creating animation')
      const animation = anime({
        targets: this.lanks[side].thang.pos,
        x: pos.x,
        y: pos.y,
        duration: ms,
        autoplay: false,
        delay: 500, // Hack to provide some time for lank to load.
        easing: 'easeInOutQuart',
        // Inform update engine to rerender thang at new position.
        update: () => { this.lanks[side].thang.stateChanged = true },
        complete: () => { this.lanks[side].thang.stateChanged = true }
      })

      commandCtx.animation = animation
      return new Promise((resolve, reject) => {
        animation.play()
        animation.complete = resolve
      })
    })
  }

  /**
   * Sets the background.
   *
   * Intelligently handles backgrounds that may already exist or
   * are simply being moved.
   * @param {Object} background Background object.
   */
  setBackgroundCommand ({ slug, scaleX, scaleY, pos: { x, y } }) {
    return new SyncFunction(() => {
      const thangType = this.loader.getThangType(slug)
      if (!thangType) {
        return
      }
      const thangOptions = {
        scaleFactorX: scaleX,
        scaleFactorY: scaleY,
        pos: { x, y },
        stateChanged: true
      }

      if (this.lanks['background'] && this.lanks['background'].thangType) {
        if (this.lanks['background'].thangType.get('slug') === slug) {
          const thang = this.lanks['background'].thang
          _.merge(thang, thangOptions)
          return
        }
      }

      const backgroundThang = createThang(thangOptions)
      this.addLank('background', thangType, backgroundThang)
    })
  }

  queueAction (side, action) {
    assertSide(side)
    this.lanks[side].queueAction(action)
    return Promise.resolve(null)
  }

  /**
   * Updates the left and right lank if they exist.
   * @param {bool} frameChanged - Needs to be true for Lank updates to occur.
   */
  update (frameChanged) {
    Object.values(this.lanks)
      .forEach(lank => lank.update(frameChanged))
  }

  /**
   * Adds a lank to the screen.
   *
   * If the lank already exists this method is a noop.
   * Otherwise if there is a conflicting lank it is removed and replaced.
   * Automatically flips a lank if they key is `right` in order to accomodate for
   * right hand side characters.
   *
   * @param {string} key
   * @param {Object} thangType
   * @param {Object|undefined} thang?
   */
  addLank (key, thangType, thang = undefined) {
    if (this.lanks[key] && this.lanks[key].thangType) {
      const original = this.lanks[key].thangType.get('original')
      if (thangType.get('original') === original) {
        // It's the same thangType. Don't add a new Lank.
        return
      } else {
        // Remove old lank.
        const lank = this.lanks[key]
        lank.layer.removeLank(lank)
        delete this.lanks[key]
        lank.destroy()
      }
    }

    // TODO: Refactor this out, and pass in thang.
    if (key === 'right' && !thang) {
      thang = createThang({
        pos: {
          x: this.stageBounds.bottomRight.x + 2,
          y: this.stageBounds.bottomRight.y
        },
        rotation: Math.PI
      })
    } else if (key === 'background' && !thang) {
      thang = createThang({
        scaleFactorX: 0.2,
        scaleFactorY: 0.2
      })
    } else if (key === 'left' && !thang) {
      thang = createThang({
        pos: {
          x: this.stageBounds.topLeft.x - 2,
          y: this.stageBounds.bottomRight.y
        }
      })
    }

    const lank = new Lank(thangType, {
      resolutionFactor: 60,
      preloadSounds: false,
      thang,
      camera: this.camera,
      groundLayer: this.groundLayer
    })
    if (key === 'background') {
      this.layerAdapters['Background'].addLank(lank)
    } else {
      this.layerAdapters['Default'].addLank(lank)
    }
    this.lanks[key] = lank
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
