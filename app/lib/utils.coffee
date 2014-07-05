module.exports.clone = (obj) ->
  return obj if obj is null or typeof (obj) isnt 'object'
  temp = obj.constructor()
  for key of obj
    temp[key] = module.exports.clone(obj[key])
  temp

module.exports.combineAncestralObject = (obj, propertyName) ->
  combined = {}
  while obj?[propertyName]
    for key, value of obj[propertyName]
      continue if combined[key]
      combined[key] = value
    if obj.__proto__
      obj = obj.__proto__
    else
      # IE has no __proto__. TODO: does this even work? At most it doesn't crash.
      obj = Object.getPrototypeOf(obj)
  combined

module.exports.normalizeFunc = (func_thing, object) ->
  # func could be a string to a function in this class
  # or a function in its own right
  object ?= {}
  if _.isString(func_thing)
    func = object[func_thing]
    if not func
      console.error "Could not find method #{func_thing} in object #{@}"
      return => null # always return a func, or Mediator will go boom
    func_thing = func
  return func_thing

module.exports.hexToHSL = (hex) ->
  rgbToHsl(hexToR(hex), hexToG(hex), hexToB(hex))

hexToR = (h) -> parseInt (cutHex(h)).substring(0, 2), 16
hexToG = (h) -> parseInt (cutHex(h)).substring(2, 4), 16
hexToB = (h) -> parseInt (cutHex(h)).substring(4, 6), 16
cutHex = (h) -> (if (h.charAt(0) is '#') then h.substring(1, 7) else h)

module.exports.hslToHex = (hsl) ->
  '#' + (toHex(n) for n in hslToRgb(hsl...)).join('')

toHex = (n) ->
  h = Math.floor(n).toString(16)
  h = '0'+h if h.length is 1
  h

module.exports.i18n = (say, target, language=me.lang(), fallback='en') ->
  generalResult = null
  fallbackResult = null
  fallforwardResult = null # If a general language isn't available, the first specific one will do
  matches = (/\w+/gi).exec(language)
  generalName = matches[0] if matches

  for localeName, locale of say.i18n
    if target of locale
      result = locale[target]
    else continue
    return result if localeName is language
    generalResult = result if localeName is generalName
    fallbackResult = result if localeName is fallback
    fallforwardResult = result if localeName.indexOf(language) is 0 and not fallforwardResult?

  return generalResult if generalResult?
  return fallforwardResult if fallforwardResult?
  return fallbackResult if fallbackResult?
  return say[target] if target of say
  null

module.exports.getByPath = (target, path) ->
  pieces = path.split('.')
  obj = target
  for piece in pieces
    return undefined unless piece of obj
    obj = obj[piece]
  obj

module.exports.round = _.curry (digits, n) ->
  n = +n.toFixed(digits)

positify = (func) -> (x) -> if x > 0 then func(x) else 0

# f(x) = ax + b
createLinearFunc = (params) ->
  (x) -> (params.a or 1) * x + (params.b or 0)

# f(x) = ax² + bx + c
createQuadraticFunc = (params) ->
  (x) -> (params.a or 1) * x * x + (params.b or 1) * x + (params.c or 0)

# f(x) = a log(b (x + c)) + d
createLogFunc = (params) ->
  (x) -> if x > 0 then (params.a or 1) * Math.log((params.b or 1) * (x + (params.c or 0))) + (params.d or 0) else 0

module.exports.functionCreators =
  linear: positify(createLinearFunc)
  quadratic: positify(createQuadraticFunc)
  logarithmic: positify(createLogFunc)
