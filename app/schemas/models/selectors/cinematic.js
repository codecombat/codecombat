/**
 * Selector / verifier.
 *
 * Querying a nested data structure gets very repetitive.
 * This file contains selectors for various elements in the cinematic schema.
 *
 * Certain selectors can also throw an exception if correct data can't be returned.
 * This is useful when certain properties need to be returned together.
 * Otherwise if a selector can't be fulfilled we should return undefined.
 *
 * For example we may have an enum string that should return different properties
 * depending on how that enum has been set. This should throw an error if the shape
 * of the data is invalid.
 *
 * ## Examples
 *
 * If we ask for the left character and it's not there, return undefined.
 * If it's there and the enum type has been set to `slug`. This may indicate
 * that we return an object with a `slug`. Or maybe the enum type is `hero` and
 * no additional properties are required. In this case if the type is `slug` and no
 * slug is present, an exception should be thrown.
 *
 */

/**
 * Composes a list of functions.
 * The initial argument is passed into the first function and the result
 * is the passed along the array. The final result is returned.
 * @param  {...any} fns List of functions
 */
const compose = (...fns) => initial => fns.reduce((v, fn) => fn(v), initial)

/**
 * @typedef {Object} TypeThangTypeSlug
 * @param {string} slug
 */

/**
 * @typedef {Object} CharacterSchema
 * @property {string|TypeThangTypeSlug} type
 * @property {boolean} enterOnStart
 * @property {Point2d} position
 */

/**
 * @typedef {Object} ShotSetup - Shot setup object
 * @property {CharacterSchema} rightThangType
 * @property {CharacterSchema} leftThangType
 * @property {Object} camera
 */

/**
 * @typedef {Object} Point2d
 * @property {number} x
 * @property {number} y
 */

/**
 * @typedef {Object} Sound
 * @property {string} mp3
 * @property {string} ogg
 */
/**
 * @typedef {Object} DialogNode
 * @property {string} text - The text to display
 * @property {Point2d} textLocation - The point information
 */

/**
 * @typedef {Object} Shot - Cinematic shot data
 * @property {ShotSetup} shotSetup - The shotSetup object
 * @property {DialogNode[]} dialogNodes - The list of DialogNodes
 */

/**
 * @typedef {Object} Cinematic - Cinematic raw data type
 * @property {Shot[]} shots - The array of shots.
 */

const DEFAULT_THANGTYPE = () => ({
  scaleX: 1,
  scaleY: 1,
  pos: {
    x: 0,
    y: 0
  }
})

/**
 * @param {Object} thangDefaults
 * @returns {Function} sets thangDefaults on the thang property for a character.
 */
const setCharacterDefaults = ({ pos: { x, y }, scaleX, scaleY }) =>
  character => {
    if (!character) {
      return
    }

    const thang = character.thang || {}
    thang.pos = { ...{ x, y }, ...(thang.pos || {}) }
    thang.scaleX = thang.scaleX || scaleX
    thang.scaleY = thang.scaleY || scaleY
    character.thang = thang
    return character
  }

/**
 * @param {Object|undefined} leftCharacter The left character object
 * @param {Object} leftCharacter.thang The thang options for the left character.
 * @returns {Object|undefined} leftCharacter with default values set on thang.
 */
const setLeftCharacterDefaults = setCharacterDefaults({
  pos: { x: -30, y: -72 },
  scaleX: 1.2,
  scaleY: 1.2
})

/**
 * @param {Object|undefined} rightCharacter The left character object
 * @param {Object} rightCharacter.thang The thang options for the left character.
 * @returns {Object|undefined} rightCharacter with default values set on thang.
 */
const setRightCharacterDefaults = setCharacterDefaults({
  pos: { x: 30, y: -72 },
  scaleX: 1.2,
  scaleY: 1.2
})

/**
 * Takes the cinematic data that adheres to cinematic schema and returns
 * just the array of shots.
 * @param {Cinematic} cinematicData
 */
