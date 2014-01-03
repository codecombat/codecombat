module.exports.loadObjectFromStorage = (key) ->
  s = localStorage.getItem(key)
  return null unless s
  try
    value = JSON.parse(s)
    return value
  catch SyntaxError
    console.warning('error loading from storage', key)
    return null

module.exports.saveObjectToStorage = (key, value) ->
  s = JSON.stringify(value)
  localStorage.setItem(key, s)