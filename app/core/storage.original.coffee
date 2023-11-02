# Pass false for fromCache to fetch keys that have been stored outside of lscache.
module.exports.load = (key, fromCache=true) ->
  return lscache.get key if fromCache
  s = localStorage.getItem(key)
  return null unless s
  try
    value = JSON.parse(s)
    return value
  catch SyntaxError
    console.warn('error loading from storage', key)
    return null

# Pass 0 for expirationInMinutes to persist it as long as possible outside of lscache expiration.
module.exports.save = (key, value, expirationInMinutes) ->
  expirationInMinutes ?= 7 * 24 * 60
  if expirationInMinutes
    lscache.set key, value, expirationInMinutes
  else
    localStorage.setItem key, JSON.stringify(value)

# Pass false for fromCache to remove keys that have been stored outside of lscache.
module.exports.remove = (key, fromCache=true) ->
  if fromCache
    lscache.remove key
  else
    localStorage.removeItem key
