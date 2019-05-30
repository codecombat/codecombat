/* eslint-env jasmine */
import { findNextLevelsBySession } from 'ozaria/site/common/ozariaUtils'
import factories from 'test/app/factories'
import Levels from 'collections/Levels'

function makeLevels (numberOfLevels) {
  const levels = new Levels(_.times(numberOfLevels, () => factories.makeLevel()))
  // set position, nextLevels, and first property
  for (let [index, level] of levels.models.entries()) {
    level.set('position', { x: (index + 1) * 10, y: 20 })
    let nextLevel = []
    if (index + 1 < levels.models.length) {
      nextLevel.push({
        levelOriginal: levels.models[index + 1].get('original')
      })
    }
    level.set('nextLevels', nextLevel)
    if (index === 0) {
      level.set('first', true)
    }
  }
  return levels.models
}

// `levels` is an array of level objects
// `state` is an array containing level session state for the level in the `levels` array at that index.
// if length of `states` is 3 and length of `levels` is 4, then 4th level doesnt have a level session
function makeLevelSessions (levels, state) {
  const sessions = []
  for (let i = 0; i < state.length; i++) {
    sessions.push(factories.makeLevelSession({ state: state[i] }, { level: levels[i], creator: me }))
  }
  return sessions // array of session objects
}

describe('ozaria utilities', () => {
  describe('findNextLevelsBySession returns an array of next level original ids for a given list of levels based on level sessions', () => {
    beforeEach(() => {
      me.set(factories.makeUser().attributes)
    })

    // c:completed, *:current level (not completed), n:not started (no level session)

    it('for levels that are cc*n', () => {
      const levels = makeLevels(4)
      const sessions = makeLevelSessions(levels, [{ complete: true }, { complete: true }, { complete: false }])
      const expectedNextLevel = levels[2]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal.length).toBe(1)
      expect(nextLevelOriginal[0]).toEqual(expectedNextLevel.get('original'))
    })

    it('for levels that are *nnn', () => {
      const levels = makeLevels(4)
      const sessions = makeLevelSessions(levels, [{ complete: false }])
      const expectedNextLevel = levels[0]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal.length).toBe(1)
      expect(nextLevelOriginal[0]).toEqual(expectedNextLevel.get('original'))
    })

    it('for levels that are nnnn', () => {
      const levels = makeLevels(4)
      const sessions = makeLevelSessions(levels, [])
      const expectedNextLevel = levels.find((l) => l.get('first')) // first level will be next level
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal.length).toBe(1)
      expect(nextLevelOriginal[0]).toEqual(expectedNextLevel.get('original'))
    })
  })
})
