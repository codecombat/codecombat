(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestProgression = api
    if (root.JSQuestMissions && root.JSQuestEngine) api.apply(root.JSQuestMissions, root.JSQuestEngine)
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  function thresholdForLevel (level) {
    if (level <= 0) return 0
    return 1 + ((level - 1) * (3 * level + 2)) / 2
  }

  function levelForXp (xp) {
    let level = 0
    while (thresholdForLevel(level + 1) <= xp) level++
    return level
  }

  function replaceChar (row, index, char) {
    return row.slice(0, index) + char + row.slice(index + 1)
  }

  function addRequiredGem (mission, variant, variantIndex, engine) {
    if (mission.id === 0 || variant.map.some(row => row.includes('*'))) return

    const result = engine.simulate(mission.solution, mission, variantIndex)
    if (!result.ok) throw new Error('Could not prepare gem for mission ' + mission.id + ': ' + result.error.message)

    for (const frame of result.trace || []) {
      if (frame.type !== 'move') continue
      const row = variant.map[frame.y]
      if (row && row[frame.x] === '.') {
        variant.map[frame.y] = replaceChar(row, frame.x, '*')
        return
      }
    }

    throw new Error('Could not place a required gem on mission ' + mission.id + ', variant ' + variantIndex)
  }

  function apply (missions, engine) {
    if (!Array.isArray(missions) || !engine || missions.__wizardProgressionApplied) return missions

    for (const mission of missions) {
      if (mission.id === 0) continue
      mission.requirements = mission.requirements || {}
      mission.requirements.state = mission.requirements.state || {}
      mission.requirements.state.minGems = Math.max(1, Number(mission.requirements.state.minGems) || 0)
      mission.instructions = mission.instructions || []
      mission.api = mission.api || []
      if (!mission.instructions.some(text => text.includes('宝石を集めないと'))) {
        mission.instructions.push('このミッションの宝石を集めないとクリアできません。')
      }
      mission.variants.forEach((variant, index) => addRequiredGem(mission, variant, index, engine))
    }

    const firstGemMission = missions.find(mission => mission.id === 1)
    if (firstGemMission && !firstGemMission.story.includes('経験値')) {
      firstGemMission.story += ' 宝石は魔法使いの経験値になり、新しい力を使えるようにします。'
    }

    let xp = 0
    for (const mission of missions) {
      const reward = mission.id === 0 ? 0 : Math.max(1, Number(mission.requirements?.state?.minGems) || 1)
      mission.wizardXpBefore = xp
      mission.wizardLevel = levelForXp(xp)
      mission.wizardXpReward = reward
      mission.wizardXpAfter = xp + reward
      mission.wizardLevelAfter = levelForXp(mission.wizardXpAfter)
      mission.nextLevelXp = thresholdForLevel(mission.wizardLevel + 1)
      mission.currentLevelXp = thresholdForLevel(mission.wizardLevel)

      if (mission.wizardLevel >= 1) {
        if (!mission.api.includes('hero.transform("frog")')) mission.api.push('hero.transform("frog")')
        if (!mission.api.includes('hero.transform("hero")')) mission.api.push('hero.transform("hero")')
      }
      xp += reward
    }

    Object.defineProperty(missions, '__wizardProgressionApplied', { value: true })
    return missions
  }

  return { apply, levelForXp, thresholdForLevel }
})
