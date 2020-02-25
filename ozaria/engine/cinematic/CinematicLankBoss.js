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
  getSpeaker,
  getHeroPet,
  getChangeDefaultIdles
} from '../../../app/schemas/models/selectors/cinematic'
import { LETTER_ANIMATE_TIME, HERO_THANG_ID, AVATAR_THANG_ID, PET_AVATAR_THANG_ID } from './constants'

const store = require('core/store')

const OFF_CAMERA_OFFSET = 20

// Throws an error if `import ... from ..` syntax.
const Promise = require('bluebird')
const Lank = require('lib/surface/Lank')

Promise.config({
  cancellation: true
})

// Key constants for special lank types
const LEFT_LANK_KEY = 'left'
const RIGHT_LANK_KEY = 'right'
const HERO_PET = 'HERO_PET'
const BACKGROUND_OBJECT = 'BACKGROUND_OBJECT'
const BACKGROUND = 'BACKGROUND'

// Backgrounds
const DEFAULT_LAYER = 'Default'
const BACKGROUND_LAYER = 'Background'
const BACKGROUND_OBJECT_LAYER = 'Background Object'

// Lank to Background mapping. If not set, will default to 'Default' layer.
const lankLayer = new Map([
  [ BACKGROUND, BACKGROUND_LAYER ],
  [ BACKGROUND_OBJECT, BACKGROUND_OBJECT_LAYER ],
  [ HERO_PET, BACKGROUND_OBJECT_LAYER ]
])

