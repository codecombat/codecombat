slugify = require('underscore.string').slugify # TODO: why _.string on client and _.str on server?

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
  {country: 'united-states', countryCode: 'US', ageOfConsent: 13}
  {country: 'china', countryCode: 'CN'}
  {country: 'brazil', countryCode: 'BR'}

  # Loosely ordered by decreasing traffic as measured 2016-09-01 - 2016-11-07
  # TODO: switch to alphabetical ordering
  {country: 'united-kingdom', countryCode: 'GB', inEU: true, ageOfConsent: 13}
  {country: 'russia', countryCode: 'RU'}
  {country: 'australia', countryCode: 'AU'}
  {country: 'canada', countryCode: 'CA'}
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
  {country: 'mexico', countryCode: 'MX'}
  {country: 'vietnam', countryCode: 'VN'}
  {country: 'singapore', countryCode: 'SG'}
  {country: 'colombia', countryCode: 'CO'}
  {country: 'india', countryCode: 'IN'}
  {country: 'thailand', countryCode: 'TH'}
  {country: 'belgium', countryCode: 'BE', inEU: true, ageOfConsent: 13}
  {country: 'sweden', countryCode: 'SE', inEU: true, ageOfConsent: 13}
  {country: 'denmark', countryCode: 'DK', inEU: true, ageOfConsent: 13}
  {country: 'czech-republic', countryCode: 'CZ', inEU: true, ageOfConsent: 15}
  {country: 'hong-kong', countryCode: 'HK'}
  {country: 'italy', countryCode: 'IT', inEU: true, ageOfConsent: 16}
  {country: 'romania', countryCode: 'RO', inEU: true, ageOfConsent: 16}
  {country: 'belarus', countryCode: 'BY'}
  {country: 'norway', countryCode: 'NO', inEU: true, ageOfConsent: 13}  # GDPR applies to EFTA
  {country: 'philippines', countryCode: 'PH'}
  {country: 'lithuania', countryCode: 'LT', inEU: true, ageOfConsent: 16}
  {country: 'argentina', countryCode: 'AR'}
  {country: 'malaysia', countryCode: 'MY'}
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

freeCampaignIds = ['5d1a8368abd38e8b5363bad9'] # CH1 campaign
internalCampaignIds = ['5eb34fc8dc0fd35e8eae66b0'] # CH2 playtest

courseIDs =
  CHAPTER_ONE: '5d41d731a8d1836b5aa3cba1'
  CHAPTER_TWO: '5d8a57abe8919b28d5113af1'
  CHAPTER_TWO_PLAYTEST: '5eb34fc8dc0fd35e8eae66b0'
  CHAPTER_THREE: '5e27600d1c9d440000ac3ee7'
  CHAPTER_FOUR: '5f0cb0b7a2492bba0b3520df'

orderedCourseIDs = [
  courseIDs.CHAPTER_ONE
  courseIDs.CHAPTER_TWO
  courseIDs.CHAPTER_TWO_PLAYTEST
  courseIDs.CHAPTER_THREE
  courseIDs.CHAPTER_FOUR
]

courseAcronyms = {}
courseAcronyms[courseIDs.CHAPTER_ONE] = 'CH1'
courseAcronyms[courseIDs.CHAPTER_TWO] = 'CH2'
courseAcronyms[courseIDs.CHAPTER_TWO_PLAYTEST] = 'CH2P'
courseAcronyms[courseIDs.CHAPTER_THREE] = 'CH3'
courseAcronyms[courseIDs.CHAPTER_FOUR] = 'CH4'

# Harcoding module names for simplicity
# Use db to store these later when we add sophisticated module functionality, right now its only used for UI
courseModules = {}
courseModules[courseIDs.CHAPTER_ONE] = {
  '1': 'Introduction to Coding'
}
courseModules[courseIDs.CHAPTER_TWO] = {
  '1': 'Algorithms and Syntax',
  '2': 'Debugging',
  '3': 'Variables',
  '4': 'Conditionals',
  '5': 'Capstone Intro',
  '6': 'Capstone Project'
}
courseModules[courseIDs.CHAPTER_TWO_PLAYTEST] = {
  '1': 'Algorithms and Syntax',
  '2': 'Debugging',
  '3': 'Variables',
  '4': 'Conditionals',
  '5': 'Capstone Intro',
  '6': 'Capstone Project'
}
courseModules[courseIDs.CHAPTER_THREE] = {
  '1': 'Review',
  '2': 'For Loops',
  '3': 'Nesting',
  '4': 'While Loops',
  '5': 'Capstone'
}
courseModules[courseIDs.CHAPTER_FOUR] = {
  '1': 'Compound Conditionals',
  '2': 'Functions and Data Analysis',
  '3': 'Writing Functions',
  '4': 'Capstone'
}

