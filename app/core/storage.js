// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Pass false for fromCache to fetch keys that have been stored outside of lscache.
module.exports.load = function (key, fromCache) {
  if (fromCache == null) { fromCache = true }
  if (fromCache) { return lscache.get(key) }
  const s = localStorage.getItem(key)
  if (!s) { return null }
  try {
    const value = JSON.parse(s)
    return value
  } catch (SyntaxError) {
    console.warn('error loading from storage', key)
    return null
  }
}

// Pass 0 for expirationInMinutes to persist it as long as possible outside of lscache expiration.
module.exports.save = function (key, value, expirationInMinutes) {
  if (expirationInMinutes == null) { expirationInMinutes = 7 * 24 * 60 }
  if (expirationInMinutes) {
    return lscache.set(key, value, expirationInMinutes)
  } else {
    return localStorage.setItem(key, JSON.stringify(value))
  }
}

// Pass false for fromCache to remove keys that have been stored outside of lscache.
module.exports.remove = function (key, fromCache) {
  if (fromCache == null) { fromCache = true }
  if (fromCache) {
    return lscache.remove(key)
  } else {
    return localStorage.removeItem(key)
  }
}
