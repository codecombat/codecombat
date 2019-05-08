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
 * @property {string} cameraType - The camera type enum
 * @property {CharacterSchema} rightThangType
 * @property {CharacterSchema} leftThangType
 */

/**
 * @typedef {Object} Point2d
 * @property {number} x
 * @property {number} y
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
 * @param {Object} o Object that may have slug property
 * @returns {string|undefined}
 */
const slug = o => (o || {}).slug

/**
 * Returns properties required to place a background Lank.
 * @param {Object} backgroundArt
 * @returns {Object|undefined} a background object
 */
const background = backgroundArt => {
  if (!(backgroundArt || {}).type) {
    return
  }
  if (!(backgroundArt.type || {}).slug) {
    return
  }
  const { pos, scaleX, scaleY } = backgroundArt

  return {
    slug: backgroundArt.type.slug,
    thang: _.merge(DEFAULT_THANGTYPE(), { pos, scaleX, scaleY })
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
    thang: _.merge(DEFAULT_THANGTYPE(), { scaleX, scaleY, pos })
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
    thang: _.merge(DEFAULT_THANGTYPE(), { scaleX, scaleY, pos })
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

/**
 * Returns the left character if it's a thangType slug.
 * @param {Shot} shot
 * @returns {Object|undefined} thangType slug, position data and whether to animate in the thang.
 */
export const getLeftCharacterThangTypeSlug = compose(shotSetup, leftCharacter, characterThangTypeSlug)

/**
 * Returns the right character if it's a thangType slug.
 * @param {Shot} shot
 * @returns {Object|undefined} thangType slug, position data and whether to animate in the thang.
 */
export const getRightCharacterThangTypeSlug = compose(shotSetup, rightCharacter, characterThangTypeSlug)

/**
 * @param {DialogNode} dialogNode
 * @returns {bool} whether we should clear all existing dialogs.
 */
export const getClearText = dialogNode => (dialogNode || {}).dialogClear || false

export const getTextPosition = dialogNode => (dialogNode || {}).textLocation

export const getSpeaker = dialogNode => (dialogNode || {}).speaker

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
  if (!bgObject) {
    return
  }

  return _.merge(DEFAULT_THANGTYPE(), bgObject.thangType)
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
 * Returns if left hero character
 * @param {Shot} shot
 * @returns {bool}
 */
export const getLeftHero = compose(shotSetup, leftCharacter, heroThangTypeOriginal)

/**
 * Returns the right hero character
 * @param {Shot} shot
 * @returns {bool}
 */
export const getRightHero = compose(shotSetup, rightCharacter, heroThangTypeOriginal)

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
 * @param {DialogNode} dialogNode
 * @returns {Object|undefined} backgroundObject
 */
export const getBackgroundObject = compose(triggers, backgroundObject)

/**
 * @param {DialogNode} dialogNode
 * @returns {number|undefined} the delay before removing the background object.
 */
export const getClearBackgroundObject = compose(triggers, clearBackgroundObject)
