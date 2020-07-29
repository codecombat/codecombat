import { merge } from 'lodash'
import { i18n } from 'app/core/utils'

/**
 Utility functions for ozaria
 */

export const defaultCodeLanguage = 'python'

export function getOzariaAssetUrl (assetName) {
  return `/file/${encodeURI(assetName)}`
}

/**
 * Calculates all the next levels for a list of levels in a classroom/campaign based on the level sessions.
 * @param {Object[]} sessions - The list of level session objects.
 * @param {Object[]|Object} levels - The list of level objects, or an object with keys as level original id and value as level data.
 * @param {Object} levels.nextLevels - The array of nextLevels for a level.
 * @param {boolean|undefined} levels.isPlayedInStages - True/false/undefined
 * @param {Object} levels.position - The object containing position of a level.
 * @param {boolean} levels.first - Value to determine if a level is the first level of classroom/campaign.
 * @param {Object} levelStatusMap - Optional. Object with key as the level original id, and value as complete/started.
 * @returns {string} - Next level's original id.
 */
export const findNextLevelsBySession = (sessions, levels, levelStatusMap) => {
  if (!levelStatusMap) {
    levelStatusMap = getLevelStatusMap(sessions)
  }
  const nextLevelOriginals = new Set() // next level = started levels + incomplete unlocked levels + not-started first levels

  let levelDataMap = {}
  if (_.isArray(levels)) {
    levelDataMap = getLevelDataMap(levels)
  } else {
    levelDataMap = levels || {}
  }
  for (const [levelOriginal, level] of Object.entries(levelDataMap)) {
    const levelStatus = levelStatusMap[levelOriginal]
    const isLevelStarted = typeof levelStatus === 'string' && levelStatus === 'started'
    const isLevelCompleted = typeof levelStatus === 'string' && levelStatus === 'complete'
    const hasCompletedStages = typeof levelStatus === 'number' && levelStatus > 0

    if (isLevelStarted) {
      nextLevelOriginals.add(levelOriginal)
    } else if (isLevelCompleted || hasCompletedStages) {
      let unlockedLevel = {}
      if (level.isPlayedInStages) {
        const stageCompleted = levelStatusMap[levelOriginal]
        unlockedLevel = getNextLevelForLevel(level, stageCompleted) || {}
      } else {
        unlockedLevel = getNextLevelForLevel(level) || {}
      }
      const unlockedLevelStatus = levelStatusMap[unlockedLevel.original]
      const unlockedLevelCompleted = (typeof unlockedLevelStatus === 'string' && unlockedLevelStatus === 'complete') ||
        (typeof unlockedLevelStatus === 'number' && unlockedLevelStatus >= unlockedLevel.nextLevelStage)
      if (!unlockedLevelCompleted && unlockedLevel.original) { // add incomplete unlocks
        nextLevelOriginals.add(unlockedLevel.original)
      }
    } else if (level.first) {
      nextLevelOriginals.add(levelOriginal)
    }
  }
  return [...nextLevelOriginals][0] // assuming there can only be one next level for the given levels and their sessions
}

/**
 * Returns the options to be used with ajv for json schema validation (used for draft-07 as of now)
 */
export const getAjvOptions = () => {
  const options = {
    unknownFormats: ['ace', 'hidden', 'i18n', 'image-file', 'markdown'] // list of formats unknown to ajv but need to be supported
  }
  return options // If we want to support both draft-04 and draft-06/07 schemas then add { schemaId: 'auto' } to options
}

/**
 * Creates a level data map using the list of level objects.
 * @param {Object[]} levels - The list of level objects.
 * @returns {Object} - Object with key as the level original id, and value as the object containing level's data.
 */
export const getLevelDataMap = (levels) => {
  const levelDataMap = {}
  for (const level of levels) {
    const levelOriginal = level.original || level.get('original')
    if (levelOriginal) {
      levelDataMap[levelOriginal] = level.attributes || level
    }
  }
  return levelDataMap
}

/**
 * Gets the level data given a list of levels and list of level original ids.
 * @param {Object[]|Object} levels - The list of level objects, or an object with keys as level original id and value as level data.
 * @param {string[]} levelOriginals - The list of level original ids.
 * @returns {Object[]} - Array of level objects.
 */
export const getLevelsDataByOriginals = (levels, levelOriginals) => {
  let levelDataMap = {}
  if (_.isArray(levels)) {
    levelDataMap = getLevelDataMap(levels)
  } else {
    levelDataMap = levels
  }
  return levelOriginals.map((original) => levelDataMap[original])
}

/**
 * Creates a level status map using the list of level session objects.
 * @param {Object[]} sessions - The list of level session objects.
 * @returns {Object} - Object with key as the level original id, and value = complete/started/capstone stage last 'completed'.
 */
