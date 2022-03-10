slugify = _.str?.slugify ? _.string?.slugify # TODO: why _.string on client and _.str on server?

clone = (obj) ->
  return obj if obj is null or typeof (obj) isnt 'object'
  temp = obj.constructor()
  for key of obj
    temp[key] = clone(obj[key])
  temp

combineAncestralObject = (obj, propertyName) ->
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

countries = [
  {country: 'united-states', countryCode: 'US', ageOfConsent: 13, addressesIncludeAdministrativeRegion:true}
  {country: 'china', countryCode: 'CN', addressesIncludeAdministrativeRegion:true}
  {country: 'brazil', countryCode: 'BR'}

  # Loosely ordered by decreasing traffic as measured 2016-09-01 - 2016-11-07
  # TODO: switch to alphabetical ordering
  {country: 'united-kingdom', countryCode: 'GB', inEU: true, ageOfConsent: 13}
  {country: 'russia', countryCode: 'RU'}
  {country: 'australia', countryCode: 'AU', addressesIncludeAdministrativeRegion:true}
  {country: 'canada', countryCode: 'CA', addressesIncludeAdministrativeRegion:true}
  {country: 'france', countryCode: 'FR', inEU: true, ageOfConsent: 15}
  {country: 'taiwan', countryCode: 'TW'}
  {country: 'ukraine', countryCode: 'UA'}
  {country: 'poland', countryCode: 'PL', inEU: true, ageOfConsent: 13}
  {country: 'spain', countryCode: 'ES', inEU: true, ageOfConsent: 13}
  {country: 'germany', countryCode: 'DE', inEU: true, ageOfConsent: 16}
  {country: 'netherlands', countryCode: 'NL', inEU: true, ageOfConsent: 16}
  {country: 'hungary', countryCode: 'HU', inEU: true, ageOfConsent: 16}
  {country: 'japan', countryCode: 'JP'}
  {country: 'turkey', countryCode: 'TR'}
  {country: 'south-africa', countryCode: 'ZA'}
  {country: 'indonesia', countryCode: 'ID'}
  {country: 'new-zealand', countryCode: 'NZ'}
  {country: 'finland', countryCode: 'FI', inEU: true, ageOfConsent: 13}
  {country: 'south-korea', countryCode: 'KR'}
  {country: 'mexico', countryCode: 'MX', addressesIncludeAdministrativeRegion:true}
  {country: 'vietnam', countryCode: 'VN'}
  {country: 'singapore', countryCode: 'SG'}
  {country: 'colombia', countryCode: 'CO'}
  {country: 'india', countryCode: 'IN', addressesIncludeAdministrativeRegion:true}
  {country: 'thailand', countryCode: 'TH'}
  {country: 'belgium', countryCode: 'BE', inEU: true, ageOfConsent: 13}
  {country: 'sweden', countryCode: 'SE', inEU: true, ageOfConsent: 13}
  {country: 'denmark', countryCode: 'DK', inEU: true, ageOfConsent: 13}
  {country: 'czech-republic', countryCode: 'CZ', inEU: true, ageOfConsent: 15}
  {country: 'hong-kong', countryCode: 'HK'}
  {country: 'italy', countryCode: 'IT', inEU: true, ageOfConsent: 16, addressesIncludeAdministrativeRegion:true}
  {country: 'romania', countryCode: 'RO', inEU: true, ageOfConsent: 16}
  {country: 'belarus', countryCode: 'BY'}
  {country: 'norway', countryCode: 'NO', inEU: true, ageOfConsent: 13}  # GDPR applies to EFTA
  {country: 'philippines', countryCode: 'PH'}
  {country: 'lithuania', countryCode: 'LT', inEU: true, ageOfConsent: 16}
  {country: 'argentina', countryCode: 'AR'}
  {country: 'malaysia', countryCode: 'MY', addressesIncludeAdministrativeRegion:true}
  {country: 'pakistan', countryCode: 'PK'}
  {country: 'serbia', countryCode: 'RS'}
  {country: 'greece', countryCode: 'GR', inEU: true, ageOfConsent: 15}
  {country: 'israel', countryCode: 'IL', inEU: true}
  {country: 'portugal', countryCode: 'PT', inEU: true, ageOfConsent: 13}
  {country: 'slovakia', countryCode: 'SK', inEU: true, ageOfConsent: 16}
  {country: 'ireland', countryCode: 'IE', inEU: true, ageOfConsent: 16}
  {country: 'switzerland', countryCode: 'CH', inEU: true, ageOfConsent: 16}  # GDPR applies to EFTA
  {country: 'peru', countryCode: 'PE'}
  {country: 'bulgaria', countryCode: 'BG', inEU: true, ageOfConsent: 14}
  {country: 'venezuela', countryCode: 'VE'}
  {country: 'austria', countryCode: 'AT', inEU: true, ageOfConsent: 14}
  {country: 'croatia', countryCode: 'HR', inEU: true, ageOfConsent: 16}
  {country: 'saudia-arabia', countryCode: 'SA'}
  {country: 'chile', countryCode: 'CL'}
  {country: 'united-arab-emirates', countryCode: 'AE'}
  {country: 'kazakhstan', countryCode: 'KZ'}
  {country: 'estonia', countryCode: 'EE', inEU: true, ageOfConsent: 13}
  {country: 'iran', countryCode: 'IR'}
  {country: 'egypt', countryCode: 'EG'}
  {country: 'ecuador', countryCode: 'EC'}
  {country: 'slovenia', countryCode: 'SI', inEU: true, ageOfConsent: 15}
  {country: 'macedonia', countryCode: 'MK'}
  {country: 'cyprus', countryCode: 'CY', inEU: true, ageOfConsent: 14}
  {country: 'latvia', countryCode: 'LV', inEU: true, ageOfConsent: 13}
  {country: 'luxembourg', countryCode: 'LU', inEU: true, ageOfConsent: 16}
  {country: 'malta', countryCode: 'MT', inEU: true, ageOfConsent: 16}
  {country: 'lichtenstein', countryCode: 'LI', inEU: true}  # GDPR applies to EFTA
  {country: 'iceland', countryCode: 'IS', inEU: true}  # GDPR applies to EFTA
]

inEU = (country) -> !!_.find(countries, (c) => c.country is slugify(country))?.inEU

