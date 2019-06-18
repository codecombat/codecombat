import anime from 'animejs/lib/anime.es.js'
import AbstractCommand from './commands/AbstractCommand'
import { SyncFunction, Sleep, SequentialCommands } from './commands/commands'
import {
  getLeftCharacterThangTypeSlug,
  getRightCharacterThangTypeSlug,
  getLeftHero,
  getRightHero,
  getBackground,
  getExitCharacter,
  getBackgroundObject,
  getBackgroundObjectDelay,
  getClearBackgroundObject,
  getText,
  getTextAnimationLength,
  getSpeakingAnimationAction,
  getSpeaker
} from '../../../app/schemas/models/selectors/cinematic'
import { LETTER_ANIMATE_TIME } from './constants'

export const HERO_THANG_ID = '55527eb0b8abf4ba1fe9a107'
const OFF_CAMERA_OFFSET = 20

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
 * @typedef {import(./commands/CinematicParser).System} System
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
    this.loader = loader
    this.lanks = {}
  }

  get stageBounds () {
    return {
      topLeft: this.camera.canvasToWorld({ x: 0, y: 0 }),
      bottomRight: this.camera.canvasToWorld({ x: this.camera.canvasWidth, y: this.camera.canvasHeight })
    }
  }

  /**
   * Returns a list of commands that correctly set up the shot.
   * @param {Shot} shot - the cinematic shot data.
   */
  parseSetupShot (shot) {
    const commands = []

    const addMoveCharacterCommand = (side, resource, enterOnStart, thang) => {
      if (enterOnStart) {
        commands.push(this.moveLankCommand({ key: side, resource, thang, ms: 1000 }))
      } else {
        commands.push(this.moveLankCommand({ key: side, resource, thang, ms: 0 }))
      }
    }

    const background = getBackground(shot)
    if (background) {
      commands.push(this.setBackgroundCommand(background))
    }

    const lHero = getLeftHero(shot)
    const original = (me.get('heroConfig') || {}).thangType || HERO_THANG_ID
    if (lHero) {
      const { enterOnStart, thang } = lHero
      addMoveCharacterCommand('left', original, enterOnStart, thang)
    }

    const rHero = getRightHero(shot)
    if (rHero) {
      const { enterOnStart, thang } = rHero
      addMoveCharacterCommand('right', original, enterOnStart, thang)
    }

    const leftCharSlug = getLeftCharacterThangTypeSlug(shot)
    if (leftCharSlug) {
      const { slug, enterOnStart, thang } = leftCharSlug
      addMoveCharacterCommand('left', slug, enterOnStart, thang)
    }

    const rightCharSlug = getRightCharacterThangTypeSlug(shot)
    if (rightCharSlug) {
      const { slug, enterOnStart, thang } = rightCharSlug
      addMoveCharacterCommand('right', slug, enterOnStart, thang)
    }

    return commands
  }

  parseDialogNode (dialogNode) {
    const commands = []

    // TODO: Do we need to give the designers more access to where the characters should exit?
    //       Currently characters start 8 meters off the respective side of the camera bounds.
    const char = getExitCharacter(dialogNode)
    if (char === 'left' || char === 'both') {
      commands.push(this.moveLankCommand({
        key: 'left',
        thang: {
          pos: {
            x: this.stageBounds.topLeft.x - OFF_CAMERA_OFFSET
          }
        },
        ms: 800 }))
    }

    if (char === 'right' || char === 'both') {
      commands.push(this.moveLankCommand({
        key: 'right',
        thang: {
          pos: {
            x: this.stageBounds.bottomRight.x + OFF_CAMERA_OFFSET
          }
        },
        ms: 800 }))
    }

    const bgObject = getBackgroundObject(dialogNode)
    if (bgObject) {
      const { scaleX, scaleY, pos: { x, y }, type: { slug } } = bgObject
      const thangOptions = {
        scaleX,
        scaleY,
        pos: { x, y },
        stateChanged: true
      }
      const delay = getBackgroundObjectDelay(dialogNode)

      commands.push(new SequentialCommands([
        new Sleep(delay),
        this.moveLankCommand({
          key: BACKGROUND_OBJECT,
          resource: slug,
          thang: thangOptions,
          ms: 0
        })
      ]))
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
      let textLength = getTextAnimationLength(dialogNode)
      if (textLength === undefined) {
        textLength = text.length * LETTER_ANIMATE_TIME
      }
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
   * You must provide either a key for an existing lank, or a key and resource
   * to create a new lank with the given key.
   * @param {Object} options
   * @param {string} options.key The key of the lank
   * @param {string} options.resource The slug or originalId of the thangType
   * @param {Object} options.thang  Thang object properties
   * @param {Object} options.ms Time to move lank to position.
   */
  moveLankCommand ({
    key,
    resource,
    thang: {
      scaleX = 1,
      scaleY = 1,
      pos: { x, y } = {}
    } = {},
    ms = 1000
  }) {
    const thang = { scaleX, scaleY, pos: { x, y } }
    const pos = { x, y } || {}

    if (ms === 0) {
      return new SyncFunction(() => {
        if (resource) {
          this.addLank(key, this.loader.getThangType(resource), thang)
        }

        _.merge(this.lanks[key].thang, {
          pos: thang.pos,
          scaleFactorX: thang.scaleX,
          scaleFactorY: thang.scaleY,
          stateChanged: true
        })
        this.lanks[key].updateScale()
      })
    }

    return new MoveLank(() => {
      if (resource) {
        this.addLank(key, this.loader.getThangType(resource), thang)
      }
      if (!this.lanks[key]) {
        throw new Error('You are using a lank that hasn\'t been created yet, in setup!')
      }
      // normalize parameters
      pos.x = pos.x !== undefined ? pos.x : this.lanks[key].thang.pos.x
      pos.y = pos.y !== undefined ? pos.y : this.lanks[key].thang.pos.y
      if (this.lanks[key].thang.pos.x === pos.x && this.lanks[key].thang.pos.y === pos.y) {
        console.warn('Are you accidentally not moving the Lank?')
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
        // Inform update engine to render thang at new position.
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
   * Handles backgrounds that may already exist or are simply being moved.
   * @param {Object} backgroundInfo
   * @param {string} backgroundInfo.slug Background object slug
   * @param {Object} backgroundInfo.thang The thang object for the background. Contains scale and position information.
   */
  setBackgroundCommand ({ slug, thang }) {
    return this.moveLankCommand({
      key: BACKGROUND,
      resource: slug,
      thang,
      ms: 0
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

  cleanup () {
    for (const key in this.lanks) {
      this.removeLank(key)
    }
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
  addLank (key, thangType, thang = {}) {
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
    if (key === 'right') {
      thang = createThang({
        pos: {
          x: this.stageBounds.bottomRight.x + OFF_CAMERA_OFFSET,
          y: (thang.pos || {}).y || this.stageBounds.bottomRight.y
        },
        rotation: RIGHT,
        scaleFactorX: thang.scaleX || 1,
        scaleFactorY: thang.scaleY || 1
      })
    } else if (key === 'left') {
      thang = createThang({
        pos: {
          x: this.stageBounds.topLeft.x - OFF_CAMERA_OFFSET,
          y: (thang.pos || {}).y || this.stageBounds.bottomRight.y
        },
        scaleFactorX: thang.scaleX || 1,
        scaleFactorY: thang.scaleY || 1
      })
    }

    const lank = new Lank(thangType, {
      resolutionFactor: 60,
      preloadSounds: false,
      thang,
      camera: this.camera,
      groundLayer: this.groundLayer,
      isCinematic: true
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
    scaleFactorX: 1,
    scaleFactorY: 1,
    action: 'idle',
    //  Looking left
    rotation: 0
  }
  return _.cloneDeep(_.merge(defaults, thang))
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