export const getLevelStatusMap = (sessions) => {
  const levelStatusMap = {}
  for (const session of sessions) {
    const levelOriginal = (session.level || session.get('level') || {}).original
    const sessionState = session.state || session.get('state') || {}
    const capstoneStage = sessionState.capstoneStage // current capstone stage (undefined if user is on stage 1)
    const isLevelAreadyComplete = levelOriginal && (levelStatusMap[levelOriginal] === 'complete' || (capstoneStage && levelStatusMap[levelOriginal] === capstoneStage - 1))
    if (!isLevelAreadyComplete) { // Don't overwrite a complete session with an incomplete one
      if (capstoneStage && capstoneStage > 1) {
        levelStatusMap[levelOriginal] = capstoneStage - 1 // for levels played in stages (capstone levels), levelStatusMap = last completed stage
      } else if (sessionState.complete) {
        levelStatusMap[levelOriginal] = 'complete'
      } else {
        levelStatusMap[levelOriginal] = 'started' // for levels played in stages (capstone levels) as well as normal levels
      }
    }
  }
  return levelStatusMap
}

/**
 * Gets the next level original ids for a given level
 * @param {Object} level - The level object.
 * @param {Object} level.nextLevels - The array of nextLevels for the given level.
 * @param {boolean|undefined} level.isPlayedInStages - True/false/undefined
 * @param {number} capstoneStage - Stage of capstone level for which we need the next level
 * @returns {Object} - Next level object containing 'Original' id and next level's stage.
 */
export const getNextLevelForLevel = (level, capstoneStage = 1) => {
  const nextLevels = level.nextLevels || {}
  let nextLevel = []
  if (capstoneStage && level.isPlayedInStages) {
    nextLevel = Object.values(nextLevels).filter((n) => (n.conditions || {}).afterCapstoneStage === capstoneStage)
  } else {
    nextLevel = Object.values(nextLevels)
  }
  return nextLevel[0] // assuming there can only be one next level for a given level and/or capstone stage
}

/**
 * Constructs the next level link
 * @param {Object} levelData - Level object
 * @param {string} levelData.type - level type
 * @param {string} levelData.slug - level slug
 * @param {string} levelData.primerLanguage - Optional, used only if it exists
 * @param {Object} options - Options for the next level link
 * @param {string} options.courseId
 * @param {string} options.courseInstanceId
 * @param {string} options.campaignId
 * @param {string} options.codeLanguage
 * @returns {string}
 */
// TODO: move to app/core/urls and use `$.param(queryParams)` to build query string
export const getNextLevelLink = (levelData, options) => {
  let link = ''
  if (levelData.type === 'intro') {
    link = '/play/intro/' + levelData.slug
  } else {
    link = '/play/level/' + levelData.slug
  }

  if (options.courseId && options.courseInstanceId) {
    link += `?course=${encodeURIComponent(options.courseId)}&course-instance=${encodeURIComponent(options.courseInstanceId)}`
    if (levelData.primerLanguage) {
      link += `&codeLanguage=${encodeURIComponent(levelData.primerLanguage)}`
    }
    if (options.nextLevelStage) {
      link += `&capstoneStage=${encodeURIComponent(options.nextLevelStage)}`
    }
  } else if (options.courseInstanceId) {
    link += `?course-instance=${encodeURIComponent(options.courseInstanceId)}`
    if (options.codeLanguage) {
      link += `&codeLanguage=${encodeURIComponent(options.codeLanguage)}`
    }
    if (options.nextLevelStage) {
      link += `&capstoneStage=${encodeURIComponent(options.nextLevelStage)}`
    }
  } else if (options.courseId) {
    link += `?course=${encodeURIComponent(options.courseId)}`
    if (options.codeLanguage) {
      link += `&codeLanguage=${encodeURIComponent(options.codeLanguage)}`
    }
    if (options.nextLevelStage) {
      link += `&capstoneStage=${encodeURIComponent(options.nextLevelStage)}`
    }
  } else if (options.codeLanguage) {
    link += `?codeLanguage=${encodeURIComponent(options.codeLanguage)}`
    if (options.nextLevelStage) {
      link += `&capstoneStage=${encodeURIComponent(options.nextLevelStage)}`
    }
  } else if (options.nextLevelStage) {
    link += `?capstoneStage=${encodeURIComponent(options.nextLevelStage)}`
  }
  return link
}

export function internationalizeConfig (levelConfig, userLocale) {
  const interactiveConfigI18n = levelConfig.i18n || {}

  const userGeneralLocale = (userLocale || '').split('-')[0]
  const fallbackLocale = 'en'

  const userLocaleObject = interactiveConfigI18n[userLocale] || {}
  const generalLocaleObject = interactiveConfigI18n[userGeneralLocale] || {}
  const fallbackLocaleObject = interactiveConfigI18n[fallbackLocale] || {}

  levelConfig = merge(
    {},
    levelConfig,
    fallbackLocaleObject,
    generalLocaleObject,
    userLocaleObject
  )

  for (const values of Object.values(levelConfig)) {
    if (Array.isArray(values)) {
      for (const arrayVal of values) {
        internationalizeConfigAux(arrayVal, userLocale)
      }
    } else if (typeof values === 'object') {
      internationalizeConfigAux(values, userLocale)
    }
  }

  return levelConfig
}

