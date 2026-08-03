(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestLoopRules = api
    if (root.JSQuestMissions) api.apply(root.JSQuestMissions)
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const LOOP_RULES = Object.freeze({
    11: { move: 1 },
    12: { move: 1 },
    13: { move: 3 },
    14: { move: 1, say: 1 },
    15: { move: 5 },
    16: { move: 1 },
    17: { move: 2 },
    18: { move: 2 },
    19: { move: 3 },
    20: { move: 2 },
    21: { move: 3 },
    22: { move: 3 },
  })

  function sourceLimitLabel (method, maximum) {
    return 'コードに hero.' + method + '(...)：最大 ' + maximum + ' 回'
  }

  function apply (missions) {
    if (!Array.isArray(missions)) return missions

    for (const mission of missions) {
      const limits = LOOP_RULES[mission.id]
      if (!limits) continue

      mission.requirements = mission.requirements || {}
      mission.requirements.sourceCallLimits = Object.entries(limits).map(([method, max]) => ({
        method,
        max,
      }))

      const maxMoves = mission.requirements.state && mission.requirements.state.maxMoves
      mission.victoryConditions = []
      if (Number.isFinite(maxMoves)) {
        mission.victoryConditions.push({
          id: 'max-moves',
          label: '移動：最大 ' + maxMoves + ' 回',
        })
      }
      for (const [method, maximum] of Object.entries(limits)) {
        mission.victoryConditions.push({
          id: 'source-' + method,
          label: sourceLimitLabel(method, maximum),
        })
      }
    }

    return missions
  }

  return Object.freeze({
    apply,
    LOOP_RULES,
    sourceLimitLabel,
  })
})