// Thang rotation constants
const RIGHT = Math.PI
const LEFT = 0

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
  constructor ({ groundLayer, layerAdapter, backgroundObjectAdapter, backgroundAdapter, camera, loader }) {
    this.groundLayer = groundLayer
    this.lankCache = {}
    this.layerAdapters = {
      [DEFAULT_LAYER]: layerAdapter,
      [BACKGROUND_LAYER]: backgroundAdapter,
      [BACKGROUND_OBJECT_LAYER]: backgroundObjectAdapter
    }

    // Layers are preloaded if nothing has been added to them.
    this.preLoadedLayers = {
      [DEFAULT_LAYER]: true,
      [BACKGROUND_LAYER]: true,
      [BACKGROUND_OBJECT_LAYER]: true
    }

    this.camera = camera
    this.loader = loader
    this.lanks = {}

    // Data that should only be mutated by commands at runtime.
    this.runTimeState = {
      idleAnimation: {
        [LEFT_LANK_KEY]: 'idle',
        [RIGHT_LANK_KEY]: 'idle'
      }
    }
  }

  get stageBounds () {
    return {
      topLeft: this.camera.canvasToWorld({ x: 0, y: 0 }),
      bottomRight: this.camera.canvasToWorld({ x: this.camera.canvasWidth, y: this.camera.canvasHeight })
    }
  }

  /**
   * This method is used to preload and pre-rasterize lanks.
   * This is achieved by adding lanks to the layers and then saving the rendered lank
   * for use later.
   * Then when the cinematic uses the lank, it is retrieved from the cache pool
   * and shown. When the cinematic removes the lank, it is hidden and returned to
   * the cache.
   * In doing so we no longer need to rasterize during the playback of a cinematic.
   */
  preRasterLank (resource, thang, layer) {
    const thangType = this.loader.getThangType(resource)
    if (this.lankCache[thangType.id]) {
      return
    }
    const lank = new Lank(thangType, {
      preloadSounds: false,
      thang: thang || {
        pos: {
          x: 0,
          y: 0
        }
      },
      camera: this.camera,
      groundLayer: this.groundLayer,
      isCinematic: true
    })
    this.layerAdapters[layer || DEFAULT_LAYER].addLank(lank)
    this.lankCache[lank.thangType.id] = lank
    if (this.preLoadedLayers[layer || DEFAULT_LAYER] === true) {
      this.preLoadedLayers[layer || DEFAULT_LAYER] = new Promise((resolve, reject) => {
        const unblockTimeout = setTimeout(() => {
          console.error('Cinematic hit render timelimit of 40 seconds')
          resolve()
        }, 40000)
        this.layerAdapters[layer || DEFAULT_LAYER].once('new-spritesheet', () => {
          clearTimeout(unblockTimeout)
          resolve()
        })
      })
    }
  }

  // This method waits for all layers to be preloaded.
  preloaded () {
    const layerLoadPromises = [...Object.values(this.preLoadedLayers)].map(b => b === true ? Promise.resolve() : b)
    let barLengthAlreadyLoaded = 66 // loaded in cinematic loader during network loading
    const layerLoadAmt = 34 / layerLoadPromises.length
    layerLoadPromises.forEach((p) => {
      p.then(() => {
        barLengthAlreadyLoaded += layerLoadAmt
        const bar = $('.progress-bar.progress-bar-success')
        if (bar) {
          bar.css('width', `${Math.min(barLengthAlreadyLoaded, 100)}%`)
        }
      })
    })
    return Promise.all(layerLoadPromises)
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
      this.preRasterLank(background.slug, background.thang, BACKGROUND_LAYER)
    }

    const lHero = getLeftHero(shot)
    const rHero = getRightHero(shot)

    const original = (me.get('ozariaUserOptions') || {}).cinematicThangTypeOriginal || HERO_THANG_ID
    const avatar = (store.getters['me/get1fhAvatar'] || {}).cinematicThangTypeId || AVATAR_THANG_ID
    const avatarPet = (store.getters['me/get1fhAvatar'] || {}).cinematicPetThangId || PET_AVATAR_THANG_ID

    const heroPet = getHeroPet(shot)
    if (heroPet) {
      const { slug, thang } = heroPet
      thang.rotation = RIGHT
      this.heroPetOffset = thang.pos
      const placePet = this.moveLankCommand({
        key: HERO_PET,
        resource: (rHero || {}).type !== 'avatar' ? slug : avatarPet,
        thang,
        ms: 0
      })
      this.preRasterLank((rHero || {}).type !== 'avatar' ? slug : avatarPet, thang, lankLayer[HERO_PET])
      commands.push(placePet)
    }

    if (lHero) {
      const { enterOnStart, thang, type } = lHero
      addMoveCharacterCommand(LEFT_LANK_KEY, type === 'hero' ? original : avatar, enterOnStart, thang)
      this.preRasterLank(type === 'hero' ? original : avatar)
    }

    if (rHero) {
      const { enterOnStart, thang, type } = rHero
      addMoveCharacterCommand(RIGHT_LANK_KEY, type === 'hero' ? original : avatar, enterOnStart, thang)
      this.preRasterLank(type === 'hero' ? original : avatar)
    }

    const leftCharSlug = getLeftCharacterThangTypeSlug(shot)
    if (leftCharSlug) {
      const { slug, enterOnStart, thang } = leftCharSlug
      addMoveCharacterCommand(LEFT_LANK_KEY, slug, enterOnStart, thang)
      this.preRasterLank(slug, thang)
    }

    const rightCharSlug = getRightCharacterThangTypeSlug(shot)
    if (rightCharSlug) {
      // Remove the hero pet if not a hero being added to the right.
      commands.push(new SyncFunction(() => this.removeLank(HERO_PET)))
      const { slug, enterOnStart, thang } = rightCharSlug
      addMoveCharacterCommand(RIGHT_LANK_KEY, slug, enterOnStart, thang)
      this.preRasterLank(slug, thang)
    }

    return commands
  }

  parseDialogNode (dialogNode) {
    const commands = []

    // TODO: Do we need to give the designers more access to where the characters should exit?
    //       Currently characters start 8 meters off the respective side of the camera bounds.
    const char = getExitCharacter(dialogNode)
    if (char === LEFT_LANK_KEY || char === 'both') {
      commands.push(new SequentialCommands([
        this.moveLankCommand({
          key: LEFT_LANK_KEY,
          thang: {
            pos: {
              x: this.stageBounds.topLeft.x - OFF_CAMERA_OFFSET
            }
          },
          ms: 800
        }),
        new SyncFunction(() => {
          if (this.lanks[LEFT_LANK_KEY]) {
            this.removeLank(LEFT_LANK_KEY)
          }
        })
      ]))
    }

    if (char === RIGHT_LANK_KEY || char === 'both') {
      commands.push(new SequentialCommands([
        this.moveLankCommand({
          key: RIGHT_LANK_KEY,
          thang: {
            pos: {
              x: this.stageBounds.bottomRight.x + OFF_CAMERA_OFFSET
            }
          },
          ms: 800
        }),
        new SyncFunction(() => {
          if (this.lanks[RIGHT_LANK_KEY]) {
            this.removeLank(RIGHT_LANK_KEY)
          }
        })
      ]))
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
      this.preRasterLank(slug, thangOptions, lankLayer[BACKGROUND_OBJECT])
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
    for (const cachedLank of Object.values(this.lankCache)) {
      if ([...Object.keys(cachedLank.thangType.getActions())].indexOf(animation) !== -1) {
        cachedLank.queueAction(animation)
      }
    }
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
          this.playActionOnLank(speaker, this.runTimeState.idleAnimation[speaker] || 'idle')
        })
      ]))
    }

    getChangeDefaultIdles(dialogNode).forEach(({ character, newIdleAction }) => {
      if (!character || !newIdleAction) {
        console.warn(`Can't set new idle action for '${character}' to '${newIdleAction}'`)
      }

      commands.push(new SyncFunction(() => { this.runTimeState.idleAnimation[character] = newIdleAction }))
    })

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

    // Without these locks the actions are changed due to sprite sheet rendering.
    lank.lockAction(false)
    lank.queueAction(action)
    lank.lockAction(true)
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
    thang,
    thang: {
      pos
    } = {},
    ms = 1000
  }) {
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
    this.updateHeroPetPosition()
    Object.values(this.lanks)
      .forEach(lank => lank.update(frameChanged))
  }

  /**
   * Custom update method that pins the hero pet to the right
   * character if it exists, by updating the hero pet thang.
   */
  updateHeroPetPosition () {
    if (this.lanks[HERO_PET] && !this.lanks[RIGHT_LANK_KEY]) {
      this.removeLank(HERO_PET)
    }

    if (!(this.lanks[HERO_PET] && this.lanks[RIGHT_LANK_KEY])) {
      return
    }

    const petThang = this.lanks[HERO_PET].thang
    const rightThang = this.lanks[RIGHT_LANK_KEY].thang
    if (!rightThang.stateChanged) {
      return
    }

    petThang.stateChanged = true
    petThang.pos = _.clone(rightThang.pos)
    petThang.pos.x += this.heroPetOffset.x
    petThang.pos.y += this.heroPetOffset.y
  }

  /**
   * Removes and cleans up resources for the provided lank.
   * @param {string} key unique key for given lank.
   */
  removeLank (key) {
    const lank = this.lanks[key]
    if (!lank) { return }
    this.lankCache[lank.thangType.id] = lank
    lank.hide()
    delete this.lanks[key]
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
    let lank = null
    let useCache = false
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

    // Use a cached lank
    if (this.lankCache[thangType.id]) {
      lank = this.lankCache[thangType.id]
      useCache = true
    }

    // Initial coordinates for thangs being created offscreen.
    // This feels like it could be refactored to be nicer.
    if (key === RIGHT_LANK_KEY) {
      thang = createThang({
        pos: {
          x: this.stageBounds.bottomRight.x + OFF_CAMERA_OFFSET,
          y: (thang.pos || {}).y || this.stageBounds.bottomRight.y
        },
        rotation: RIGHT,
        scaleFactorX: thang.scaleX || 1,
        scaleFactorY: thang.scaleY || 1,
        action: this.runTimeState.idleAnimation[key] || 'idle'
      })
    } else if (key === LEFT_LANK_KEY) {
      thang = createThang({
        pos: {
          x: this.stageBounds.topLeft.x - OFF_CAMERA_OFFSET,
          y: (thang.pos || {}).y || this.stageBounds.bottomRight.y
        },
        scaleFactorX: thang.scaleX || 1,
        scaleFactorY: thang.scaleY || 1,
        action: this.runTimeState.idleAnimation[key] || 'idle'
      })
    } else if (key === HERO_PET) {
      // Hack to ensure pet renders off screen
      // TODO: Remove when we have a way to make lanks invisible.
      thang.pos = {
        x: this.stageBounds.bottomRight.x * 10,
        y: this.stageBounds.bottomRight.y * 10
      }
    }

    lank = lank || new Lank(thangType, {
      preloadSounds: false,
      thang,
      camera: this.camera,
      groundLayer: this.groundLayer,
      isCinematic: true
    })
    lank.setThang(thang)
    lank.show()
    if (!useCache) {
      const layer = lankLayer.get(key) || DEFAULT_LAYER
      this.layerAdapters[layer].addLank(lank)
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
export const createThang = thang => {
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
    rotation: LEFT,
    // This method is required by the Lank to support customization
    getLankOptions: function () {
      // TODO: Make this only applied to hero character instead of anything customizable.
      const options = { colorConfig: {} }
      const playerTints = (me.get('ozariaUserOptions') || {}).tints || []
      playerTints.forEach(tint => {
        const colorGroups = (tint.colorGroups || {})
        options.colorConfig = _.merge(options.colorConfig, colorGroups)
      })
      return options
    }
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
