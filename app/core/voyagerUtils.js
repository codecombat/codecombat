
module.exports = {

  /**
   * Creates a level status map using the list of level session objects.
   * @param {Object[]} sessions - The list of level session objects.
   * @returns {Object} - Object with key as the level original id, and value as complete/started.
   */
  getLevelStatusMap: function (sessions) {
    let levelStatusMap = {}
    for (let session of sessions) {
      let levelOriginal = (session.level || session.get('level') || {}).original
      if (levelOriginal && levelStatusMap[levelOriginal] !== 'complete') { // Don't overwrite a complete session with an incomplete one
        if ((session.state || session.get('state') || {}).complete) {
          levelStatusMap[levelOriginal] = 'complete'
        } else {
          levelStatusMap[levelOriginal] = 'started'
        }
      }
    }
    return levelStatusMap
  },

  /**
   * Creates a level data map using the list of level objects.
   * @param {Object[]} levels - The list of level objects.
   * @returns {Object} - Object with key as the level original id, and value as the object containing level's data.
   */
  getLevelDataMap: function (levels) {
    let levelDataMap = {}
    for (let level of levels) {
      let levelOriginal = level.original || level.get('original')
      if (levelOriginal) {
        levelDataMap[levelOriginal] = level.attributes || level
      }
    }
    return levelDataMap
  },

  /**
   * Gets the next level original id for a given level
   * @param {Object} level - The level object.
   * @param {Object[]} level.nextLevels - The array of nextLevels for the given level.
   * @returns {string|undefined} - 'Original' id of the next level, or undefined.
   */
  getNextLevelOriginalForLevel: function (level) {
    let nextLevels = level.nextLevels
    if ((nextLevels || []).length > 0) {
      return nextLevels[0].levelOriginal // assuming that there will be just one next level for voyager v1 as of now.
    }
    return undefined
  },

  /**
   * Calculates all the next levels for a list of levels in a classroom/campaign and level sessions.
   * @param {Object[]} sessions - The list of level session objects.
   * @param {Object[]|Object} levels - The list of level objects, or an object with keys as level original id and value as level data.
   * @param {Object[]} levels.nextLevels - The array of nextLevels for a level.
   * @param {Object} levels.position - The object containing position of a level.
   * @param {boolean} levels.first - Value to determine if a level is the first level of classroom/campaign.
   * @param {Object} levelStatusMap - Optional. Object with key as the level original id, and value as complete/started.
   * @returns {Object[]} - Array of next level objects.

   * There would only be 1 next level for voyager v1 as of now, hence use the first element of the array returned from here.
   * TODO: Edge case - If the 'sessions' contain a session for a level which has been played in another classroom, or another campaign;
   * then it will be part of the nextLevels even if not unlocked for the current classroom/campaign.
  */
  findNextLevels: function (sessions, levels, levelStatusMap) {
    if (!levelStatusMap) {
      levelStatusMap = this.getLevelStatusMap(sessions)
    }
    let nextLevels = [] // next level = started levels + incomplete unlocked levels + not-started first levels
    let levelDataMap = {}
    if (_.isArray(levels)) {
      levelDataMap = this.getLevelDataMap(levels)
    } else {
      levelDataMap = levels
    }
    for (let [i, level] of Object.entries(levelDataMap)) {
      if (levelStatusMap[i] === 'started' && nextLevels.indexOf(level) < 0) {
        nextLevels.push(level)
      } else if (levelStatusMap[i] === 'complete') {
        let nextLevelOriginal = this.getNextLevelOriginalForLevel(level)
        if (nextLevelOriginal && levelStatusMap[nextLevelOriginal] !== 'complete' && nextLevels.indexOf(levelDataMap[nextLevelOriginal]) < 0) {
          nextLevels.push(levelDataMap[nextLevelOriginal]) // incomplete unlocks
        }
      } else if (level.first && nextLevels.indexOf(level) < 0) {
        nextLevels.push(level)
      }
    }
    return nextLevels
  }
}
