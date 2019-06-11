/* eslint-env jasmine */
import { findNextLevelsBySession } from 'ozaria/site/common/ozariaUtils'
import factories from 'test/app/factories'
import Levels from 'collections/Levels'

function makeLevels (numberOfLevels) {
  const levels = new Levels(_.times(numberOfLevels, () => factories.makeLevel()))
  // set position, nextLevels, and first property
  for (let [index, level] of levels.models.entries()) {
    level.set('position', { x: (index + 1) * 10, y: 20 })
    let nextLevel = {}
    if (index + 1 < levels.models.length) {
      const nextLevelData = levels.models[index + 1]
      nextLevel[nextLevelData.get('original')] = {
        original: nextLevelData.get('original'),
        name: nextLevelData.get('name'),
        slug: nextLevelData.get('slug')
      }
    }
    level.set('nextLevels', nextLevel)
    if (index === 0) {
      level.set('first', true)
    }
  }
  return levels.models
}

/**
 * creates 4 levels with second level as the level played in stages
 * the next levels store the information about capstone stage
 */
function makeLevelsForCapstoneFlow () {
  const levels = new Levels(_.times(4, () => factories.makeLevel()))
  // set position, nextLevels, and first property
  let nextLevelStage = 1
  for (let [index, level] of levels.models.entries()) {
    level.set('position', { x: (index + 1) * 10, y: 20 })
    let nextLevel = {}
    if (index === 1) {
      const firstNextLevelData = levels.models[2]
      nextLevel[firstNextLevelData.get('original')] = {
        original: firstNextLevelData.get('original'),
        name: firstNextLevelData.get('name'),
        slug: firstNextLevelData.get('slug'),
        conditions: {
          afterCapstoneStage: 1
        }
      }
      const secondNextLevelData = levels.models[3]
      nextLevel[secondNextLevelData.get('original')] = {
        original: secondNextLevelData.get('original'),
        name: secondNextLevelData.get('name'),
        slug: secondNextLevelData.get('slug'),
        conditions: {
          afterCapstoneStage: 2
        }
      }
      level.set('isPlayedInStages', true)
    } else {
      const nextLevelData = levels.models[1]
      nextLevel[nextLevelData.get('original')] = {
        original: nextLevelData.get('original'),
        name: nextLevelData.get('name'),
        slug: nextLevelData.get('slug'),
        nextLevelStage: nextLevelStage
      }
      nextLevelStage++
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
  describe('findNextLevelsBySession returns the next level original id for a given list of levels based on level sessions', () => {
    beforeEach(() => {
      me.set(factories.makeUser().attributes)
    })

    // c:completed, *:current level (not completed), n:not started (no level session), <number>:current capstone stage(for levels played in stages)

    it('for levels that are cc*n', () => {
      const levels = makeLevels(4)
      const sessions = makeLevelSessions(levels, [{ complete: true }, { complete: true }, { complete: false }])
      const expectedNextLevel = levels[2]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })

    it('for levels that are *nnn', () => {
      const levels = makeLevels(4)
      const sessions = makeLevelSessions(levels, [{ complete: false }])
      const expectedNextLevel = levels[0]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })

    it('for levels that are nnnn', () => {
      const levels = makeLevels(4)
      const sessions = makeLevelSessions(levels, [])
      const expectedNextLevel = levels.find((l) => l.get('first')) // first level will be next level
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })

    it('for capstone played in stages: c1nn', () => {
      const levels = makeLevelsForCapstoneFlow()
      const sessions = makeLevelSessions(levels, [{ complete: true }, { complete: false }]) // capstoneStage is undefined when playing stage 1
      const expectedNextLevel = levels[1]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })

    it('for capstone played in stages: c2nn', () => {
      const levels = makeLevelsForCapstoneFlow()
      const sessions = makeLevelSessions(levels, [{ complete: true }, { capstoneStage: 2 }])
      const expectedNextLevel = levels[2]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })

    it('for capstone played in stages: c2cn', () => {
      const levels = makeLevelsForCapstoneFlow()
      const sessions = makeLevelSessions(levels, [{ complete: true }, { capstoneStage: 2 }, { complete: true }])
      const expectedNextLevel = levels[1] // next level should be capstone level
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })

    it('for capstone played in stages: c3cn', () => {
      const levels = makeLevelsForCapstoneFlow()
      const sessions = makeLevelSessions(levels, [{ complete: true }, { capstoneStage: 3 }, { complete: true }])
      const expectedNextLevel = levels[3]
      const nextLevelOriginal = findNextLevelsBySession(sessions, levels)
      expect(nextLevelOriginal).toBeDefined()
      expect(nextLevelOriginal).toEqual(expectedNextLevel.get('original'))
    })
  })
})