export const shots = cinematicData => (cinematicData || {}).shots

/**
 * @param {Shot} shot
 * @returns {undefined|ShotSetup} shotsetup
 */
export const shotSetup = shot => (shot || {}).shotSetup

/**
 * @param {ShotSetup} shotSetup
 * @returns {CharacterSchema|undefined}
 */
const leftCharacter = shotSetup => (shotSetup || {}).leftThangType

/**
 * @param {ShotSetup} shotSetup
 * @returns {CharacterSchema|undefined}
 */
const rightCharacter = shotSetup => (shotSetup || {}).rightThangType

/**
 * @param {ShotSetup} shotSetup
 * @returns {Object|undefined} background Object
 */
const backgroundArt = shotSetup => (shotSetup || {}).backgroundArt

/**
 * @param {ShotSetup} shotSetup
 * @returns {Object|undefined} heroPetThangType
 */
const heroPetThangType = shotSetup => (shotSetup || {}).heroPetThangType

/**
 * @param {Object} o Object that may have slug property
 * @returns {string|undefined}
 */
const slug = o => (o || {}).slug

/**
 * Returns a thang from a thangType if properties exist.
 * @param {Object} thangType that matches the ThangTypeSchema with a Character Slug
 * @returns {Object|undefined} returns thang if required properties exist.
 */
const extractThangTypeSchemaSlug = thangType => {
  if (!(thangType || {}).type) {
    return
  }
  if (!(thangType.type || {}).slug) {
    return
  }
  const { pos, scaleX, scaleY } = thangType
  const thang = { pos, scaleX, scaleY }
  const slug = thangType.type.slug
  return { thang, slug }
}

/**
 * Returns properties required to place a background Lank.
 * @param {Object} backgroundArt
 * @returns {Object|undefined} a background object
 */
const background = backgroundArt => {
  const thangData = extractThangTypeSchemaSlug(backgroundArt)
  if (!thangData) {
    return
  }
  const { slug, thang } = thangData

  return {
    slug,
    thang: _.merge(DEFAULT_THANGTYPE(), thang)
  }
}

/**
 * Returns properties required to place a hero pet Lank.
 * @param {Object} heroPetSchema
 * @returns {Object|undefined} a pet object with slug and thang
 */
const heroPet = heroPet => {
  const thangData = extractThangTypeSchemaSlug(heroPet)
  if (!thangData) {
    return
  }
  const { slug, thang } = thangData

  return {
    slug,
    thang: _.merge(DEFAULT_THANGTYPE(), thang)
  }
}

/**
 * @param {Object|undefined} thangType
 * @returns {Object|undefined} the thang and slug.
 */
const characterFromThangTypeSchema = thangType => {
  if (!(thangType || {}).type) {
    return
  }
  if (!(thangType.type || {}).slug) {
    return
  }
  const slug = thangType.type.slug
  const { scaleX, scaleY, pos } = thangType
  return {
    slug,
    thang: { scaleX, scaleY, pos }
  }
}

/**
 * Check if this is the hero type.
 * If so returns the properties associated.
 * The caller must get the thangType original using:
 * `me.get('heroConfig').thangType`
 * @param {Object|undefined} thangType
 * @returns {Object|undefined} thang data
 */
const getHeroFromThangTypeSchema = thangType => {
  if (!(thangType || {}).type) {
    return
  }
  if (typeof thangType.type !== 'string' || thangType.type !== 'hero') {
    return
  }

  const { scaleX, scaleY, pos } = thangType
  return {
    thang: { scaleX, scaleY, pos }
  }
}

/**
 * Returns exactly the data required to fulfill the information to place a character
 * onto the screen.
 * @param {CharacterSchema} character - the left or right character in CharacterSchema
 * @return {Object|undefined} with slug, enterOnStart, and thang properties object.
 */