addressesIncludeAdministrativeRegion = (country) -> !!_.find(countries, (c) => c.country is slugify(country))?.addressesIncludeAdministrativeRegion

ageOfConsent = (countryName, defaultIfUnknown=0) ->
  return defaultIfUnknown unless countryName
  country = _.find(countries, (c) => c.country is slugify(countryName))
  return defaultIfUnknown unless country
  return country.ageOfConsent if country.ageOfConsent
  return 16 if country.inEU
  return defaultIfUnknown

countryCodeToFlagEmoji = (code) ->
  return code unless code?.length is 2
  (String.fromCodePoint(c.charCodeAt() + 0x1F1A5) for c in code.toUpperCase()).join('')

countryCodeToName = (code) ->
  return code unless code?.length is 2
  return code unless country = _.find countries, countryCode: code.toUpperCase()
  titleize country.country

titleize = (s) ->
  # Turns things like 'dungeons-of-kithgard' into 'Dungeons of Kithgard'
  _.string.titleize(_.string.humanize(s)).replace(/ (and|or|but|nor|yet|so|for|a|an|the|in|to|of|at|by|up|for|off|on|with|from)(?= )/ig, (word) => word.toLowerCase())

campaignIDs =
  INTRO: '55b29efd1cd6abe8ce07db0d'

freeCampaignIds = [campaignIDs.INTRO] # CS1 campaign
internalCampaignIds = [] # Ozaria has one of these, CoCo doesn't

courseIDs =
  INTRODUCTION_TO_COMPUTER_SCIENCE: '560f1a9f22961295f9427742'
  GAME_DEVELOPMENT_1: '5789587aad86a6efb573701e'
  WEB_DEVELOPMENT_1: '5789587aad86a6efb573701f'
  COMPUTER_SCIENCE_2: '5632661322961295f9428638'
  GAME_DEVELOPMENT_2: '57b621e7ad86a6efb5737e64'
  WEB_DEVELOPMENT_2: '5789587aad86a6efb5737020'
  COMPUTER_SCIENCE_3: '56462f935afde0c6fd30fc8c'
  GAME_DEVELOPMENT_3: '5a0df02b8f2391437740f74f'
  COMPUTER_SCIENCE_4: '56462f935afde0c6fd30fc8d'
  COMPUTER_SCIENCE_5: '569ed916efa72b0ced971447'
  COMPUTER_SCIENCE_6: '5817d673e85d1220db624ca4'

CSCourseIDs = [
  courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE
  courseIDs.COMPUTER_SCIENCE_2
  courseIDs.COMPUTER_SCIENCE_3
  courseIDs.COMPUTER_SCIENCE_4
  courseIDs.COMPUTER_SCIENCE_5
  courseIDs.COMPUTER_SCIENCE_6
]
WDCourseIDs = [
  courseIDs.WEB_DEVELOPMENT_1
  courseIDs.WEB_DEVELOPMENT_2
]
orderedCourseIDs = [
  courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE
  courseIDs.GAME_DEVELOPMENT_1
  courseIDs.WEB_DEVELOPMENT_1
  courseIDs.COMPUTER_SCIENCE_2
  courseIDs.GAME_DEVELOPMENT_2
  courseIDs.WEB_DEVELOPMENT_2
  courseIDs.COMPUTER_SCIENCE_3
  courseIDs.GAME_DEVELOPMENT_3
  courseIDs.COMPUTER_SCIENCE_4
  courseIDs.COMPUTER_SCIENCE_5
  courseIDs.COMPUTER_SCIENCE_6
]

courseNumericalStatus = {}
courseNumericalStatus['NO_ACCESS'] = 0
courseNumericalStatus[courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE] = 1
courseNumericalStatus[courseIDs.GAME_DEVELOPMENT_1] = 2
courseNumericalStatus[courseIDs.WEB_DEVELOPMENT_1] = 4
courseNumericalStatus[courseIDs.COMPUTER_SCIENCE_2] = 8
courseNumericalStatus[courseIDs.GAME_DEVELOPMENT_2] = 16
courseNumericalStatus[courseIDs.WEB_DEVELOPMENT_2] = 32
courseNumericalStatus[courseIDs.COMPUTER_SCIENCE_3] = 64
courseNumericalStatus[courseIDs.GAME_DEVELOPMENT_3] = 128
courseNumericalStatus[courseIDs.COMPUTER_SCIENCE_4] = 256
courseNumericalStatus[courseIDs.COMPUTER_SCIENCE_5] = 512
courseNumericalStatus[courseIDs.COMPUTER_SCIENCE_6] = 1024
courseNumericalStatus['FULL_ACCESS'] = 2047


courseAcronyms = {}
courseAcronyms[courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE] = 'CS1'
courseAcronyms[courseIDs.GAME_DEVELOPMENT_1] = 'GD1'
courseAcronyms[courseIDs.WEB_DEVELOPMENT_1] = 'WD1'
courseAcronyms[courseIDs.COMPUTER_SCIENCE_2] = 'CS2'
courseAcronyms[courseIDs.GAME_DEVELOPMENT_2] = 'GD2'
courseAcronyms[courseIDs.WEB_DEVELOPMENT_2] = 'WD2'
courseAcronyms[courseIDs.COMPUTER_SCIENCE_3] = 'CS3'
courseAcronyms[courseIDs.GAME_DEVELOPMENT_3] = 'GD3'
courseAcronyms[courseIDs.COMPUTER_SCIENCE_4] = 'CS4'
courseAcronyms[courseIDs.COMPUTER_SCIENCE_5] = 'CS5'
courseAcronyms[courseIDs.COMPUTER_SCIENCE_6] = 'CS6'

