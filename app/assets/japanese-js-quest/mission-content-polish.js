(function (root, factory) {
  const apply = factory()
  if (typeof module === 'object' && module.exports) module.exports = apply
  else apply(root)
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  return function applyMissionContentPolish (root) {
    const mission = root.JSQuestMissions?.find(item => item.id === 1)
    if (!mission) return

    const goalInstruction = 'ヒーローを光るゴールのマスまで進めるとクリアです。'
    if (!mission.instructions.includes(goalInstruction)) {
      mission.instructions.push(goalInstruction)
    }
  }
})
