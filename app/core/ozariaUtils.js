
module.exports = {

  /**
   * Creates a level status map using the list of level session objects.
   * @param {Object[]} sessions - The list of level session objects.
   * @returns {Object} - Object with key as the level original id, and value as complete/started.
   */
  getLevelStatusMap: function (sessions) {
    const levelStatusMap = {}
    for (const session of sessions) {
      const levelOriginal = (session.level || session.get('level') || {}).original
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
    const levelDataMap = {}
    for (const level of levels) {
      const levelOriginal = level.original || level.get('original')
      if (levelOriginal) {
        levelDataMap[levelOriginal] = level.attributes || level
      }
    }
    return levelDataMap
  },

  /**
   * Gets the next level original ids for a given level
   * @param {Object} level - The level object.
   * @param {Object[]} level.nextLevels - The array of nextLevels for the given level.
   * @param {string} level.nextLevels[].levelOriginal - Original id of the next level.
   * @returns {string[]} - Array of next level 'Original' ids.
   */
  getNextLevelOriginalForLevel: function (level) {
    const nextLevels = level.nextLevels
    const nextLevelOriginals = []
    if ((nextLevels || []).length > 0) {
      nextLevelOriginals.push(nextLevels[0].levelOriginal) // assuming that there will be just one next level for ozaria v1 as of now.
      // TODO: handle logic for 1FH capstone level
    }
    return nextLevelOriginals
  },

  /**
   * Calculates all the next levels for a list of levels in a classroom/campaign based on the level sessions.
   * @param {Object[]} sessions - The list of level session objects.
   * @param {Object[]|Object} levels - The list of level objects, or an object with keys as level original id and value as level data.
   * @param {Object[]} levels.nextLevels - The array of nextLevels for a level.
   * @param {string} levels.nextLevels[].levelOriginal - Original id of the next level.
   * @param {Object} levels.position - The object containing position of a level.
   * @param {boolean} levels.first - Value to determine if a level is the first level of classroom/campaign.
   * @param {Object} levelStatusMap - Optional. Object with key as the level original id, and value as complete/started.
   * @returns {string[]} - Array of next level original ids.

   * There would only be 1 next level for ozaria v1 as of now, hence use the first element of the array returned from here.
   */
  findNextLevelsBySession: function (sessions, levels, levelStatusMap) {
    if (!levelStatusMap) {
      levelStatusMap = this.getLevelStatusMap(sessions)
    }
    const nextLevelOriginals = new Set() // next level = started levels + incomplete unlocked levels + not-started first levels

    let levelDataMap = {}
    if (_.isArray(levels)) {
      levelDataMap = this.getLevelDataMap(levels)
    } else {
      levelDataMap = levels
    }
    for (const [levelOriginal, level] of Object.entries(levelDataMap)) {
      if (levelStatusMap[levelOriginal] === 'started') {
        nextLevelOriginals.add(levelOriginal)
      } else if (levelStatusMap[levelOriginal] === 'complete') {
        const unlockedLevelOriginals = this.getNextLevelOriginalForLevel(level) || []
        unlockedLevelOriginals
          .filter((original) => levelStatusMap[original] !== 'complete')
          .forEach((original) => nextLevelOriginals.add(original)) // incomplete unlocks
      } else if (level.first) {
        nextLevelOriginals.add(levelOriginal)
      }
    }
    return [...nextLevelOriginals]
  },

  /**
   * Gets the level data given a list of levels and list of level original ids.
   * @param {Object[]|Object} levels - The list of level objects, or an object with keys as level original id and value as level data.
   * @param {string[]} levelOriginals - The list of level original ids.
   * @returns {Object[]} - Array of level objects.
   */
  getLevelsDataByOriginals: function (levels, levelOriginals) {
    let levelDataMap = {}
    if (_.isArray(levels)) {
      levelDataMap = this.getLevelDataMap(levels)
    } else {
      levelDataMap = levels
    }
    return levelOriginals.map((original) => levelDataMap[original])
  },

  /**
   * Returns the options to be used with ajv for json schema validation (used for draft-07 as of now)
   */
  getAjvOptions: function () {
    const options = {
      unknownFormats: ['ace', 'hidden', 'i18n'] // list of formats unknown to ajv but need to be supported
    }
    return options // If we want to support both draft-04 and draft-06/07 schemas then add { schemaId: 'auto' } to options
  }
}
