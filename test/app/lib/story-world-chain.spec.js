const { loadWorldChain, buildStoryContext } = require('lib/story-world-chain')

// A stand-in for core/api/fetch-json over GET /db/ai_story_world/:slug; unknown slugs reject like the server's 404.
function makeFetch (worlds) {
  const calls = []
  const fetchJson = url => {
    calls.push(url)
    const slug = url.split('/').pop()
    if (worlds[slug]) { return Promise.resolve(JSON.parse(JSON.stringify(worlds[slug]))) }
    return Promise.reject({ code: 404, message: 'Document not found.' }) // eslint-disable-line prefer-promise-reject-errors
  }
  fetchJson.calls = calls
  return fetchJson
}

const galaxy = {
  slug: 'galaxy',
  characters: [{ id: 'hq', name: 'HQ', role: 'ally' }, { id: 'hackstack', name: 'HackStack', role: 'hackstack' }, { id: 'you', name: 'You', role: 'player' }],
  backgrounds: [{ id: 'bridge', image: 'bridge.png' }],
}
const planet = { slug: 'hour-of-ai', characters: [{ id: 'local', name: 'Local', role: 'npc' }], backgrounds: [{ id: 'camp', image: 'camp.png' }] }

describe('lib/story-world-chain', function () {
  describe('loadWorldChain', function () {
    it('follows parentWorld to the galaxy, nearest first, and reads an absent parent as the galaxy', function (done) {
      const fetchJson = makeFetch({ galaxy, 'hour-of-ai': planet })
      loadWorldChain('hour-of-ai', fetchJson).then(chain => {
        expect(chain.worlds.map(w => w.slug)).toEqual(['hour-of-ai', 'galaxy'])
        expect(chain.missing).toBe(null)
        expect(fetchJson.calls).toEqual(['/db/ai_story_world/hour-of-ai', '/db/ai_story_world/galaxy'])
      }).then(done, done.fail)
    })

    it('starts at the galaxy when the scenario names no world', function (done) {
      const fetchJson = makeFetch({ galaxy })
      loadWorldChain(undefined, fetchJson).then(chain => {
        expect(chain.worlds.map(w => w.slug)).toEqual(['galaxy'])
        expect(fetchJson.calls.length).toBe(1)
      }).then(done, done.fail)
    })

    it('stops at a world that fails to load and names it', function (done) {
      const fetchJson = makeFetch({ galaxy, 'hour-of-ai': Object.assign({}, planet, { parentWorld: 'lost' }) })
      loadWorldChain('hour-of-ai', fetchJson).then(chain => {
        expect(chain.worlds.map(w => w.slug)).toEqual(['hour-of-ai'])
        expect(chain.missing).toBe('lost')
        return loadWorldChain('nowhere', fetchJson)
      }).then(chain => {
        expect(chain.worlds).toEqual([])
        expect(chain.missing).toBe('nowhere')
      }).then(done, done.fail)
    })

    it('stops at depth 4 and on a cycle', function (done) {
      const deep = {}
      for (const [slug, parent] of [['a', 'b'], ['b', 'c'], ['c', 'd'], ['d', 'e'], ['e', 'galaxy']]) { deep[slug] = { slug, parentWorld: parent } }
      const loop = { x: { slug: 'x', parentWorld: 'y' }, y: { slug: 'y', parentWorld: 'x' } }
      loadWorldChain('a', makeFetch(Object.assign({ galaxy }, deep))).then(chain => {
        expect(chain.worlds.map(w => w.slug)).toEqual(['a', 'b', 'c', 'd'])
        expect(chain.missing).toBe(null)
        return loadWorldChain('x', makeFetch(loop))
      }).then(chain => {
        expect(chain.worlds.map(w => w.slug)).toEqual(['x', 'y'])
        expect(chain.missing).toBe(null)
      }).then(done, done.fail)
    })
  })

  describe('buildStoryContext', function () {
    const chain = { worlds: [planet, galaxy], missing: null }

    it('lists the cast and scenes nearest first, a nearer id hiding the farther one', function () {
      const scenario = {
        isStory: true,
        storyWorld: 'hour-of-ai',
        characters: [{ id: 'hq', name: 'Captain', role: 'npc' }, { id: 'guide', name: 'Guide', role: 'ally' }],
        backgrounds: [{ id: 'camp', image: 'night-camp.png' }],
        objectives: [{ id: 'recolor', text: 'Change the star' }, { text: 'no id' }],
      }
      const context = buildStoryContext(scenario, chain)
      expect(context.isStory).toBe(true)
      expect(context.storyWorld).toBe('hour-of-ai')
      expect(context.worldChain).toEqual(['hour-of-ai', 'galaxy'])
      expect(context.characters).toEqual([
        { id: 'hq', name: 'Captain', role: 'npc', source: 'scenario' },
        { id: 'guide', name: 'Guide', role: 'ally', source: 'scenario' },
        { id: 'local', name: 'Local', role: 'npc', source: 'hour-of-ai' },
        { id: 'hackstack', name: 'HackStack', role: 'hackstack', source: 'galaxy' },
        { id: 'you', name: 'You', role: 'player', source: 'galaxy' },
      ])
      expect(context.defaultAlly).toBe('guide')
      expect(context.backgrounds).toEqual([{ id: 'camp', source: 'scenario' }, { id: 'bridge', source: 'galaxy' }])
      expect(context.objectives).toEqual([{ id: 'recolor', text: 'Change the star', kind: null, hidden: false }])
      expect(context.missingWorld).toBe(null)
    })

    it('carries what completes each objective and whether it is hidden', function () {
      const objectives = [{ id: 'gift', text: 'Make a gift', completeOn: { kind: 'prompt-replied' }, hidden: true }, { id: 'a', text: 'A', completeOn: {} }]
      expect(buildStoryContext({ objectives }, chain).objectives).toEqual([
        { id: 'gift', text: 'Make a gift', kind: 'prompt-replied', hidden: true },
        { id: 'a', text: 'A', kind: null, hidden: false },
      ])
    })

    it('falls back to the galaxy ally and copes with no chain yet or a missing world', function () {
      const bare = buildStoryContext({}, null)
      expect(bare).toEqual({ isStory: false, storyWorld: null, worldChain: [], characters: [], objectives: [], backgrounds: [], defaultAlly: null, missingWorld: null })
      const context = buildStoryContext({ storyWorld: 'hour-of-ai' }, chain)
      expect(context.defaultAlly).toBe('hq')
      expect(context.characters[0].name).toBe('Local')
      const broken = buildStoryContext({ storyWorld: 'lost' }, { worlds: [], missing: 'lost' })
      expect(broken.missingWorld).toBe('lost')
      expect(broken.defaultAlly).toBe(null)
    })
  })
})