hourOfCodeOptions = {
  campaignId: freeCampaignIds[0],
  courseId: courseIDs.CHAPTER_ONE,
  name: 'Chapter 1: Up The Mountain',
  progressModalAfter: 1500000 #25 mins
}

registerHocProgressModalCheck = ->
  hocProgressModalCheck = setInterval(() =>
    if window.sessionStorage?.getItem('hoc_progress_modal_time') < new Date().getTime()
      window.sessionStorage.setItem('show_hoc_progress_modal', true)
      window.sessionStorage.removeItem('hoc_progress_modal_time')
      clearInterval(hocProgressModalCheck)
  , 60000) # every 1 min

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
  premiumHeroesCount: '12'
  totalHeroesCount: '16'
  premiumLevelsCount: '330'
  freeLevelsCount: '100'

# group course/campaign levels by module number
buildLevelsListByModule = (levels, isCh1=false) ->
  Level = require('models/Level')
  levelsModuleMap = {}
  # Find the intro before the last capstone stage for CH1
  # since CH1 capstone needs to be placed after that in the levels list
  if isCh1 && levels.find((l) => l.isCapstone())
    capstoneOriginal = levels.find((l) => l.isCapstone()).get('original')
    totalCapstoneStages = 10 # Hardcoding the num of stages since its not available in level data, TODO refactor later
    if capstoneOriginal
      introBeforeLastCapstoneStage = levels.find((l) =>
        nextLevel = Object.values(l.get('nextLevels') || {})[0] || {}
        return nextLevel.original == capstoneOriginal && nextLevel.nextLevelStage == totalCapstoneStages
      )
      introBeforeLastCapstoneStageOriginal = introBeforeLastCapstoneStage?.get('original')
  capstoneLevel = {}
  levels.forEach((l) =>
    moduleNumber = l.get('moduleNum') || 1
    if isCh1 && l.isCapstone()
      capstoneLevel = new Level(l.attributes)
    else
      levelsModuleMap[moduleNumber] ?= []
      levelsModuleMap[moduleNumber].push(l)
      if isCh1 && introBeforeLastCapstoneStageOriginal && l.get('original') == introBeforeLastCapstoneStageOriginal
        levelsModuleMap[moduleNumber].push(capstoneLevel)
  )
  return levelsModuleMap

# adds displayName and learning goals from intro levels content to the intro level given
addIntroLevelContent = (introLevel, introLevelsContent) ->
  if introLevel.get('type') == 'intro' && (introLevel.get('introContent') || []).length > 0 && introLevelsContent
    introLevel.get('introContent').forEach((c) =>
      return if c.type == 'avatarSelectionScreen'
      if typeof c.contentId is 'object' # contentId can be an object if interactive is different for python/js
        # for simplicity, assuming that the display name/learning goals will be same for a given interactive in python/js
        introLevelData = introLevelsContent[c.contentId.python] || {}
      else
        introLevelData = introLevelsContent[c.contentId] || {}
      c.displayName = i18n(introLevelData, 'displayName') || i18n(introLevelData, 'name')
      learningGoals = ((introLevelData.documentation || {}).specificArticles || []).find((a) => a.name == 'Learning Goals')
      if learningGoals
        c.learningGoals = i18n(learningGoals, 'body')
    )

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

startsWithVowel = (s) -> s[0] in 'aeiouAEIOU'

filterMarkdownCodeLanguages = (text, language) ->
  return '' unless text
  currentLanguage = language or me.get('aceConfig')?.language or 'python'
  excludedLanguages = _.without ['javascript', 'python', 'coffeescript', 'clojure', 'lua', 'java', 'io', 'html'], currentLanguage
  # Exclude language-specific code blocks like ```python (... code ...)``` for each non-target language.
  codeBlockExclusionRegex = new RegExp "```(#{excludedLanguages.join('|')})\n[^`]+```\n?", 'gm'
  # Exclude language-specific images like ![python - image description](image url) for each non-target language.
  imageExclusionRegex = new RegExp "!\\[(#{excludedLanguages.join('|')}) - .+?\\]\\(.+?\\)\n?", 'gm'
  text = text.replace(codeBlockExclusionRegex, '').replace(imageExclusionRegex, '')

  commonLanguageReplacements =
    python: [
      ['true', 'True'], ['false', 'False'], ['null', 'None'],
      ['object', 'dictionary'], ['Object', 'Dictionary'],
      ['array', 'list'], ['Array', 'List'],
    ]
    lua: [
      ['null', 'nil'],
      ['object', 'table'], ['Object', 'Table'],
      ['array', 'table'], ['Array', 'Table'],
    ]
  for [from, to] in commonLanguageReplacements[currentLanguage] ? []
    # Convert JS-specific keywords and types to Python ones, if in simple `code` tags.
    # This won't cover it when it's not in an inline code tag by itself or when it's not in English.
    text = text.replace ///`#{from}`///g, "`#{to}`"
    # Now change "An `dictionary`" to "A `dictionary`", etc.
    if startsWithVowel(from) and not startsWithVowel(to)
      text = text.replace ///(\ a|A)n(\ `#{to}`)///g, "$1$2"
    if not startsWithVowel(from) and startsWithVowel(to)
      text = text.replace ///(\ a|A)(\ `#{to}`)///g, "$1n$2"

  return text

