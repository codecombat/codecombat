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
 * parseShot converts the shot into bytecode.
 *
 * @param {Shot} shot - The shot to convert into bytecode
 */
export const parseShot = (shot, systems) => {
  const shotSetup = shot.shotSetup
  const dialogNodes = shot.dialogNodes

  return parseSetup(shotSetup, systems)
}

/**
 * @typedef {Object} Systems
 * @param {CinematicLankBoss} cinematicLankBoss
 */

/**
 * Returns an array of Commands for the shotSetup.
 * @param {ShotSetup} shotSetup - The shotsetup
 * @param {Systems} systems
 */
const parseSetup = (shotSetup, systems) => {
  const { cinematicLankBoss, loader } = systems
  const setupCommands = []

  // Ensure lanks exist on the cinematicLankBoss
  if (shotSetup.leftThangType && shotSetup.leftThangType.type === 'slug') {
    const slug = shotSetup.leftThangType.slug
    cinematicLankBoss.addLank('left', loader.getThangType(slug), systems)
  }
  if (shotSetup.rightThangType && shotSetup.rightThangType.type === 'slug') {
    const slug = shotSetup.rightThangType.slug
    cinematicLankBoss.addLank('right', loader.getThangType(slug), systems)
  }

  // Slide them in if required.
  if (shotSetup.leftThangType && shotSetup.leftThangType.enterOnStart) {
    const pos = shotSetup.leftThangType.position
    setupCommands.push(cinematicLankBoss.moveLankCommand('left', pos))
  }
  if (shotSetup.rightThangType && shotSetup.rightThangType.enterOnStart) {
    const pos = shotSetup.rightThangType.position
    setupCommands.push(cinematicLankBoss.moveLankCommand('right', pos))
  }

  return setupCommands
}