courseLessonSlidesURLs = {}
unless features?.china
  courseLessonSlidesURLs[courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE] = 'https://drive.google.com/drive/folders/1YU7LEZ6TLQzbAsSMw90nNJfvU7gDrcid?usp=sharing'
  courseLessonSlidesURLs[courseIDs.COMPUTER_SCIENCE_2] = 'https://drive.google.com/drive/folders/1x24P6ZY_MBOBoHvlikbDr7jvMPYVRVkJ?usp=sharing'
  courseLessonSlidesURLs[courseIDs.COMPUTER_SCIENCE_3] = 'https://drive.google.com/drive/folders/1hBl-h5Xvo5chYH4q9e6IEo42JozlrTG9?usp=sharing'
  courseLessonSlidesURLs[courseIDs.COMPUTER_SCIENCE_4] = 'https://drive.google.com/drive/folders/1tbuE4Xn0ahJ0xcF1-OaiPs9lHeIs9zqG?usp=sharing'
  courseLessonSlidesURLs[courseIDs.COMPUTER_SCIENCE_5] = 'https://drive.google.com/drive/folders/1ThxWFZjoXzU5INtMzlqKEn8xkgHhVnl4?usp=sharing'
  courseLessonSlidesURLs[courseIDs.GAME_DEVELOPMENT_1] = 'https://drive.google.com/drive/folders/1YSJ9wcfHRJ2854F-vUdSWqoLBuSJye7V?usp=sharing'
  courseLessonSlidesURLs[courseIDs.GAME_DEVELOPMENT_2] = 'https://drive.google.com/drive/folders/1Mks2MA-WGMrwNpZj6VtKkL3loPnHp_bs?usp=sharing'

petThangIDs = [
  '578d320d15e2501f00a585bd' # Wolf Pup
  '5744e3683af6bf590cd27371' # Cougar
  '5786a472a6c64135009238d3' # Raven
  '577d5d4dab818b210046b3bf' # Pugicorn
  '58c74b7c3d4a3d2900d43b7e' # Brown Rat
  '58c7614a62cc3a1f00442240' # Yetibab
  '58a262520b43652f00dad75e' # Phoenix
  '57869cf7bd31c14400834028' # Frog
  '578691f9bd31c1440083251d' # Polar Bear Cub
  '58a2712b0b43652f00dae5a4' # Blue Fox
  '58c737140ca7852e005deb8a' # Mimic
  '57586f0a22179b2800efda37' # Baby Griffin
]

premiumContent =
  premiumHeroesCount: '15'
  totalHeroesCount: '19'
  premiumLevelsCount: '531'
  freeLevelsCount: '5'

normalizeFunc = (func_thing, object) ->
  # func could be a string to a function in this class
  # or a function in its own right
  object ?= {}
  if _.isString(func_thing)
    func = object[func_thing]
    if not func
      console.error "Could not find method #{func_thing} in object", object
      return => null # always return a func, or Mediator will go boom
    func_thing = func
  return func_thing

objectIdToDate = (objectID) ->
  new Date(parseInt(objectID.toString().slice(0,8), 16)*1000)

hexToHSL = (hex) ->
  rgbToHsl(hexToR(hex), hexToG(hex), hexToB(hex))

hexToR = (h) -> parseInt (cutHex(h)).substring(0, 2), 16
hexToG = (h) -> parseInt (cutHex(h)).substring(2, 4), 16
hexToB = (h) -> parseInt (cutHex(h)).substring(4, 6), 16
cutHex = (h) -> (if (h.charAt(0) is '#') then h.substring(1, 7) else h)

hslToHex = (hsl) ->
  '#' + (toHex(n) for n in hslToRgb(hsl...)).join('')

toHex = (n) ->
  h = Math.floor(n).toString(16)
  h = '0'+h if h.length is 1
  h

pathToUrl = (path) ->
  base = location.protocol + '//' + location.hostname + (location.port && ":" + location.port)
  base + path

extractPlayerCodeTag = (code) ->
  unwrappedDefaultCode = code.match(/<playercode>\n([\s\S]*)\n *<\/playercode>/)?[1]
  if unwrappedDefaultCode
    return stripIndentation(unwrappedDefaultCode)
  else
    return undefined

stripIndentation = (code) ->
  codeLines = code.split('\n')
  indentation = _.min(_.filter(codeLines.map (line) -> line.match(/^\s*/)?[0]?.length))
  strippedCode = (line.substr(indentation) for line in codeLines).join('\n')
  return strippedCode

# @param {Object} say - the object containing an i18n property.
# @param {string} target - the attribute that you want to access.
# @returns {string} translated string if possible
# Example usage:
#   `courseName = utils.i18n(course.attributes, 'name')`
i18n = (say, target, language=me.get('preferredLanguage', true), fallback='en') ->
  generalResult = null
  fallBackResult = null
  fallForwardResult = null  # If a general language isn't available, the first specific one will do.
  fallSidewaysResult = null  # If a specific language isn't available, its sibling specific language will do.
  matches = (/\w+/gi).exec(language)
  generalName = matches[0] if matches

  # Lets us safely attempt to translate undefined objects
  return say?[target] unless say?.i18n

  for localeName, locale of say.i18n
    continue if localeName is '-'
    if target of locale
      result = locale[target]
    else continue
    return result if localeName is language
    generalResult = result if localeName is generalName
    fallBackResult = result if localeName is fallback
    fallForwardResult = result if localeName.indexOf(language) is 0 and not fallForwardResult?
    fallSidewaysResult = result if localeName.indexOf(generalName) is 0 and not fallSidewaysResult?

  return generalResult if generalResult?
  return fallForwardResult if fallForwardResult?
  return fallSidewaysResult if fallSidewaysResult?
  return fallBackResult if fallBackResult?
  return say[target] if target of say
  null

getByPath = (target, path) ->
  throw new Error 'Expected an object to match a query against, instead got null' unless target
  pieces = path.split('.')
  obj = target
  for piece in pieces
    return undefined unless piece of obj
    obj = obj[piece]
  obj

isID = (id) -> _.isString(id) and id.length is 24 and id.match(/[a-f0-9]/gi)?.length is 24

isIE = -> $?.browser?.msie ? false

isRegionalSubscription = (name) -> /_basic_subscription/.test(name)

isSmokeTestEmail = (email) ->
  /@example.com/.test(email) or /smoketest/.test(email)

round = _.curry (digits, n) ->
  n = +n.toFixed(digits)

positify = (func) -> (params) -> (x) -> if x > 0 then func(params)(x) else 0

# f(x) = ax + b
createLinearFunc = (params) ->
  (x) -> (params.a or 1) * x + (params.b or 0)

# f(x) = ax² + bx + c
createQuadraticFunc = (params) ->
  (x) -> (params.a or 1) * x * x + (params.b or 1) * x + (params.c or 0)