capitalLanguages =
  'javascript': 'JavaScript'
  'coffeescript': 'CoffeeScript'
  'python': 'Python'
  'java': 'Java'
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
      levelNumber = $.t('play_level.challenge')
    else
      practiceLevelCurrentCount = 0
    levelNumberMap[level.key] = levelNumber
  levelNumberMap

findNextLevel = (levels, currentIndex, needsPractice) ->
  # Find next available incomplete level, depending on whether practice is needed
  # levels = [{practice: true/false, complete: true/false, assessment: true/false}]
  # Skip over assessment levels
  index = currentIndex
  index++
  if needsPractice
    if levels[currentIndex].practice or index < levels.length and levels[index].practice
      # Needs practice, current level is practice or next is practice; return the next incomplete practice-or-normal level
      # May leave earlier practice levels incomplete and reach end of course
      index++ while index < levels.length and (levels[index].complete or levels[index].assessment)
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
      index++ while index < levels.length and (levels[index].complete or levels[index].assessment)
  else
    # No practice needed; return the next required incomplete level
    index++ while index < levels.length and (levels[index].practice or levels[index].complete or levels[index].assessment)
  index

findNextAssessmentForLevel = (levels, currentIndex, needsPractice) ->
  # Find assessment level immediately after current level (and its practice levels)
  # Only return assessment if it's the next level
  # Skip over practice levels unless practice neeeded
  # levels = [{practice: true/false, complete: true/false, assessment: true/false}]
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
    url: "https://player.vimeo.com/video/310626758",
    cn_url: "https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE01-%E5%9F%BA%E6%9C%AC%E8%AF%AD%E6%B3%95-Codecombat%20Instruction%20for%20Teachers.mp4",
    title: "Basic Syntax",
    original: "54173c90844506ae0195a0b4",
    thumbnail_locked: "/images/level/videos/basic_syntax_locked.png",
    thumbnail_unlocked: "/images/level/videos/basic_syntax_unlocked.png"
  },
  # fire dancing
  "55ca293b9bc1892c835b0136": {
    i18name: 'while_loops',
    url: "https://player.vimeo.com/video/310626741",
    cn_url: "https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE03-CodeCombat%E6%95%99%E5%AD%A6%E5%AF%BC%E8%AF%BE-CS1-%E5%BE%AA%E7%8E%AFlogo.mp4",
    title: "While Loops",
    original: "55ca293b9bc1892c835b0136"
    thumbnail_locked: "/images/level/videos/while_loops_locked.png",
    thumbnail_unlocked: "/images/level/videos/while_loops_unlocked.png"
  }
  # known enemy
  "5452adea57e83800009730ee": {
    i18name: 'variables',
    url: "https://player.vimeo.com/video/310626807",
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

yearsSinceMonth = (start) ->
  return undefined unless start
  # Should probably review this logic, written quickly and haven't tested any edge cases
  if _.isString start
    return undefined unless /\d{4}-\d{2}(-\d{2})?/.test start
    if start.length is 7
      start = start + '-28'  # Assume near the end of the month, don't let timezones mess it up, skew younger in interpretation
    start = new Date(start)
  return undefined unless _.isDate start
  now = new Date()
  now.getFullYear() - start.getFullYear() + (now.getMonth() - start.getMonth()) / 12

# Keep in sync with the copy in background-processor
ageBrackets = [
  {slug: '0-11', max: 11.33}
  {slug: '11-14', max: 14.33}
  {slug: '14-18', max: 18.99}
  {slug: 'open', max: 9001}
]

ageToBracket = (age) ->
  # Convert years to an age bracket
  return 'open' unless age
  for bracket in ageBrackets
    if age < bracket.max
      return bracket.slug
  return 'open'

module.exports = {
  addIntroLevelContent
  ageBrackets
  ageOfConsent
  ageToBracket
  buildLevelsListByModule
  capitalLanguages
  clone
  combineAncestralObject
  countries
  countryCodeToFlagEmoji
  courseAcronyms
  courseIDs
  courseModules
  createLevelNumberMap
  extractPlayerCodeTag
  filterMarkdownCodeLanguages
  findNextAssessmentForLevel
  findNextLevel
  formatDollarValue
  formatStudentLicenseStatusDate
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
  hourOfCodeOptions
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
  pathToUrl
  petThangIDs
  premiumContent
  registerHocProgressModalCheck
  replaceText
  round
  sortCourses
  sortCoursesByAcronyms
  stripIndentation
  usStateCodes
  userAgent
  videoLevels
  vueNonReactiveInstall
  yearsSinceMonth
}
