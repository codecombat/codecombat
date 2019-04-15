import { getLeftCharacterThangTypeSlug, getRightCharacterThangTypeSlug } from '../../../../schemas/selectors/cinematic'

export const parseShot = (shot, systems) => {
  return parseSetup(shot, systems)
}

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
  const { cinematicLankBoss, loader } = systems
  const setupCommands = []

  const leftCharSlug = getLeftCharacterThangTypeSlug(shot)

  if (leftCharSlug) {
    const { slug, enterOnStart, position } = leftCharSlug
    cinematicLankBoss.addLank('left', loader.getThangType(slug), systems)
    if (enterOnStart) {
      setupCommands.push(cinematicLankBoss.moveLankCommand('left', position))
    } else {
      cinematicLankBoss.moveLank('left', position)
    }
  }

  const rightCharSlug = getRightCharacterThangTypeSlug(shot)
  if (rightCharSlug) {
    const { slug, enterOnStart, position } = rightCharSlug
    cinematicLankBoss.addLank('left', loader.getThangType(slug), systems)
    if (enterOnStart) {
      setupCommands.push(cinematicLankBoss.moveLankCommand('left', position))
    } else {
      cinematicLankBoss.moveLank('left', position)
    }
  }

  return setupCommands
}
