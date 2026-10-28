/*
 * Which translations a save will clear. The server drops a translation when its source text
 * changed and the translation is still the stored one (codecombat-server server/lib/stale-i18n.js);
 * the scenario editor lists them in the Save modal so the author knows to run AI Translate.
 */

/** A schema's translated fields: [{ path: ['actionData', 'choices', 0], props: ['text', 'responseText'] }], 0 for every array index. */
function translatedPaths (schema, path = [], paths = []) {
  if (!schema || typeof schema !== 'object') { return paths }
  for (const option of schema.oneOf || []) { translatedPaths(option, path, paths) }
  if (schema.properties && schema.properties.i18n && schema.properties.i18n.props) {
    paths.push({ path, props: schema.properties.i18n.props })
  }
  for (const key in schema.properties || {}) {
    if (key !== 'i18n') { translatedPaths(schema.properties[key], path.concat([key]), paths) }
  }
  if (schema.items) { translatedPaths(schema.items, path.concat([0]), paths) }
  return paths
}

// Each node a path names in next, paired with the node at the same place in prev.
function nodesAt (prev, next, path, at = []) {
  if (!next || typeof next !== 'object') { return [] }
  if (!path.length) { return [{ prev, next, at }] }
  const [segment, ...rest] = path
  if (segment === 0 && Array.isArray(next)) {
    return next.reduce((nodes, item, i) => nodes.concat(nodesAt(prev && prev[i], item, rest, at.concat([i]))), [])
  }
  return nodesAt(prev && prev[segment], next[segment], rest, at.concat([segment]))
}

const trimmed = value => (typeof value === 'string' ? value.trim() : '')

const translationOf = (item, lang, prop) => ((item.i18n || {})[lang] || {})[prop]

/**
 * What saving next over prev clears: [{ at: ['actionData', 'choices', 1], prop: 'responseText', langs: ['he'] }].
 * A stored translation goes with a changed source, unless a stored item had both (it moved with its text).
 */
function staleTranslations (prev, next, paths) {
  const stale = []
  if (!prev || !next) { return stale }
  for (const { path, props } of paths) {
    const stored = nodesAt(null, prev, path).map(node => node.next)
    for (const node of nodesAt(prev, next, path)) {
      const i18n = node.next.i18n
      if (!i18n || typeof i18n !== 'object') { continue }
      for (const prop of props) {
        const source = node.next[prop]
        if (typeof source !== 'string' || source.trim() === trimmed(node.prev && node.prev[prop])) { continue }
        const langs = Object.keys(i18n).filter(lang => {
          const translations = i18n[lang]
          if (!translations || typeof translations !== 'object' || !(prop in translations)) { return false }
          const storedWith = stored.filter(item => translationOf(item, lang, prop) === translations[prop])
          return storedWith.length > 0 && !storedWith.some(item => trimmed(item[prop]) === source.trim())
        })
        if (langs.length) { stale.push({ at: node.at, prop, langs }) }
      }
    }
  }
  return stale
}

module.exports = { translatedPaths, staleTranslations }
