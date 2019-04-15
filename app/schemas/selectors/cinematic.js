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
 * @typedef {Object} CharacterSchema
 * @property {string} type
 * @property {string} slug
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
 * Takes the cinematic data that adheres to cinematic schema and returns
 * just the array of shots.
 * @param {Shot[]} cinematicData
 */
export const shots = cinematicData => {
  if (cinematicData && cinematicData.shots) {
    return cinematicData.shots
  }
  return undefined
}

/**
 * @param {Shot} shot
 * @returns {undefined|ShotSetup} shotsetup
 */
export const shotSetup = shot => shot && shot.shotSetup

/**
 * @param {ShotSetup} shotSetup
 * @returns {CharacterSchema|undefined}
 */
const leftCharacter = shotSetup => shotSetup && shotSetup.leftThangType

/**
 * @param {ShotSetup} shotSetup
 * @returns {CharacterSchema|undefined}
 */
const rightCharacter = shotSetup => shotSetup && shotSetup.rightThangType

/**
 * Returns exactly the data required to fulfill the information to place a character
 * onto the screen.
 * @param {CharacterSchema} character - the left or right character in CharacterSchema
 */
const characterThangTypeSlug = character => {
  if (!character) {
    return
  }
  if (character.type && character.type !== 'slug') {
    return
  }

  const type = character.type
  const slug = character.slug || (() => { throw new Error(`no slug on char`) })()
  const enterOnStart = character.enterOnStart !== undefined
    ? character.enterOnStart
    : (() => { throw new Error('no enterOnStart for char') })()
  const position = character.position ||
    (() => { throw new Error('no position for char') })()

  return { type, slug, enterOnStart, position }
}

/**
 * Returns the left character if it's a thangType slug.
 * Throws error if malformed object data.
 * @param {Shot} shot
 */
export const getLeftCharacterThangTypeSlug = compose(shotSetup, leftCharacter, characterThangTypeSlug)

/**
 * Returns the right character if it's a thangType slug.
 * Throws error if malformed object data.
 * @param {Shot} shot
 */
export const getRightCharacterThangTypeSlug = compose(shotSetup, rightCharacter, characterThangTypeSlug)