# f(x) = a log(b (x + c)) + d
createLogFunc = (params) ->
  (x) -> if x > 0 then (params.a or 1) * Math.log((params.b or 1) * (x + (params.c or 0))) + (params.d or 0) else 0

# f(x) = ax^b + c
createPowFunc = (params) ->
  (x) -> (params.a or 1) * Math.pow(x, params.b or 1) + (params.c or 0)

functionCreators =
  linear: positify(createLinearFunc)
  quadratic: positify(createQuadraticFunc)
  logarithmic: positify(createLogFunc)
  pow: positify(createPowFunc)

# Call done with true to satisfy the 'until' goal and stop repeating func
keepDoingUntil = (func, wait=100, totalWait=5000) ->
  waitSoFar = 0
  (done = (success) ->
    if (waitSoFar += wait) <= totalWait and not success
      _.delay (-> func done), wait) false

grayscale = (imageData) ->
  d = imageData.data
  for i in [0..d.length] by 4
    r = d[i]
    g = d[i+1]
    b = d[i+2]
    v = 0.2126*r + 0.7152*g + 0.0722*b
    d[i] = d[i+1] = d[i+2] = v
  imageData

# Deep compares l with r, with the exception that undefined values are considered equal to missing values
# Very practical for comparing Mongoose documents where undefined is not allowed, instead fields get deleted
kindaEqual = compare = (l, r) ->
  if _.isObject(l) and _.isObject(r)
    for key in _.union Object.keys(l), Object.keys(r)
      return false unless compare l[key], r[key]
    return true
  else if l is r
    return true
  else
    return false

# Return UTC string "YYYYMMDD" for today + offset
getUTCDay = (offset=0) ->
  day = new Date()
  day.setDate(day.getUTCDate() + offset)
  partYear = day.getUTCFullYear()
  partMonth = (day.getUTCMonth() + 1)
  partMonth = "0" + partMonth if partMonth < 10
  partDay = day.getUTCDate()
  partDay = "0" + partDay if partDay < 10
  "#{partYear}#{partMonth}#{partDay}"

# Fast, basic way to replace text in an element when you don't need much.
# http://stackoverflow.com/a/4962398/540620
if document?.createElement
  dummy = document.createElement 'div'
  dummy.innerHTML = 'text'
  TEXT = if dummy.textContent is 'text' then 'textContent' else 'innerText'
  replaceText = (elems, text) ->
    elem[TEXT] = text for elem in elems
    null

# Add a stylesheet rule
# http://stackoverflow.com/questions/524696/how-to-create-a-style-tag-with-javascript/26230472#26230472
# Don't use wantonly, or we'll have to implement a simple mechanism for clearing out old rules.
if document?.createElement
  injectCSS = ((doc) ->
    # wrapper for all injected styles and temp el to create them
    wrap = doc.createElement("div")
    temp = doc.createElement("div")
    # rules like "a {color: red}" etc.
    return (cssRules) ->
      # append wrapper to the body on the first call
      unless wrap.id
        wrap.id = "injected-css"
        wrap.style.display = "none"
        doc.body.appendChild wrap
      # <br> for IE: http://goo.gl/vLY4x7
      temp.innerHTML = "<br><style>" + cssRules + "</style>"
      wrap.appendChild temp.children[1]
      return
  )(document)

# So that we can stub out userAgent in tests
userAgent = ->
  window.navigator.userAgent

getDocumentSearchString = ->
  # moved to a separate function so it can be mocked for testing
  return document.location.search

getQueryVariables = ->
  query = module.exports.getDocumentSearchString().substring(1) # use module.exports so spy is used in testing
  pairs = (pair.split('=') for pair in query.split '&')
  variables = {}
  for [key, value] in pairs
    variables[key] = {'true': true, 'false': false}[value] ? decodeURIComponent(value)
  return variables

getQueryVariable = (param, defaultValue) ->
  variables = getQueryVariables()
  return variables[param] ? defaultValue

getSponsoredSubsAmount = (price=999, subCount=0, personalSub=false) ->
  # 1 100%
  # 2-11 80%
  # 12+ 60%
  # TODO: make this less confusing
  return 0 unless subCount > 0
  offset = if personalSub then 1 else 0
  if subCount <= 1 - offset
    price
  else if subCount <= 11 - offset
    Math.round((1 - offset) * price + (subCount - 1 + offset) * price * 0.8)
  else
    Math.round((1 - offset) * price + 10 * price * 0.8 + (subCount - 11 + offset) * price * 0.6)

getCourseBundlePrice = (coursePrices, seats=20) ->
  totalPricePerSeat = coursePrices.reduce ((a, b) -> a + b), 0
  if coursePrices.length > 2
    pricePerSeat = Math.round(totalPricePerSeat / 2.0)
  else
    pricePerSeat = parseInt(totalPricePerSeat)
  seats * pricePerSeat

getCoursePraise = ->
  praise = [
    {
      quote:  "The kids love it."
      source: "Leo Joseph Tran, Athlos Leadership Academy"
    },
    {
      quote: "My students have been using the site for a couple of weeks and they love it."
      source: "Scott Hatfield, Computer Applications Teacher, School Technology Coordinator, Eastside Middle School"
    },
    {
      quote: "Thanks for the captivating site. My eighth graders love it."
      source: "Janet Cook, Ansbach Middle/High School"
    },
    {
      quote: "My students have started working on CodeCombat and love it! I love that they are learning coding and problem solving skills without them even knowing it!!"
      source: "Kristin Huff, Special Education Teacher, Webb City School District"
    },
    {
      quote: "I recently introduced Code Combat to a few of my fifth graders and they are loving it!"
      source: "Shauna Hamman, Fifth Grade Teacher, Four Peaks Elementary School"
    },
    {
      quote: "Overall I think it's a fantastic service. Variables, arrays, loops, all covered in very fun and imaginative ways. Every kid who has tried it is a fan."
      source: "Aibinder Andrew, Technology Teacher"
    },
    {
      quote: "I love what you have created. The kids are so engaged."
      source: "Desmond Smith, 4KS Academy"
    },
    {
      quote: "My students love the website and I hope on having content structured around it in the near future."
      source: "Michael Leonard, Science Teacher, Clearwater Central Catholic High School"
    }
  ]
  praise[_.random(0, praise.length - 1)]

