/*
 * The cast and scenes a scenario's messages can reference, resolved the way
 * the story page resolves them (hackstack src/lib/story/resolve.ts): the
 * scenario's own lists first, then its world, then that world's parent, up to
 * the galaxy. A nearer definition of an id hides a farther one.
 */

const GALAXY_WORLD_SLUG = 'galaxy'
// scenario → planet → galaxy is the normal shape; anything deeper is a content mistake, not a feature.
const MAX_WORLD_CHAIN_DEPTH = 4

/**
 * Fetch the worlds a scenario inherits from, nearest first: parentWorld after
 * parentWorld (absent = galaxy), stopping at the galaxy, at a world that fails
 * to load (its slug comes back as `missing`), at MAX_WORLD_CHAIN_DEPTH and on
 * a repeated slug. Never rejects.
 * @param {string} [startSlug] the scenario's storyWorld; absent = galaxy
 * @param {Function} fetchJson core/api/fetch-json or a stand-in
 */
function loadWorldChain (startSlug, fetchJson) {
  const worlds = []
  const seen = []
  const next = slug => {
    if (!slug || seen.includes(slug) || seen.length >= MAX_WORLD_CHAIN_DEPTH) { return { worlds, missing: null } }
    seen.push(slug)
    return fetchJson(`/db/ai_story_world/${slug}`).then(world => {
      worlds.push(world)
      if (slug === GALAXY_WORLD_SLUG) { return { worlds, missing: null } }
      return next(world.parentWorld || GALAXY_WORLD_SLUG)
    }, () => ({ worlds, missing: slug }))
  }
  return Promise.resolve(next(startSlug || GALAXY_WORLD_SLUG))
}

// Entries of `list` across the scopes, nearest first; a repeated id keeps only its nearest entry.
function nearestFirst (scopes, list, pick) {
  const seen = {}
  const out = []
  for (const scope of scopes) {
    for (const entry of scope[list] || []) {
      if (!entry || !entry.id || seen[entry.id]) { continue }
      seen[entry.id] = true
      out.push(Object.assign(pick(entry), { source: scope.source }))
    }
  }
  return out
}

/**
 * What the Script tab offers for a step's speaker, objective and scene.
 * @param {Object} scenario plain scenario attributes (isStory, storyWorld, objectives, characters, backgrounds)
 * @param {{ worlds: Array<Object>, missing: string|null }} [chain] from loadWorldChain; absent while it loads
 */
function buildStoryContext (scenario, chain) {
  const worlds = (chain && chain.worlds) || []
  const scopes = [{ source: 'scenario', characters: scenario.characters, backgrounds: scenario.backgrounds }]
  for (const world of worlds) { scopes.push({ source: world.slug, characters: world.characters, backgrounds: world.backgrounds }) }
  const characters = nearestFirst(scopes, 'characters', c => ({ id: c.id, name: c.name || c.id, role: c.role }))
  const ally = characters.find(c => c.role === 'ally')
  return {
    isStory: Boolean(scenario.isStory),
    storyWorld: scenario.storyWorld || null,
    worldChain: worlds.map(w => w.slug),
    characters,
    objectives: (scenario.objectives || []).filter(o => o && o.id).map(o => ({
      id: o.id,
      text: o.text || '',
      kind: (o.completeOn && o.completeOn.kind) || null,
      hidden: Boolean(o.hidden),
    })),
    backgrounds: nearestFirst(scopes, 'backgrounds', b => ({ id: b.id })),
    defaultAlly: ally ? ally.id : null,
    missingWorld: (chain && chain.missing) || null,
  }
}

module.exports = { loadWorldChain, buildStoryContext, GALAXY_WORLD_SLUG, MAX_WORLD_CHAIN_DEPTH }
