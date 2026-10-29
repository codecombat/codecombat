/*
 * Which version of a scenario the editor edits. GET /db/ai_scenario/<handle> returns the exact
 * document an id names, and a scenario's original id is the _id of its v0.0, so an original-id
 * link (a scenario node's "(e)", a Slack save link) opened v0.0, and a save from there made the
 * content of v0.0 the latest version. A slug resolves to the latest. ?version=M.m opens exactly
 * that version, which is how Version history reaches v0.0.
 */

const VERSION_RE = /^\d+\.\d+$/

/** '?version=0.3' gives '0.3'; absent or malformed gives null. */
function versionFromSearch (search) {
  const match = /[?&]version=([^&#]*)/.exec(search || '')
  if (!match) { return null }
  let version
  try { version = decodeURIComponent(match[1]) } catch (e) { return null } // a stray % in the query
  return VERSION_RE.test(version) ? version : null
}

/** '0.3' for a document with a version, null without one. */
function versionLabel (doc) {
  const version = doc && doc.version
  return version && typeof version.major === 'number' && typeof version.minor === 'number' ? `${version.major}.${version.minor}` : null
}

// An id handle may be typed in any case; the server answers with the canonical lowercase hex.
const OBJECT_ID_RE = /^[0-9a-f]{24}$/i
const sameHandle = (a, b) => (OBJECT_ID_RE.test(String(a)) ? String(a).toLowerCase() === String(b).toLowerCase() : String(a) === String(b))

/**
 * After the handle loaded a document, what the editor should edit instead of it:
 *   'latest'  the handle is the original id (so the document is v0.0) and no version was asked for
 *   'exact'   ?version names a version other than the loaded one
 *   null      the loaded document: a slug, a version's own id, or ?version naming it
 */
function resolveVersion ({ handle, loaded, version }) {
  if (!loaded) { return null }
  if (version) { return versionLabel(loaded) === version ? null : 'exact' }
  return loaded.original && sameHandle(handle, loaded.original) ? 'latest' : null
}

/** True when the document shown is not the scenario's latest version. */
function isStale (doc, latest) {
  return Boolean(doc && latest && doc._id && latest._id && String(doc._id) !== String(latest._id))
}

/**
 * The editor URL for a document: its slug, or without one its original id (which the editor
 * opens as the latest), plus ?version only when that exact version is meant.
 */
function editUrl (doc, version) {
  return `/editor/ai-scenario/${doc.slug || doc.original || doc._id}${version ? `?version=${version}` : ''}`
}

module.exports = { versionFromSearch, versionLabel, resolveVersion, isStale, editUrl }