const characterThangTypeSlug = character => {
  if (!character) {
    return
  }

  const thangType = characterFromThangTypeSchema((character || {}).thangType)
  if (!thangType) {
    return
  }

  const { slug, thang } = thangType

  const enterOnStart = character.enterOnStart || false

  return { slug, enterOnStart, thang }
}

/**
 * Returns exactly the data required to place a hero on the canvas.
 * Does not return the thangType original.
 * Get it with:
 * `me.get('heroConfig').thangType`
 * @param {CharacterSchema} character - the left or right hero
 * @returns {Object|undefined} The thangType original and position data.
 */
const heroThangTypeOriginal = character => {
  if (!character) {
    return
  }
  const thangType = getHeroFromThangTypeSchema((character || {}).thangType)
  if (!thangType) {
    return
  }
  const { thang } = thangType

  if (typeof character.enterOnStart !== 'boolean') {
    character.enterOnStart = false
  }
  const enterOnStart = character.enterOnStart

  return { enterOnStart, thang }
}

// A camera default setting.
export const CAMERA_DEFAULT = () => ({
  pos: {
    x: 0,
    y: 0
  },
  zoom: 1
})

/**
 * @param {ShotStup} shotSetup
 * @returns {Object|undefined} camera properties with sensible defaults.
 */
const camera = shotSetup => {
  if (!(shotSetup || {}).camera) {
    return
  }
  return _.merge(CAMERA_DEFAULT(), shotSetup.camera)
}

/**
 * Returns the left character if it's a thangType slug.
 * @param {Shot} shot
 * @returns {Object|undefined} thangType slug, position data and whether to animate in the thang.
 */
export const getLeftCharacterThangTypeSlug = compose(shotSetup, leftCharacter, characterThangTypeSlug, setLeftCharacterDefaults)

/**
 * Returns the right character if it's a thangType slug.
 * @param {Shot} shot
 * @returns {Object|undefined} thangType slug, position data and whether to animate in the thang.
 */
export const getRightCharacterThangTypeSlug = compose(shotSetup, rightCharacter, characterThangTypeSlug, setRightCharacterDefaults)

/**
 * @param {DialogNode} dialogNode
 * @returns {bool} whether we should clear all existing dialogs. Defaults to true.
 */
export const getClearText = dialogNode => {
  const shouldClearDialogue = (dialogNode || {}).dialogClear
  if (typeof shouldClearDialogue === 'undefined') {
    return true
  }
  return shouldClearDialogue
}

export const getTextPosition = dialogNode => (dialogNode || {}).textLocation

export const getSpeaker = dialogNode => (dialogNode || {}).speaker || 'left'

export const getText = dialogNode => (dialogNode || {}).text

/**
 * @param {DialogNode} dialogNode
 * @returns  {'left'|'right'|'both'|undefined}
 */
export const getExitCharacter = dialogNode => (dialogNode || {}).exitCharacter

/**
 * @param {DialogNode} dialogNode
 * @returns {Object|undefined} triggers
 */
export const triggers = dialogNode => (dialogNode || {}).triggers

const backgroundObject = triggers => {
  const bgObject = (triggers || {}).backgroundObject
  if (!(bgObject || {}).thangType) {
    return
  }

  return _.merge(DEFAULT_THANGTYPE(), bgObject.thangType)
}

/**
 * @param {Object} triggers
 * @returns {number|undefined} number of ms before background object appears
 */
const backgroundObjectDelay = triggers => {
  const bgObject = (triggers || {}).backgroundObject
  if (!bgObject) {
    return
  }
  return bgObject.triggerStart || 0
}

/**
 * @param {DialogNode} dialogNode
 * @returns {number|undefined}
 */
const textAnimationLength = dialogNode => (dialogNode || {}).textAnimationLength

/**
 * @param {ShotSetup} shotSetup
 * @returns {Sound} possibly contains `mp3` or `ogg` property.
 */
