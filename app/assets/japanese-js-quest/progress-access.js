(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestProgressAccess = api
    const missionCount = Array.isArray(root.JSQuestMissions) ? root.JSQuestMissions.length : 0
    api.normalizeStorage(root.localStorage, 'japanese-js-quest-progress-v1', missionCount)
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  function sanitizeCompleted (completed, missionCount) {
    if (!Array.isArray(completed) || missionCount < 1) return []
    return Array.from(new Set(completed
      .map(Number)
      .filter(id => Number.isInteger(id) && id >= 0 && id < missionCount)))
      .sort((left, right) => left - right)
  }

  function deriveUnlocked (completed, missionCount) {
    if (missionCount < 1) return 1
    const completedSet = new Set(sanitizeCompleted(completed, missionCount))
    let unlocked = 1
    while (unlocked < missionCount && completedSet.has(unlocked - 1)) unlocked++
    return unlocked
  }

  function normalizeProgress (saved, missionCount) {
    const completed = sanitizeCompleted(saved && saved.completed, missionCount)
    return {
      completed,
      unlocked: deriveUnlocked(completed, missionCount),
    }
  }

  function normalizeStorage (storage, storageKey, missionCount) {
    if (!storage || missionCount < 1) return null
    try {
      const raw = storage.getItem(storageKey)
      const saved = raw ? JSON.parse(raw) : {}
      const normalized = normalizeProgress(saved, missionCount)
      if (raw !== JSON.stringify(normalized)) {
        storage.setItem(storageKey, JSON.stringify(normalized))
      }
      return normalized
    } catch (_) {
      const normalized = normalizeProgress({}, missionCount)
      try {
        storage.setItem(storageKey, JSON.stringify(normalized))
      } catch (_) {}
      return normalized
    }
  }

  return Object.freeze({
    sanitizeCompleted,
    deriveUnlocked,
    normalizeProgress,
    normalizeStorage,
  })
})