getPrepaidCodeAmount = (price=0, users=0, months=0) ->
  return 0 unless users > 0 and months > 0
  total = price * users * months
  total

formatDollarValue = (dollars) ->
  '$' + (parseFloat(dollars).toFixed(2))

capitalLanguages =
  'javascript': 'JavaScript'
  'coffeescript': 'CoffeeScript'
  'python': 'Python'
  'java': 'Java'
  'cpp': 'C++'
  'lua': 'Lua'
  'html': 'HTML'

createLevelNumberMap = (levels) ->
  levelNumberMap = {}
  practiceLevelTotalCount = 0
  practiceLevelCurrentCount = 0
  for level, i in levels
    levelNumber = i - practiceLevelTotalCount + 1
    if level.practice
      levelNumber = i - practiceLevelTotalCount + String.fromCharCode('a'.charCodeAt(0) + practiceLevelCurrentCount)
      practiceLevelTotalCount++
      practiceLevelCurrentCount++
    else if level.assessment
      practiceLevelTotalCount++
      practiceLevelCurrentCount++
      levelNumber = if level.assessment is 'cumulative' then $.t('play_level.combo_challenge') else $.t('play_level.concept_challenge')
    else
      practiceLevelCurrentCount = 0
    levelNumberMap[level.key] = levelNumber
  levelNumberMap

findNextLevel = (levels, currentIndex, needsPractice) ->
  # Find next available incomplete level, depending on whether practice is needed
  # levels = [{practice: true/false, complete: true/false, assessment: true/false, locked: true/false}]
  # Skip over assessment levels
  # return -1 if at or beyond locked level
  return -1 for i in [0..currentIndex] when levels[i].locked
  index = currentIndex
  index++
  if needsPractice
    if levels[currentIndex].practice or index < levels.length and levels[index].practice
      # Needs practice, current level is practice or next is practice; return the next incomplete practice-or-normal level
      # May leave earlier practice levels incomplete and reach end of course
      while index < levels.length and (levels[index].complete or levels[index].assessment)
        return -1 if levels[index].locked
        index++
    else
      # Needs practice, current level is required, next level is required or assessment; return the first incomplete level of previous practice chain
      index--
      index-- while index >= 0 and not levels[index].practice
      if index >= 0
        index-- while index >= 0 and levels[index].practice
        if index >= 0
          index++
          index++ while index < levels.length and levels[index].practice and levels[index].complete
          if levels[index].practice and not levels[index].complete
            return index
      # Last set of practice levels is complete; return the next incomplete normal level instead.
      index = currentIndex + 1
      while index < levels.length and (levels[index].complete or levels[index].assessment)
        return -1 if levels[index].locked
        index++
  else
    # No practice needed; return the next required incomplete level
    while index < levels.length and (levels[index].practice or levels[index].complete or levels[index].assessment)
      return -1 if levels[index].locked
      index++
  index

findNextAssessmentForLevel = (levels, currentIndex, needsPractice) ->
  # Find assessment level immediately after current level (and its practice levels)
  # Only return assessment if it's the next level
  # Skip over practice levels unless practice neeeded
  # levels = [{practice: true/false, complete: true/false, assessment: true/false, locked: true/false}]
  # eg: l*,p,p,a*,a',l,...
  # given index l*, return index a*
  # given index a*, return index a'
  index = currentIndex
  index++
  while index < levels.length
    if levels[index].practice
      return -1 if needsPractice and not levels[index].complete
      index++ # It's a practice level but do not need practice, keep looking
    else if levels[index].assessment
      return -1 if levels[index].complete
      return index
    else if levels[index].complete # It's completed, keep looking
      index++
    else # we got to a normal level; we didn't find an assessment for the given level.
      return -1
  return -1 # we got to the end of the list and found nothing

needsPractice = (playtime=0, threshold=5) ->
  playtime / 60 > threshold

sortCourses = (courses) ->
  _.sortBy courses, (course) ->
    # ._id can be from classroom.courses, otherwise it's probably .id
    index = orderedCourseIDs.indexOf(course.id ? course._id)
    index = 9001 if index is -1
    index

sortCoursesByAcronyms = (courses) ->
  orderedCourseAcronyms = _.sortBy(courseAcronyms)
  _.sortBy courses, (course) ->
    # ._id can be from classroom.courses, otherwise it's probably .id
    index = orderedCourseAcronyms.indexOf(courseAcronyms[course.id ? course._id])
    index = 9001 if index is -1
    index

usStateCodes =
  # https://github.com/mdzhang/us-state-codes
  # generated by js2coffee 2.2.0
  (->
    stateNamesByCode =
      'AL': 'Alabama'
      'AK': 'Alaska'
      'AZ': 'Arizona'
      'AR': 'Arkansas'
      'CA': 'California'
      'CO': 'Colorado'
      'CT': 'Connecticut'
      'DE': 'Delaware'
      'DC': 'District of Columbia'
      'FL': 'Florida'
      'GA': 'Georgia'
      'HI': 'Hawaii'
      'ID': 'Idaho'
      'IL': 'Illinois'
      'IN': 'Indiana'
      'IA': 'Iowa'
      'KS': 'Kansas'
      'KY': 'Kentucky'
      'LA': 'Louisiana'
      'ME': 'Maine'
      'MD': 'Maryland'
      'MA': 'Massachusetts'
      'MI': 'Michigan'
      'MN': 'Minnesota'
      'MS': 'Mississippi'
      'MO': 'Missouri'
      'MT': 'Montana'
      'NE': 'Nebraska'
      'NV': 'Nevada'
      'NH': 'New Hampshire'
      'NJ': 'New Jersey'
      'NM': 'New Mexico'
      'NY': 'New York'
      'NC': 'North Carolina'
      'ND': 'North Dakota'
      'OH': 'Ohio'
      'OK': 'Oklahoma'
      'OR': 'Oregon'
      'PA': 'Pennsylvania'
      'RI': 'Rhode Island'
      'SC': 'South Carolina'
      'SD': 'South Dakota'
      'TN': 'Tennessee'
      'TX': 'Texas'
      'UT': 'Utah'
      'VT': 'Vermont'
      'VA': 'Virginia'
      'WA': 'Washington'
      'WV': 'West Virginia'
      'WI': 'Wisconsin'
      'WY': 'Wyoming'
    stateCodesByName = _.invert(stateNamesByCode)
    # normalizes case and removes invalid characters
    # returns null if can't find sanitized code in the state map

    sanitizeStateCode = (code) ->
      code = if _.isString(code) then code.trim().toUpperCase().replace(/[^A-Z]/g, '') else null
      if stateNamesByCode[code] then code else null

    # returns a valid state name else null

    getStateNameByStateCode = (code) ->
      stateNamesByCode[sanitizeStateCode(code)] or null

    # normalizes case and removes invalid characters
    # returns null if can't find sanitized name in the state map

    sanitizeStateName = (name) ->
      if !_.isString(name)
        return null
      # bad whitespace remains bad whitespace e.g. "O  hi o" is not valid
      name = name.trim().toLowerCase().replace(/[^a-z\s]/g, '').replace(/\s+/g, ' ')
      tokens = name.split(/\s+/)
      tokens = _.map(tokens, (token) ->
        token.charAt(0).toUpperCase() + token.slice(1)
      )
      # account for District of Columbia
      if tokens.length > 2
        tokens[1] = tokens[1].toLowerCase()
      name = tokens.join(' ')
      if stateCodesByName[name] then name else null

    # returns a valid state code else null

    getStateCodeByStateName = (name) ->
      stateCodesByName[sanitizeStateName(name)] or null

    return {
      sanitizeStateCode: sanitizeStateCode
      getStateNameByStateCode: getStateNameByStateCode
      sanitizeStateName: sanitizeStateName
      getStateCodeByStateName: getStateCodeByStateName
    }
  )()

