// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Level = require('models/Level')

// group course/campaign levels by module number
const buildLevelsListByModule = function (levels, isCh1) {
  let introBeforeLastCapstoneStageOriginal
  if (isCh1 == null) { isCh1 = false }
  const levelsModuleMap = {}
  // Find the intro before the last capstone stage for CH1
  // since CH1 capstone needs to be placed after that in the levels list
  if (isCh1 && levels.find(l => l.isCapstone())) {
    const capstoneOriginal = levels.find(l => l.isCapstone()).get('original')
    const totalCapstoneStages = 10 // Hardcoding the num of stages since its not available in level data, TODO refactor later
    if (capstoneOriginal) {
      const introBeforeLastCapstoneStage = levels.find(l => {
        const nextLevel = Object.values(l.get('nextLevels') || {})[0] || {}
        return (nextLevel.original === capstoneOriginal) && (nextLevel.nextLevelStage === totalCapstoneStages)
      })
      introBeforeLastCapstoneStageOriginal = introBeforeLastCapstoneStage != null ? introBeforeLastCapstoneStage.get('original') : undefined
    }
  }
  let capstoneLevel = {}
  levels.forEach(l => {
    const moduleNumber = l.get('moduleNum') || 1
    if (isCh1 && l.isCapstone()) {
      capstoneLevel = new Level(l.attributes)
      return capstoneLevel
    } else {
      if (levelsModuleMap[moduleNumber] == null) { levelsModuleMap[moduleNumber] = [] }
      levelsModuleMap[moduleNumber].push(l)
      if (isCh1 && introBeforeLastCapstoneStageOriginal && (l.get('original') === introBeforeLastCapstoneStageOriginal)) {
        return levelsModuleMap[moduleNumber].push(capstoneLevel)
      }
    }
  })
  return levelsModuleMap
}

module.exports = {
  buildLevelsListByModule
}
