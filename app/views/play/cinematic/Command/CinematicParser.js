export const parseShot = (shot, systems) => {
  return parseSetup(shot, systems)
}

/**
 * @typedef {import('../../../../schemas/selectors/cinematic').Cinematic} Cinematic
 */

/**
 * @typedef {import('../../../../schemas/selectors/cinematic').Shot} Shot
 */

/**
 * @typedef {import('../../../../schemas/selectors/cinematic').ShotSetup} ShotSetup
 */

/**
 * @typedef {import('../../../../schemas/selectors/cinematic').DialogNode} DialogNode
 */

/**
 * @typedef {Object} CommandTuple
 * @property {AbstractCommand[]} commands - The commands to be run to execute this dialogNode or shotSetup.
 * @property {AbstractCommand[]} cleanupCommands - commands that can be used to cleanup prior commands.
 */

/**
 * Interface for classes that represent a System.
 *
 * @interface System
 */

/**
 * @function
 * @name System#parseSetupShot
 * @param {Shot} - The data of the current shot.
 * @returns {CommandTuple} - commands are run immediately. cleanupCommands will be run at the end of the shot.
 */

/**
 * @function
 * @name System#parseDialogNode
 * @param {DialogNode} - The dialogNode data.
 * @returns {CommandTuple} - commands are run immediately. cleanupCommands get run just before next dialogNode runs.
 */

/**
 * @typedef {Object} Systems
 * @param {CinematicLankBoss} cinematicLankBoss
 */

/**
 * Returns an array of Commands for the setup of the shot.
 * @param {Shot} shot
 * @param {Systems} systems
 */
const parseSetup = (shot, systems) => {
  const { cinematicLankBoss } = systems
  let setupCommands = []

  setupCommands = setupCommands.concat(cinematicLankBoss.parseSetupShot(shot).commands || [])

  return setupCommands
}