emailRegex = /[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-z]{2,63}/
isValidEmail = (email) ->
  emailRegex.test(email?.trim().toLowerCase())

formatStudentLicenseStatusDate = (status, date) ->
    string = switch status
      when 'not-enrolled' then $.i18n.t('teacher.status_not_enrolled')
      when 'enrolled' then (if date then $.i18n.t('teacher.status_enrolled') else '-')
      when 'expired' then $.i18n.t('teacher.status_expired')
    string.replace('{{date}}', date or 'Never')

formatStudentSingleLicenseStatusDate = (product) ->
  string = $.i18n.t('teacher.full_license')
  if product.productOptions?.includedCourseIDs?
    string = product.productOptions.includedCourseIDs.map((id) -> courseAcronyms[id]).join('+')
  string += ': ' + moment(product.endDate).format('ll')

getApiClientIdFromEmail = (email) ->
  if /@codeninjas.com$/i.test(email) # hard coded for code ninjas since a lot of their users do not have clientCreator set
    clientID = '57fff652b0783842003fed00'
    return clientID

# hard-coded 3 CS1 levels with concept video details
# TODO: move them to database if more such levels
videoLevels = {
  # gems in the deep
  "54173c90844506ae0195a0b4": {
    i18name: 'basic_syntax',
    url: "https://iframe.videodelivery.net/d9a73d2f2d3d8de2e5e86203af47e20c?defaultTextTrack=en",
    cn_url: "https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE01-%E5%9F%BA%E6%9C%AC%E8%AF%AD%E6%B3%95-Codecombat%20Instruction%20for%20Teachers.mp4",
    title: "Basic Syntax",
    original: "54173c90844506ae0195a0b4",
    thumbnail_locked: "/images/level/videos/basic_syntax_locked.png",
    thumbnail_unlocked: "/images/level/videos/basic_syntax_unlocked.png"
  },
  # fire dancing
  "55ca293b9bc1892c835b0136": {
    i18name: 'while_loops',
    url: "https://iframe.videodelivery.net/1cec5da9a56cd42ade2906cd03c0b82b?defaultTextTrack=en",
    cn_url: "https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE03-CodeCombat%E6%95%99%E5%AD%A6%E5%AF%BC%E8%AF%BE-CS1-%E5%BE%AA%E7%8E%AFlogo.mp4",
    title: "While Loops",
    original: "55ca293b9bc1892c835b0136"
    thumbnail_locked: "/images/level/videos/while_loops_locked.png",
    thumbnail_unlocked: "/images/level/videos/while_loops_unlocked.png"
  }
  # known enemy
  "5452adea57e83800009730ee": {
    i18name: 'variables',
    url: "https://iframe.videodelivery.net/239838623c19b13437705ebe69929031?defaultTextTrack=en",
    cn_url: "https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE02-%E5%8F%98%E9%87%8F-CodeCombat-CS1-%E5%8F%98%E9%87%8Flogo.mp4",
    title: "Variables",
    original: "5452adea57e83800009730ee"
    thumbnail_locked: "/images/level/videos/variables_locked.png",
    thumbnail_unlocked: "/images/level/videos/variables_unlocked.png"
  }
}

# Adds a `Vue.nonreactive` global method that can be used
# to prevent Vue traversing our large and expensive game objects.
# Reference Library: https://github.com/rpkilby/vue-nonreactive
vueNonReactiveInstall = (Vue) ->
    Observer = (new Vue())
      .$data
      .__ob__
      .constructor

    Vue.nonreactive = (value) ->
      # Vue sees the noop Observer and stops traversing the structure.
      value.__ob__ = new Observer({});
      return value;

yearsSinceMonth = (birth, now) ->
  return undefined unless birth
  # Should probably review this logic, written quickly and haven't tested any edge cases
  if _.isString birth
    return undefined unless /^\d{4}-\d{1,2}(-\d{1,2})?$/.test birth
    if birth.split('-').length is 2
      birth = birth + '-28'  # Assume near the end of the month, don't let timezones mess it up, skew younger in interpretation
    dates = birth.split('-')
    birth = new Date(+dates[0], +dates[1]-1, +dates[2])
  return undefined unless _.isDate birth

  birthYear = birth.getFullYear()
  birthYear += 1 if birth.getMonth() > 7 # getMonth start from 0 # child birth after 9.1 should join school in next year
  season = currentSeason()
  now ?= new Date()
  schoolYear = now.getFullYear()

  seasonAfterSep = +(season.start.split('-')[0]) >= 9
  schoolYear += 1 if seasonAfterSep # school year comes into a new year after 9.1
  return schoolYear - birthYear