const setupMusic = shotSetup => {
  if (!(shotSetup || {}).music) {
    return
  }
  return shotSetup.music
}

/**
 * @param {Object} triggers
 * @returns {undefined|number} Delay if it exists.
 */
const clearBackgroundObject = triggers => {
  if (!triggers) {
    return
  }
  return (triggers.clearBackgroundObject || {}).triggerStart
}

/**
 * @typedef {Object} SoundEffect
 * @property {number} triggerStart
 * @property {Sound} sound
 */

/**
 * @param {Object} triggers
 * @returns {SoundEffect[]|undefined}
 */
const soundEffects = triggers => {
  if (!(triggers || {}).soundFxTriggers) {
    return
  }
  const { soundFxTriggers } = triggers
  if (!Array.isArray(soundFxTriggers)) {
    console.warn(`Ensure 'triggers.soundFxTriggers' is an array. Got a ${typeof soundFxTriggers}`)
    return
  }
  return soundFxTriggers
    .map(sound => {
      sound.triggerStart = sound.triggerStart || 0
      return sound
    })
}

/**
 * Returns if left hero character
 * @param {Shot} shot
 * @returns {bool}
 */
export const getLeftHero = compose(shotSetup, leftCharacter, heroThangTypeOriginal, setLeftCharacterDefaults)

/**
 * Returns the right hero character
 * @param {Shot} shot
 * @returns {bool}
 */
export const getRightHero = compose(shotSetup, rightCharacter, heroThangTypeOriginal, setRightCharacterDefaults)

/**
 * Returns the background
 * @param {Shot} shot
 * @returns {Object|undefined}
 */
export const getBackground = compose(shotSetup, backgroundArt, background)

/**
 * Return the background slug.
 * @param {Shot} shot
 * @returns {string|undefined}
 */
export const getBackgroundSlug = compose(shotSetup, backgroundArt, background, slug)

/**
 * Get hero pet thang
 * @param {Shot} shot
 * @returns {Object|undefined}
 */
export const getHeroPet = compose(shotSetup, heroPetThangType, heroPet)

/**
 * @param {DialogNode} dialogNode
 * @returns {Object|undefined} backgroundObject
 */
export const getBackgroundObject = compose(triggers, backgroundObject)

/**
 * @param {DialogNode} dialogNode
 * @returns {number|undefined} delay
 */
export const getBackgroundObjectDelay = compose(triggers, backgroundObjectDelay)

/**
 * @param {DialogNode} dialogNode
 * @returns {number|undefined} the delay before removing the background object.
 */
export const getClearBackgroundObject = compose(triggers, clearBackgroundObject)

/**
 * @param {Shot} shot
 * @returns {Object} Always returns a camera
 */
export const getCamera = compose(shotSetup, camera)

/**
 * @param {DialogNode} dialogNode
 * @returns {number} defaults return of 1000
 */
export const getTextAnimationLength = textAnimationLength

/**
 * @param {DialogNode}  dialogNode
 * @returns {string|undefined} Lank action to play
 */
export const getSpeakingAnimationAction = dialogNode => (dialogNode || {}).speakingAnimationAction

/**
 * @returns {string|undefined}
 */
export const getSetupMusic = compose(shotSetup, setupMusic)

/**
 * @param {DialogNode} dialogNode
 * @returns {SoundEffect[] | undefined}
 */
export const getSoundEffects = compose(triggers, soundEffects)

/**
 * @param {DialogNode} dialogNode
 * @returns {bool}
 */
export const getWaitUserInput = dialogNode => {
  const waitUserInput = (dialogNode || {}).waitUserInput
  if (typeof waitUserInput === 'boolean') {
    return waitUserInput
  }
  return true
}

/**
 * @param {DialogNode} dialogNode
 * @returns {string|undefined}
 */
export const getLanguageFilter = dialogNode => (dialogNode || {}).programmingLanguageFilter
