require './aether/aether.coffee'

Aether.addGlobal 'Vector', require './world/vector'
Aether.addGlobal '_', _
translateUtils = require './translate-utils'

module.exports.createAetherOptions = (options) ->
  throw new Error 'Specify a function name to create an Aether instance' unless options.functionName
  throw new Error 'Specify a code language to create an Aether instance' unless options.codeLanguage

  aetherOptions =
    functionName: options.functionName
    protectAPI: not options.skipProtectAPI
    includeFlow: Boolean options.includeFlow
    noVariablesInFlow: true
    skipDuplicateUserInfoInFlow: true  # Optimization that won't work if we are stepping with frames
    yieldConditionally: options.functionName is 'plan'
    simpleLoops: true
    whileTrueAutoYield: true
    globals: ['Vector', '_']
    problems:
      jshint_W040: {level: 'ignore'}
      jshint_W030: {level: 'ignore'}  # aether_NoEffect instead
      jshint_W038: {level: 'ignore'}  # eliminates hoisting problems
      jshint_W091: {level: 'ignore'}  # eliminates more hoisting problems
      jshint_E043: {level: 'ignore'}  # https://github.com/codecombat/codecombat/issues/813 -- since we can't actually tell JSHint to really ignore things
      jshint_Unknown: {level: 'ignore'}  # E043 also triggers Unknown, so ignore that, too
      aether_MissingThis: {level: 'error'}
    problemContext: options.problemContext
    #functionParameters: # TODOOOOO
    executionLimit: 3 * 1000 * 1000
    language: options.codeLanguage
    useInterpreter: true
  parameters = functionParameters[options.functionName]
  unless parameters
    console.warn "Unknown method #{options.functionName}: please add function parameters to lib/aether_utils.coffee."
    parameters = []
  if options.functionParameters and not _.isEqual options.functionParameters, parameters
    console.error "Update lib/aether_utils.coffee with the right function parameters for #{options.functionName} (had: #{parameters} but this gave #{options.functionParameters}."
    parameters = options.functionParameters
  aetherOptions.functionParameters = parameters.slice()
  #console.log 'creating aether with options', aetherOptions
  return aetherOptions

# TODO: figure out some way of saving this info dynamically so that we don't have to hard-code it: #1329
functionParameters =
  hear: ['speaker', 'message', 'data']
  makeBid: ['tileGroupLetter']
  findCentroids: ['centroids']
  isFriend: ['name']
  evaluateBoard: ['board', 'player']
  getPossibleMoves: ['board']
  minimax_alphaBeta: ['board', 'player', 'depth', 'alpha', 'beta']
  distanceTo: ['target']

  chooseAction: []
  plan: []
  initializeCentroids: []
  update: []
  getNearestEnemy: []
  die: []

module.exports.generateSpellsObject = (options) ->
  {level, levelSession, token} = options
  {createAetherOptions} = require 'lib/aether_utils'
  aetherOptions = createAetherOptions functionName: 'plan', codeLanguage: levelSession.get('codeLanguage'), skipProtectAPI: options.level?.isType('game-dev')
  spellThang = thang: {id: 'Hero Placeholder'}, aether: new Aether aetherOptions
  spells = "hero-placeholder/plan": thang: spellThang, name: 'plan'
  source = token or levelSession.get('code')?['hero-placeholder']?.plan ? ''
  try
    spellThang.aether.transpile source
  catch e
    console.log "Couldn't transpile!\n#{source}\n", e
    spellThang.aether.transpile ''
  spells

module.exports.replaceSimpleLoops = (source, language) ->
  switch language
    when 'python' then source.replace /loop:/, 'while True:'
    when 'javascript', 'java', 'cpp' then source.replace /loop {/, 'while (true) {'
    when 'lua' then source.replace /loop\n/, 'while true do\n'
    when 'coffeescript' then source
    else source

startsWithVowel = (s) -> s[0] in 'aeiouAEIOU'

module.exports.filterMarkdownCodeLanguages = (text, language) ->
  return '' unless text
  currentLanguage = language or me.get('aceConfig')?.language or 'python'
  excludeCpp = 'cpp'
  unless /```cpp\n[^`]+```\n?/.test text
    excludeCpp = 'javascript'
  excludedLanguages = _.without ['javascript', 'python', 'coffeescript', 'lua', 'java', 'cpp', 'html', 'io', 'clojure'], if currentLanguage == 'cpp' then excludeCpp else currentLanguage
  # Exclude language-specific code blocks like ```python (... code ...)``
  # ` for each non-target language.
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
  if currentLanguage == 'cpp' and excludeCpp == 'javascript'
    jsRegex = new RegExp "```javascript\n([^`]+)```", 'gm'
    text = text.replace jsRegex, (a, l) =>
      """```cpp
        #{translateUtils.translateJS a[13..a.length-4], 'cpp', false}
      ```"""

  return text

makeErrorMessageTranslationRegex = (englishString) ->
  escapeRegExp = (str) ->
    # https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
    return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
  new RegExp(escapeRegExp(englishString).replace(/\\\$\d/g, '(.+)').replace(/ +/g, ' +'))

module.exports.translateErrorMessage = ({ message, errorCode, i18nParams, spokenLanguage, staticTranslations, translateFn }) ->
  # Here we take a string from the locale file, find the placeholders ($1/$2/etc)
  #   and replace them with capture groups (.+),
  # returns a regex that will match against the error message
  #   and capture any dynamic values in the text
  # staticTranslations is { langCode: translations } for en and target languages
  # translateFn(i18nKey, i18nParams) is $.i18n.t on the client, i18next.t on the server
  return message if not message
  if /\n/.test(message) # Translate each line independently, since regexes act weirdly with newlines
    return message.split('\n').map((line) -> module.exports.translateErrorMessage({ message: line.trim(), errorCode, i18nParams, spokenLanguage, staticTranslations, translateFn })).join('\n')

  if /^i18n::/.test(message) # handle i18n messages from aether_worker
    messages = message.split('::')
    return translateFn(messages[1], JSON.parse(messages[2]))

  message = message.replace /([A-Za-z]+Error:) \1/, '$1'
  return message if spokenLanguage in ['en', 'en-US']

  # Separately handle line number and error type prefixes
  applyReplacementTranslation = (text, regex, key) =>
    fullKey = "esper.#{key}"
    replacementTemplate = translateFn(fullKey)
    return if replacementTemplate is fullKey
    # This carries over any capture groups from the regex into $N placeholders in the template string
    replaced = text.replace regex, replacementTemplate
    if replaced isnt text
      return [replaced.replace(/``/g, '`'), true]
    return [text, false]

  # These need to be applied in this order, before the main text is translated
  prefixKeys = ['line_no', 'uncaught', 'reference_error', 'argument_error', 'type_error', 'syntax_error', 'error']

  messages = message.split(': ')
  for i of messages
    m = messages[i]
    m += ': ' unless +i == messages.length - 1 # i is string
    for keySet in [prefixKeys, Object.keys(_.omit(staticTranslations.en.esper), prefixKeys)]
      for translationKey in keySet
        englishString = staticTranslations.en.esper[translationKey]
        regex = makeErrorMessageTranslationRegex englishString
        [m, didTranslate] = applyReplacementTranslation m, regex, translationKey
        break if didTranslate and keySet isnt prefixKeys
    messages[i] = m

  if errorCode
    messages[messages.length - 1] = translateFn("esper.error_#{(_.string || _.str).underscored(errorCode)}", i18nParams)

  messages.join('')