# Keep in sync with the copy in background-processor
ageBrackets = [
  {slug: '0-11', max: 11}
  {slug: '11-14', max: 14}
  {slug: '14-18', max: 18}
  {slug: 'open', max: 9001}
]

ageBracketsChina = [
  {slug: '0-11', max: 11}
  {slug: '11-18', max: 18}
  {slug: 'open', max: 9001}
]

seasons = [
  {
    name: 'Season 1',
    start:'01-01',
    end: '04-30',
  }
  {
    name: 'Season 2',
    start:'05-01',
    end: '08-31',
  }
  {
    name: 'Season 3',
    start:'09-01',
    end: '12-31',
  }
]

currentSeason = () ->
  now = new Date()
  year = now.getFullYear()
  return seasons.find((season) ->
    dates = season.end.split('-')
    now < new Date(year, +dates[0]-1, dates[1]).setHours(24, 0, 0, 0)
  )

ageToBracket = (age) ->
# Convert years to an age bracket
  return 'open' unless age
  for bracket in ageBrackets
    if age <= bracket.max
      return bracket.slug
  return 'open'

bracketToAge = (slug) ->
  for i in [0...ageBrackets.length]
    if ageBrackets[i].slug == slug
      lowerBound = if i == 0 then 0 else ageBrackets[i-1].max
      higherBound = ageBrackets[i].max
      return { $gt: lowerBound, $lte: higherBound }

  for i in [0...ageBracketsChina.length]
    if ageBracketsChina[i].slug == slug
      lowerBound = if i == 0 then 0 else ageBracketsChina[i-1].max
      higherBound = ageBracketsChina[i].max
      return { $gt: lowerBound, $lte: higherBound }


CODECOMBAT = 'codecombat'
CODECOMBAT_CHINA = 'koudashijie'
OZARIA = 'ozaria'
OZARIA_CHINA = 'aojiarui'

isOldBrowser = () ->
  if features.china and $.browser
    return true if not ($.browser.webkit or $.browser.mozilla or $.browser.msedge)
    majorVersion = $.browser.versionNumber
    return true if $.browser.mozilla && majorVersion < 25
    return true if $.browser.chrome && majorVersion < 72  # forbid some chinese browser
    return true if $.browser.safari && majorVersion < 6  # 6 might have problems with Aether, or maybe just old minors of 6: https://errorception.com/projects/51a79585ee207206390002a2/errors/547a202e1ead63ba4e4ac9fd
  return false

isCodeCombat = true
isOzaria = false

arenas = [
  {slug: 'blazing-battle'   , type: 'regular',      start: new Date("2021-01-01T00:00:00.000-07:00"), end: new Date("2021-05-01T00:00:00.000-08:00"), results: new Date("2021-05-01T00:00:00.000-08:00"), levelOriginal: '5fca06dc8b4da8002889dbf1', tournament: '608cea0f8f2b971478556ac6', image: '/file/db/level/5fca06dc8b4da8002889dbf1/Blazing Battle Final cut.jpg'}
  {slug: 'infinite-inferno' , type: 'championship', start: new Date("2021-04-01T00:00:00.000-08:00"), end: new Date("2021-05-01T00:00:00.000-08:00"), results: new Date("2021-05-01T00:00:00.000-08:00"), levelOriginal: '602cdc204ef0480075fbd954', tournament: '608cd3f814fa0bf9f1c1f928', image: '/file/db/level/602cdc204ef0480075fbd954/InfiniteInferno_Banner_Final.jpg'}
  {slug: 'mages-might'      , type: 'regular',      start: new Date("2021-05-01T00:00:00.000-08:00"), end: new Date("2021-09-01T00:00:00.000-08:00"), results: new Date("2021-09-08T09:00:00.000-08:00"), levelOriginal: '6066f956ddfd6f003d1ed6bb', tournament: '612d554b9abe2e0019aeffb9', image: '/file/db/level/6066f956ddfd6f003d1ed6bb/Mages\'%20Might%20Banner.jpg'}
  {slug: 'sorcerers'        , type: 'championship', start: new Date("2021-08-01T00:00:00.000-08:00"), end: new Date("2021-09-01T00:00:00.000-08:00"), results: new Date("2021-09-08T09:00:00.000-08:00"), levelOriginal: '609a6ad2e1eb34001a84e7af', tournament: '612d556f9abe2e0019af000b', image: "/file/db/level/609a6ad2e1eb34001a84e7af/Sorcerer's-Blitz-01.jpg"}
  {slug: 'giants-gate'      , type: 'regular',      start: new Date("2021-09-01T00:00:00.000-08:00"), end: new Date("2021-12-15T00:00:00.000-07:00"), results: new Date("2021-12-21T09:00:00.000-07:00"), levelOriginal: '60e69b24bed8ae001ac6ce3e', tournament: '6136a86e0c0ecaf34e431e81', image: "/file/db/level/60e69b24bed8ae001ac6ce3e/Giant’s-Gate-Final.jpg"}
  {slug: 'colossus'         , type: 'championship', start: new Date("2021-11-19T00:00:00.000-07:00"), end: new Date("2021-12-15T00:00:00.000-07:00"), results: new Date("2021-12-21T09:00:00.000-07:00"), levelOriginal: '615ffaf2b20b4900280e0070', tournament: '61983f74fd75db5e28ac127a', image: "/file/db/level/615ffaf2b20b4900280e0070/Colossus-Clash-02.jpg"}
  {slug: 'iron-and-ice'     , type: 'regular',      start: new Date("2021-12-15T00:00:00.000-07:00"), end: new Date("2022-05-01T00:00:00.000-08:00"), results: new Date("2022-05-06T09:00:00.000-08:00"), levelOriginal: '618a5a13994545008d2d4990',                                         image: "file/db/level/618a5a13994545008d2d4990/Iron-and-Ice-Arena-Banner-02.jpg"}
  {slug: 'tundra-tower'     , type: 'championship', start: new Date("2021-04-01T00:00:00.000-08:00"), end: new Date("2022-05-01T00:00:00.000-08:00"), results: new Date("2022-05-06T09:00:00.000-08:00"), levelOriginal: '620cb80a9bc0f1005e9189d7'}
 #{slug: 'desert-duel'      , type: 'regular',      start: new Date("2022-05-01T00:00:00.000-08:00"), end: new Date("2022-09-01T00:00:00.000-08:00"), results: new Date("2022-09-08T09:00:00.000-08:00"), levelOriginal: ''}
 #{slug: 'sandstorm'        , type: 'championship', start: new Date("2022-08-01T00:00:00.000-08:00"), end: new Date("2022-09-01T00:00:00.000-08:00"), results: new Date("2022-09-08T09:00:00.000-08:00"), levelOriginal: ''}
 #{slug: 'magma-mountain'   , type: 'regular',      start: new Date("2022-09-01T00:00:00.000-08:00"), end: new Date("2023-01-01T00:00:00.000-07:00"), results: new Date("2023-01-10T09:00:00.000-07:00"), levelOriginal: ''}
 #{slug: 'lava-lake'        , type: 'championship', start: new Date("2022-12-01T00:00:00.000-07:00"), end: new Date("2023-01-01T00:00:00.000-07:00"), results: new Date("2023-01-10T09:00:00.000-07:00"), levelOriginal: ''}
]

