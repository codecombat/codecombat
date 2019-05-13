import anime from 'animejs/lib/anime.es.js'
import AbstractCommand from './Command/AbstractCommand'
import { Noop, SyncFunction, Sleep, SequentialCommands } from './Command/commands'
import {
  getLeftCharacterThangTypeSlug,
  getRightCharacterThangTypeSlug,
  getLeftHero,
  getRightHero,
  getBackground,
  getExitCharacter,
  getBackgroundObject,
  getClearBackgroundObject,
  getText,
  getTextAnimationLength,
  getSpeakingAnimationAction,
  getSpeaker
} from '../../../schemas/selectors/cinematic'

// Throws an error if `import ... from ..` syntax.
const Promise = require('bluebird')
const Lank = require('lib/surface/Lank')

Promise.config({
  cancellation: true
})

const BACKGROUND_OBJECT = 'backgroundObject'
const BACKGROUND = 'background'
const RIGHT = Math.PI

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
        commands.push(this.moveLankCommand({ key: side, resource, pos }))
      } else {
        commands.push(this.moveLank({ key: side, resource, pos }))
      }
    }

    const background = getBackground(shot)
    if (background) {
      commands.push(this.setBackgroundCommand(background))
    }

    const lHero = getLeftHero(shot)
    const original = me.get('heroConfig').thangType
    if (lHero) {
      const { enterOnStart, thang: { pos } } = lHero
      moveCharacter('left', original, enterOnStart, pos)
    }

    const rHero = getRightHero(shot)
    if (rHero) {
      const { enterOnStart, thang: { pos } } = rHero
      moveCharacter('right', original, enterOnStart, pos)
    }

    const leftCharSlug = getLeftCharacterThangTypeSlug(shot)
    if (leftCharSlug) {
      const { slug, enterOnStart, thang: { pos } } = leftCharSlug
      moveCharacter('left', slug, enterOnStart, pos)
    }

    const rightCharSlug = getRightCharacterThangTypeSlug(shot)
    if (rightCharSlug) {
      const { slug, enterOnStart, thang: { pos } } = rightCharSlug
      moveCharacter('right', slug, enterOnStart, pos)
    }

    return commands
  }

  parseDialogNode (dialogNode) {
    const commands = []

    // TODO: Do we need to give the designers more access to where the characters should exit?
    //       Currently characters start 4 meters off the respective side of the camera bounds.
    const char = getExitCharacter(dialogNode)
    if (char === 'left' || char === 'both') {
      commands.push(this.moveLankCommand({ key: 'left', pos: { x: this.stageBounds.topLeft.x - 4 } }))
    }

    if (char === 'right' || char === 'both') {
      commands.push(this.moveLankCommand({ key: 'right', pos: { x: this.stageBounds.bottomRight.x + 4 } }))
    }

    const bgObject = getBackgroundObject(dialogNode)
    if (bgObject) {
      const { scaleX, scaleY, pos: { x, y }, type: { slug } } = bgObject
      const thangOptions = {
        scaleFactorX: scaleX,
        scaleFactorY: scaleY,
        pos: { x, y },
        stateChanged: true
      }
      commands.push(this.moveLank({ key: BACKGROUND_OBJECT, resource: slug, pos: { x, y }, thang: createThang(thangOptions) }))
    }

    const removeBgDelay = getClearBackgroundObject(dialogNode)
    if (typeof removeBgDelay === 'number') {
      commands.push(new SequentialCommands([
        new Sleep(removeBgDelay),
        new SyncFunction(() => {
          this.removeLank(BACKGROUND_OBJECT)
        })
      ]))
    }

    const text = getText(dialogNode)
    const animation = getSpeakingAnimationAction(dialogNode)
    if (text && animation) {
      const textLength = getTextAnimationLength(dialogNode)
      const speaker = getSpeaker(dialogNode)
      commands.push(new SequentialCommands([
        // TODO: Is a minimum time of 100 required to ensure animation always plays?
        new Sleep(Math.min(100, textLength)),
        new SyncFunction(() => {
          this.playActionOnLank(speaker, animation)
        })
      ]))

      commands.push(new SequentialCommands([
        new Sleep(textLength),
        new SyncFunction(() => {
          this.playActionOnLank(speaker, 'idle')
        })
      ]))
    }
    return commands
  }

  /**
   * Moves either the left or right lank to a given co-ordinates **instantly**.
   *
   * TODO: Refactor into the moveLankCommand method. Make it handle a delay of 0ms.
   * @param {'left'|'right'} side - the lank being moved.
   * @param {{x, y}} pos - the position in meters to move towards.
   */
  moveLank ({ key, resource, pos = {}, thang }) {
    return new SyncFunction(() => {
      this.addLank(key, this.loader.getThangType(resource), thang)

      // normalize parameters
      this.lanks[key].thang.pos.x = pos.x !== undefined ? pos.x : this.lanks[key].thang.pos.x
      this.lanks[key].thang.pos.y = pos.y !== undefined ? pos.y : this.lanks[key].thang.pos.y

      // Ensures lank is rendered.
      this.lanks[key].thang.stateChanged = true
    })
  }

  /**
   * Plays an action on a lank. If you want an animation to loop, and it isn't,
   * you need to make the action loop on the ThangType.
   * @param {string} key The lanks unique key
   * @param {string} action The action to queue onto the lank
   * @return {undefined}
   */
  playActionOnLank (key, action) {
    const lank = this.lanks[key]
    if (!lank) {
      console.warn(`Tried to play action '${action}' on non existant lank '${key}'`)
      return
    }
    lank.queueAction(action)
  }

  /**
   * Returns a command that will move the lank.
   * @param {string} key
   * @param {{x, y}} pos
   * @param {number} ms
   */
  moveLankCommand ({ key, resource, pos, ms = 1000, thang }) {
    return new MoveLank(() => {
      if (resource) {
        this.addLank(key, this.loader.getThangType(resource))
      }
      pos = pos || {}
      // normalize parameters
      pos.x = pos.x !== undefined ? pos.x : this.lanks[key].thang.pos.x
      pos.y = pos.y !== undefined ? pos.y : this.lanks[key].thang.pos.y
      if (this.lanks[key].thang.pos.x === pos.x && this.lanks[key].thang.pos.y === pos.y) {
        return new Noop()
      }
      const lankStateChanged = () => { this.lanks[key].thang.stateChanged = true }
      const animation = anime({
        targets: this.lanks[key].thang.pos,
        x: pos.x,
        y: pos.y,
        duration: ms,
        autoplay: false,
        delay: 500, // Hack to provide some time for lank to load.
        easing: 'easeInOutQuart',
        // Inform update engine to rerender thang at new position.
        update: lankStateChanged,
        complete: lankStateChanged
      })

      return {
        lankStateChanged,
        animation,
        run: () => new Promise((resolve, reject) => {
          animation.play()
          animation.complete = resolve
        })
      }
    })
  }

  /**
   * Sets the background.
   *
   * Handles backgrounds that may already exist or are simply being moved.
   * TODO: Refactor and fold into the moveLankCommand method. Make it handle delay of 0ms.
   *       This method is a special case of the moveLank method.
   * @param {Object} background Background object.
   */
  setBackgroundCommand ({ slug, thang: { scaleX, scaleY, pos: { x, y } } }) {
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

      // If this background is already in use, just update thang instead of
      // completely replacing the lank.
      if (this.lanks[BACKGROUND] && this.lanks[BACKGROUND].thangType) {
        if (this.lanks[BACKGROUND].thangType.get('slug') === slug) {
          const thang = this.lanks[BACKGROUND].thang
          _.merge(thang, thangOptions)
          return
        }
      }

      const backgroundThang = createThang(thangOptions)
      this.addLank(BACKGROUND, thangType, backgroundThang)
    })
  }

  /**
   * Updates lanks
   * @param {bool} frameChanged - Needs to be true for Lank updates to occur.
   */
  update (frameChanged) {
    Object.values(this.lanks)
      .forEach(lank => lank.update(frameChanged))
  }

  /**
   * Removes and cleans up resources for the provided lank.
   * @param {string} key unique key for given lank.
   */
  removeLank (key) {
    const lank = this.lanks[key]
    if (!lank) { return }
    lank.layer.removeLank(lank)
    delete this.lanks[key]
    lank.destroy()
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
    // Handle a duplicate thangType with the same key.
    if (this.lanks[key] && this.lanks[key].thangType) {
      const original = this.lanks[key].thangType.get('original')
      if (thangType.get('original') === original) {
        // It's the same thangType. Don't add a new Lank.
        return
      } else {
        // It's a lank we want to replace.
        this.removeLank(key)
      }
    }

    // Initial coordinates for thangs being created offscreen.
    // This feels like it could be refactored to be nicer.
    if (key === 'right' && !thang) {
      thang = createThang({
        pos: {
          x: this.stageBounds.bottomRight.x + 4,
          y: this.stageBounds.bottomRight.y
        },
        rotation: RIGHT
      })
    } else if (key === 'left' && !thang) {
      thang = createThang({
        pos: {
          x: this.stageBounds.topLeft.x - 4,
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
    if (key === BACKGROUND) {
      this.layerAdapters['Background'].addLank(lank)
    } else {
      this.layerAdapters['Default'].addLank(lank)
    }
    this.lanks[key] = lank
  }
}

/**
 * Creates a mock thang. Looking left by default.
 * You can pass in a thang to override default thang properties.
 *
 * @param {Object} thang - is merged onto default thang settings.
 * @returns {Object} thang object literal
 */
const createThang = thang => {
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
  return _.merge(defaults, thang)
}

/**
 * A modified AnimeCommand that updates thang state ensuring lanks are correctly rendered.
 */
class MoveLank extends AbstractCommand {
  /**
   * @param {Function} animationFn Function that returns a run function, animation tween
   *                               and a function to update the state of the lank.
   */
  constructor (animationFn) {
    super()
    this.animationFn = animationFn
  }

  run () {
    const { run, animation, lankStateChanged } = this.animationFn()
    this.animation = animation
    this.lankStateChanged = lankStateChanged
    return run()
  }

  cancel (promise) {
    const animation = this.animation
    if (!animation) {
      throw new Error('Incorrect use of MoveLank. Must attach animation.')
    }
    animation.seek(animation.duration)
    this.lankStateChanged()
    return promise
  }
}
