import { ConcurrentCommands } from './commands'

/**
 * @typedef {import('../../../../app/schemas/models/selectors/cinematic').Cinematic} Cinematic
 */

/**
 * @typedef {import('../../../../app/schemas/models/selectors/cinematic').Shot} Shot
 */

/**
 * @typedef {import('../../../../app/schemas/models/selectors/cinematic').ShotSetup} ShotSetup
 */

/**
 * @typedef {import('../../../../app/schemas/models/selectors/cinematic').DialogNode} DialogNode
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
 * @returns {AbstractCommand[]} - commands run just before the first dialogNode.
 */

/**
 * @function
 * @name System#parseDialogNode
 * @param {DialogNode} - The dialogNode data.
 * @returns {AbstractCommand[]} - commands for a dialogNode.
 */

/**
 * @typedef {Object} Systems
 * @param {CinematicLankBoss} cinematicLankBoss
 */

/**
 * Returns an array of Commands for the setup of the shot.
 * @param {Shot} shot
 * @param {Systems} systems
 * @returns {AbstractCommand[]} The commands to run at the start and end of the shot.
 */
const parseSetup = (shot, systems) =>
  Object.values(systems)
    .filter(sys => sys !== undefined && typeof sys.parseSetupShot === 'function')
    .reduce((commands, sys) => {
      const systemCommands = sys.parseSetupShot(shot)
      if (!Array.isArray(systemCommands)) {
        throw new Error('Your system should always return an array of commands for a systemSetup')
      }
      return [...commands, ...systemCommands]
    }
    , [])

/**
 * Returns an array of commands.
 * This is required as we update this list to add commands to the start and end.
 * @param {DialogNode} dialogNode
 * @param {Object} systems
 * @returns {AbstractCommand[]}
 */
const parseDialogNode = (dialogNode, systems) => {
  const dialogCommands = Object.values(systems)
    .filter(sys => sys !== undefined && typeof sys.parseDialogNode === 'function')
    .reduce((commands, sys) => {
      const dialogCommands = sys.parseDialogNode(dialogNode)
      if (!Array.isArray(dialogCommands)) {
        throw new Error('Your system should always return an array of commands for a dialogNode')
      }
      return [...commands, ...dialogCommands]
    }, [])
  return [new ConcurrentCommands(dialogCommands)]
}

/**
 * Parses a shot and dialog nodes.
 *
 * Returns a 2d array of command nodes. Each inner array is passed into the
 * CommandRunner and run until user interuption or conclusion. Then between the
 * inner arrays the cinematicController waits before running the next command batch.
 *
 * @param {Shot} shot The shot that is being run.
 * @param {Object} systems The systems.
 * @returns {AbstractCommand[][]} A 2d array of commands.
 */
export const parseShot = (shot, systems = {}) => {
  const setupCommands = parseSetup(shot, systems) || []
  const dialogNodes = (shot.dialogNodes || [])
    .map(node => parseDialogNode(node, systems))
    .filter(dialogCommands => dialogCommands.length > 0)

  // If we have both dialogNodes and some setupCommands we want to
  // have the setup occur just before the first dialogNode.
  if (dialogNodes.length > 0 && setupCommands.length > 0) {
    return [[...setupCommands, ...dialogNodes[0]], ...dialogNodes.slice(1)]
  }
  if (dialogNodes.length === 0) {
    return [setupCommands]
  }
  return dialogNodes
}