activeArenas = ->
  daysActiveAfterEnd = regular: 7, championship: 14
  (_.clone(a) for a in arenas when a.start <= new Date() < a.end.getTime() + daysActiveAfterEnd[a.type] * 86400 * 1000)

activeAndPastArenas = -> (_.clone(a) for a in arenas when a.start <= new Date())

teamSpells = humans: ['hero-placeholder/plan'], ogres: ['hero-placeholder-1/plan']

clanHeroes = [
  {clanId: '601351bb4b79b4013e198fbe', clanSlug: 'team-derbezt', thangTypeOriginal: '6037ed81ad0ac000f5e9f0b5', thangTypeSlug: 'armando-hoyos'}
  {clanId: '6137aab4e0bae40025bed266', clanSlug: 'team-ned', thangTypeOriginal: '6136fe7e9f1147002c1316b4', thangTypeSlug: 'ned-fulmer'}
]

freeAccessLevels = [
  { access: 'short', slug: 'dungeons-of-kithgard' }
  { access: 'short', slug: 'gems-in-the-deep' }
  { access: 'short', slug: 'shadow-guard' }
  { access: 'short', slug: 'signs-and-portents' }  # Retroactively unlocks later on, doesn't really impact much
  { access: 'short', slug: 'enemy-mine' }
  { access: 'short', slug: 'true-names' }
  { access: 'medium', slug: 'cell-commentary' }
  { access: 'medium', slug: 'the-raised-sword' }
  { access: 'medium', slug: 'kithgard-librarian' }
  { access: 'medium', slug: 'the-prisoner' }
  { access: 'medium', slug: 'fire-dancing' }
  { access: 'medium', slug: 'haunted-kithmaze' }
  { access: 'medium', slug: 'descending-further' }
  { access: 'medium', slug: 'dread-door' }
  { access: 'long', slug: 'hack-and-dash' }
  { access: 'long', slug: 'cupboards-of-kithgard' }
  { access: 'long', slug: 'known-enemy' }
  { access: 'long', slug: 'master-of-names' }
  { access: 'long', slug: 'the-final-kithmaze' }
  { access: 'long', slug: 'kithgard-gates' }
  { access: 'extended', slug: 'defense-of-plainswood' }
  { access: 'extended', slug: 'winding-trail' }
  { access: 'china-classroom', slug: 'forgetful-gemsmith' }
  { access: 'china-classroom', slug: 'kounter-kithwise' }
  { access: 'china-classroom', slug: 'crawlways-of-kithgard' }
  { access: 'china-classroom', slug: 'illusory-interruption' }
  { access: 'china-classroom', slug: 'careful-steps' }
  { access: 'china-classroom', slug: 'long-steps' }
  { access: 'china-classroom', slug: 'favorable-odds' }
]

orgKindString = (kind, org=null) ->
  return 'State' if kind is 'administrative-region' and org?.country is 'US' and /^en/.test me.get('preferredLanguage')
  key = {
    'administrative-region': 'teachers_quote.state'
    'school-district': 'teachers_quote.district_label'
    'school-admin': 'outcomes.school_admin'
    'school-network': 'outcomes.school_network'
    'school-subnetwork': 'outcomes.school_subnetwork'
    school: 'teachers_quote.organization_label'
    teacher: 'courses.teacher'
    classroom: 'outcomes.classroom'
    student: 'courses.student'
  }[kind]
  return $.i18n.t(key)

module.exports = {
  activeAndPastArenas
  activeArenas
  addressesIncludeAdministrativeRegion
  ageBrackets
  ageBracketsChina
  ageOfConsent
  ageToBracket
  arenas
  bracketToAge
  campaignIDs
  capitalLanguages
  clanHeroes
  clone
  combineAncestralObject
  countries
  countryCodeToFlagEmoji
  countryCodeToName
  courseAcronyms
  courseIDs
  courseLessonSlidesURLs
  courseNumericalStatus
  CSCourseIDs
  WDCourseIDs
  createLevelNumberMap
  extractPlayerCodeTag
  freeAccessLevels
  findNextAssessmentForLevel
  findNextLevel
  formatDollarValue
  formatStudentLicenseStatusDate
  formatStudentSingleLicenseStatusDate
  freeCampaignIds
  functionCreators
  getApiClientIdFromEmail
  getByPath
  getCourseBundlePrice
  getCoursePraise
  getDocumentSearchString
  getPrepaidCodeAmount
  getQueryVariable
  getQueryVariables
  getSponsoredSubsAmount
  getUTCDay
  grayscale
  hexToHSL
  hslToHex
  i18n
  inEU
  injectCSS
  internalCampaignIds
  isID
  isIE
  isRegionalSubscription
  isSmokeTestEmail
  isValidEmail
  keepDoingUntil
  kindaEqual
  needsPractice
  normalizeFunc
  objectIdToDate
  orderedCourseIDs
  orgKindString
  pathToUrl
  petThangIDs
  premiumContent
  replaceText
  round
  sortCourses
  sortCoursesByAcronyms
  stripIndentation
  teamSpells
  titleize
  usStateCodes
  userAgent
  videoLevels
  vueNonReactiveInstall
  yearsSinceMonth
  CODECOMBAT
  OZARIA
  CODECOMBAT_CHINA
  OZARIA_CHINA
  isOldBrowser
  isCodeCombat
  isOzaria
}