/**
 * This replaces properties recursively with the i18n properties.
 * It's a very naive implementation and should be replaced with the
 * i18n function in utils.
 *
 * The translation falls back to English but doesn't fall sideways or
 * fallback gracefully from Traditional to Simplified Chinese.
 */
function internationalizeConfigAux (obj, userLocale) {
  const { i18n } = obj || {}
  if (i18n) {
    const translatedObj = i18n[userLocale] || {}
    _.merge(obj, translatedObj)
    return
  }

  for (const values of Object.values(obj)) {
    if (Array.isArray(values)) {
      for (const arrayVal of values) {
        internationalizeConfigAux(arrayVal, userLocale)
      }
    } else if (typeof values === 'object') {
      internationalizeConfigAux(values, userLocale)
    }
  }
}

export function tryCopy () {
  try {
    document.execCommand('copy')
  } catch (err) {
    const message = 'Oops, unable to copy'
    noty({ text: message, layout: 'topCenter', type: 'error', killer: false })
  }
}

export function internationalizeLevelType(type, withLevelSuffix, withProjectSuffix){
  if (['challenge', 'capstone', 'practice', 'cutscene', 'intro'].indexOf(type) == -1){
    type = 'practice'
  }
  let key = 'play_level.level_type_' + type;
  if (withProjectSuffix && type === 'capstone') {
    key += '_project'
  } else if (withLevelSuffix){
    key += '_level'
  }
  return $.i18n.t(key)
}

export function internationalizeContentType(type){
  switch (type) {
    case 'cutscene-video':
      return $.i18n.t('play_level.level_type_cutscene')
    case 'cutscene':
      return $.i18n.t('play_level.level_type_cutscene')
    case 'avatarSelectionScreen':
      return $.i18n.t('play_level.content_type_avatar')
    case 'cinematic':
      return $.i18n.t('play_level.content_type_cinematic')
    case 'interactive':
      return $.i18n.t('play_level.content_type_interactive')
    default:
      return this.currentContent.contentType
  }
}

// OLD TEACHER DASHBOARD
// Returns the display label for levels of type practice/challenge/intro/cutscene/capstone
// For cutscene levels, its name is determined from introContent which should contain the cutscene name.
export function getLevelDisplayNameWithLabel (level) {
  if (!level) {
    return
  }
  const contentType = level.getDisplayContentType()
  let levelName = i18n(level.attributes, 'displayName') || i18n(level.attributes, 'name')
  if (contentType === 'cutscene' && (level.get('introContent') || [])[0]) {
    levelName = level.get('introContent')[0].displayName || levelName
  }

  if (contentType === 'capstone') {
    return internationalizeLevelType(contentType, false, true) + ': ' + levelName
  }
  return internationalizeLevelType(contentType) + ': ' + levelName
}

// OLD TEACHER DASHBOARD
// Only for cinematics/interactives
export function getIntroContentNameWithLabel (introContent) {
  if (!introContent) {
    return
  }
  const displayName = introContent.displayName || '...'
  if (introContent.type) {
    return internationalizeContentType(introContent.type) + ': ' + displayName
  }
}

// Used for new teacher dashboard, contentData is the list-item returned by game-content APIs
// i.e. levels broken down into practice/cinematics/interactives etc
// `withLevelSuffix` will append 'Level' to the names for practice/capstone/challenge levels
// `withProjectSuffix` will append 'Project' to the capstone name
export function getGameContentDisplayNameWithType (contentData, withLevelSuffix = true, withProjectSuffix = false) {
  if (!contentData) {
    return
  }
  const contentName = i18n(contentData, 'displayName') || i18n(contentData, 'name')
  const contentType = getGameContentDisplayType(contentData.ozariaType || contentData.type, withLevelSuffix, withProjectSuffix)
  return `${contentType}: ${contentName}`
}

// `withLevelSuffix` will append 'Level' to the names for practice/capstone/challenge levels
// `withProjectSuffix` will append 'Project' to the capstone name
export function getGameContentDisplayType (contentType, withLevelSuffix = true, withProjectSuffix = false) {
  if (contentType.startsWith('practice')) {
    return internationalizeLevelType('practice', withLevelSuffix, withProjectSuffix)
  } else if (contentType.startsWith('capstone')) {
    return internationalizeLevelType('capstone', withLevelSuffix, withProjectSuffix)
  } else if (contentType.startsWith('challenge')) {
    return internationalizeLevelType('challenge', withLevelSuffix, withProjectSuffix)
  } else {
    return internationalizeContentType(contentType)
  }
}
