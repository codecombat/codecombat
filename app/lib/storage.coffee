module.exports.load = (key) ->
  s = localStorage.getItem(key)
  return null unless s
  try
    value = JSON.parse(s)
    return value
  catch SyntaxError
    console.warn('error loading from storage', key)
    return null

module.exports.save = (key, value) ->
  s = JSON.stringify(value)
  localStorage.setItem(key, s)

module.exports.remove = (key) -> localStorage.removeItem key
