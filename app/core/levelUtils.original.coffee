Level = require('models/Level')

# group course/campaign levels by module number
buildLevelsListByModule = (levels, isCh1=false) ->
  levelsModuleMap = {}
  # Find the intro before the last capstone stage for CH1
  # since CH1 capstone needs to be placed after that in the levels list
  if isCh1 && levels.find((l) => l.isCapstone())
    capstoneOriginal = levels.find((l) => l.isCapstone()).get('original')
    totalCapstoneStages = 10 # Hardcoding the num of stages since its not available in level data, TODO refactor later
    if capstoneOriginal
      introBeforeLastCapstoneStage = levels.find((l) =>
        nextLevel = Object.values(l.get('nextLevels') || {})[0] || {}
        return nextLevel.original == capstoneOriginal && nextLevel.nextLevelStage == totalCapstoneStages
      )
      introBeforeLastCapstoneStageOriginal = introBeforeLastCapstoneStage?.get('original')
  capstoneLevel = {}
  levels.forEach((l) =>
    moduleNumber = l.get('moduleNum') || 1
    if isCh1 && l.isCapstone()
      capstoneLevel = new Level(l.attributes)
    else
      levelsModuleMap[moduleNumber] ?= []
      levelsModuleMap[moduleNumber].push(l)
      if isCh1 && introBeforeLastCapstoneStageOriginal && l.get('original') == introBeforeLastCapstoneStageOriginal
        levelsModuleMap[moduleNumber].push(capstoneLevel)
  )
  return levelsModuleMap

module.exports = {
  buildLevelsListByModule
}
