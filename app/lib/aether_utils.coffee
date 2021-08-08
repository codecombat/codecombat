require './aether/aether.coffee'

utils = require 'core/utils'

Aether.addGlobal 'Vector', require './world/vector'
Aether.addGlobal '_', _

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
    when 'lua' then source.replace /loop\n/, 'while true then\n'
    when 'coffeescript' then source
    else source

module.exports.translateJS = (jsCode, language='cpp', fullCode=true) ->
  return translateJSBrackets(jsCode, language, fullCode) if language in ['cpp', 'java']
  return translateJSWhitespace(jsCode, language) if language in ['python', 'lua', 'coffeescript']
  console.warn 'Unsupported language translation: from javascript to', language
  return jsCode

translateJSBrackets = (jsCode, language='cpp', fullCode=true) ->
  # Supports cpp or java

  # Find header comments function definitions in order to hoist them out of the main function
  matchBrackets = (str, startIndex) ->
    cc = 0
    for i in [startIndex...str.length]
      cc += 1 if str[i] == '{'
      if str[i] == '}'
        cc -= 1
        return i+2 unless cc
  splitFunctions = (str) ->
    creg = /\n[ \t]*[^\/]/
    codeIndex = creg.exec(str)
    if str and str[0] != '/'
      startComments = ''
    else if codeIndex
      codeIndex = codeIndex.index + 1
      startComments = str.slice 0, codeIndex
      str = str.slice codeIndex
    else
      return [str, '']

    indices = []
    reg = /\nfunction/gi
    indices.push 0 if str.startsWith("function ")
    while (result = reg.exec(str))
      indices.push result.index+1
    split = []
    end = 0
    split.push {s: 0, e: indices[0]} if indices.length
    for i in indices
      end = matchBrackets str, i
      split.push {s: i, e: end}
    split.push {s: end, e: str.length}
    header = if startComments then [startComments] else []
    # TODO: this loses startComments before any function that isn't the first function
    return header.concat split.map (s) -> str.slice s.s, s.e

  jsCodes = splitFunctions jsCode
  if fullCode
    # Remove whitespace-only pieces, except for in the last piece
    jsCodes = _.filter(jsCodes.slice(0, jsCodes.length - 1), (piece) -> piece.replace(/\s/g, '').length).concat(jsCodes[jsCodes.length - 1])
  else
    # Remove all whitespace-only pieces
    jsCodes = _.filter jsCodes, (piece) -> piece.replace(/\s/g, '').length
  len = jsCodes.length
  lines = jsCodes[len-1].trimStart().split '\n'
  #console.log "Split code segments into", _.cloneDeep(jsCodes)
  if fullCode
    if language is 'cpp'
      jsCodes[len-1] = """
        int main() {
        #{(lines.map (line) -> '    ' + line).join '\n'}
            return 0;
        }
      """
    else if language is 'java'
      hasHeader = /^\/\//.test(jsCodes[0])
      startIndex = if hasHeader then 1 else 0
      functionLines = jsCodes.splice(startIndex, len - 1 - startIndex).join('\n').trimStart().split('\n')
      functionLines.shift() while functionLines.length and not functionLines[0]  # Trim starting whitespace lines
      len = jsCodes.length
      jsCodes[len-1] = """
        public class AI {#{if functionLines.length then '\n' + (functionLines.map (line) -> '    ' + line).join '\n' else ''}
            public static void main(String[] args) {
        #{(lines.map (line) -> '        ' + line).join '\n'}
            }
        }
      """
  else
    jsCodes[len-1] = (lines.map (line) -> ' ' + line).join('\n')  # Add whitespace at beginning of each line to make regexes easier

  functionReturnType = if language is 'cpp' then 'auto' else 'public static void'  # TODO: figure out some auto return types for Java
  functionParamType = if language is 'cpp' then 'auto' else 'Object'  # TODO: figure out some auto/void param types for Java
  for i in [0...len]
    s = jsCodes[i]
    s = s.replace /function (.+?)\((.*?)\)/g, (match, functionName, functionParams) ->
      typedParameters = _.filter(functionParams.split(/, ?/)).map((e) -> "#{functionParamType} #{e}").join(', ')
      "#{functionReturnType} #{functionName}(#{typedParameters})"
    s = s.replace /var (x|y|z|dist)/g, 'float $1'
    s = s.replace /var (\w+)Index/g, 'int $1Index'
    s = s.replace /var (i|j|k)(?![a-zA-Z0-9_])/g, 'int $1'
    s = s.replace /\ ===\ /g, ' == '
    s = s.replace /\ !== /g, ' != '

    if language is 'cpp'
      s = s.replace /\.length/g, '.size()'
      s = s.replace /\.push\(/g, '.push_back('
      s = s.replace /\.pop\(/g, '.pop_back('
      s = s.replace /\.shift\(/g, '.pop('
      s = s.replace /\ var /g, ' auto '
      s = s.replace /\ = \[([^;]*)\];/g, ' = {$1};'
      s = s.replace /\(var /g, '(auto '
      s = s.replace /\nvar /g, '\nauto '
      s = s.replace /\ return \[([^;]*)\];/g, ' return {$1};'

    # TODO: figure out how we are going to call other methods in Java
    # TODO: figure out how we are going to handle {x: 34, y: 30} object literals in Java
    # TODO: figure out how we are going to handle array methods in Java

    # Don't substitute these within comments
    noComment = '^ *([^/\\r\\n]*?)'
    if language is 'cpp'
      newRegex = new RegExp(noComment + '([^*])new ', 'gm')
      while newRegex.test(s)
        s = s.replace newRegex, '$1$2*new '
    quotesReg = new RegExp(noComment + "'(.*?)'", 'gm')
    while quotesReg.test(s)
      s = s.replace quotesReg, '$1"$2"'
    # first replace ' to " then replace object
    s = s.replace /\{\s*"?x"?\s*:\s*([^,]+),\s*"?y"?\s*:\s*([^\}]*)\}/g, '{$1, $2}'  # {x:1, y:1} -> {1, 1}
    jsCodes[i] = s

  unless fullCode
    lines = jsCodes[len-1].split '\n'
    jsCodes[len-1] = (lines.map (line) -> line.slice 1).join('\n')  # Remove leading convenience whitespace that we added

  jsCodes.join '\n'

translateJSWhitespace = (jsCode, language='lua') ->
  # Supports python, lua, or coffeescript

  s = jsCode.split('\n').map((line) -> ' ' + line).join('\n')  # Add whitespace at beginning of each line to make regexes easier

  if language is 'lua'
    s = s.replace /function (.+?)\((.*)\) ?{/g, 'function $1($2)'  # Just remove the trailing {
  else if language is 'python'
    s = s.replace /function (.+?)\((.*)\) ?{/g, 'def $1($2):'  # Convert trailing { to :
  else if language is 'coffeescript'
    s = s.replace /function (.+?)\((.*)\) ?{/g, (match, functionName, functionParams) ->
      if functionParams
        "#{functionName} = (#{functionParams}) ->"
      else
        "#{functionName} = ->"

  # Rewrite for-loops
  # for(i=0; i < archers.length; i++) {
  #     var archer = archers[i];
  cStyleForInLoopWithVariableAssignmentRegex = /for ?\((?:var )?(.+?) ?= ?0; ?\1 ?< ?(.+?).length; ?(?:.*?\+\+.*?)\) *\{?\n(.*)var (.+?) ?= ?\2\[\1\];? *$/gm
  if language is 'lua'
    # for i, archer in pairs(archers) do
    s = s.replace cStyleForInLoopWithVariableAssignmentRegex, 'for $1, $4 in pairs($2) do'
  else if language is 'python'
    #s = s.replace cStyleForInLoopWithVariableAssignmentRegex, 'for $1, $4 in enumerate($2):'  # I guess we usually do the other way for scaffolding learning similar to how we do it in JS instead of teaching enumerate
    s = s.replace cStyleForInLoopWithVariableAssignmentRegex, 'for $1 in range(len($2)):\n$3$4 = $2[$1]'
  else if language is 'coffeescript'
    # for archer in archers
    s = s.replace cStyleForInLoopWithVariableAssignmentRegex, 'for $4, $1 in $2'

  # for(i=0; i < archers.length; i++) {
  cStyleForInLoopRegex = /for ?\((?:var )?(.+?) ?= ?0; ?\1 ?< ?(.+?).length; ?(?:.*?\+\+.*?)\) *\{?/g
  if language is 'lua'
    # for i in pairs(archers) do
    s = s.replace cStyleForInLoopRegex, 'for $1 in pairs($2) do'
  else if language is 'python'
    # for i in range(0, len(archers)):
    s = s.replace cStyleForInLoopRegex, 'for $1 in range(len($2)):'
  else if language is 'coffeescript'
    # for i in [0...archers.length]
    s = s.replace cStyleForInLoopRegex, 'for $1 in [0...$2.length]'

  # for(i=0; i < 10; i++) {
  cStyleForLoopRegex = /for ?\((?:var )?(.+?) ?= ?(\d+); ?\1 ?< ?(.+?); ?(?:.*?\+\+.*?)\) *\{?/g
  if language is 'lua'
    # for i=0, 10 do
    s = s.replace cStyleForLoopRegex, 'for $1=$2, $3 do'
  else if language is 'python'
    # for i in range(0, 10):
    s = s.replace cStyleForLoopRegex, 'for $1 in range($2, $3):'
  else if language is 'coffeescript'
    # for i in [0...10]
    s = s.replace cStyleForLoopRegex, 'for $1 [$2...$3]'

  # for(y=110; y >= 38; i -= 18) {
  # This is brittle and will not get inclusive vs. exclusive ranges right, but better than nothing
  cStyleForLoopWithArithmeticRegex = /for ?\((?:var )?(.+?) ?= ?(\d+); ?\1 ?(<=|<|>=|>) ?(.+?); ?\1 ?\+?(-?)= ?(.*)\) *\{?/g
  if language is 'lua'
    # for y=110, 38, -18 do
    s = s.replace cStyleForLoopWithArithmeticRegex, 'for $1=$2, $4, $5$6 do'
  else if language is 'python'
    # for y in range(110, 38, -18):
    s = s.replace cStyleForLoopWithArithmeticRegex, 'for $1 in range($2, $4, $5$6):'
  else if language is 'coffeescript'
    # for y in [110...38, -18]
    s = s.replace cStyleForLoopWithArithmeticRegex, 'for $1 [$2...$4, $5$6]'

  # There are a lot of other for-loop possibilities, but we'll handle those with manual solutions

  if language is 'lua'
    s = s.replace /\ ===\ /g, ' == '
    s = s.replace /\ !==? /g, ' ~= '
    s = s.replace /(\S+)(\+|-){2}/g, '$1 = $1 $2 1'  # Rewrite postfix ++ and --, like count++ -> count = count + 1
    s = s.replace /(\+|-){2}(\S+)/g, '$2 = $2 $1 1'  # Rewrite prefix  ++ and --, like ++count -> count = count + 1
    s = s.replace /(\S+) ?(\+|-|\*|\/)= ?(.+)/g, '$1 = $1 $2 $3'  # Rewrite +=, -=, etc.
  else if language is 'coffeescript'
    s = s.replace /\ ===?\ /g, ' is '
    s = s.replace /\ !==? /g, ' isnt '
  else if language is 'python'
    s = s.replace /\ ===?\ /g, ' == '  # Maybe we should rewrite to `is` instead?
    s = s.replace /\ !==? /g, ' != '
    s = s.replace /(\S+)(\+|-){2}/g, '$1 $2= 1'  # Rewrite postfix ++ and --, like count++ -> count += 1
    s = s.replace /(\+|-){2}(\S+)/g, '$2 $1= 1'  # Rewrite prefix  ++ and --, like ++count -> count += 1

  s = s.replace /\ &&\ /g, ' and '
  s = s.replace /\ \|\|\ /g, ' or '
  s = s.replace /\!([$A-Z_(])/gi, 'not $1'

  if language is 'python'
    s = s.replace /\.push\(/g, '.append('
    s = s.replace /\.shift\(0?\)/g, '.pop(0)'
  else if language is 'lua'
    s = s.replace /\.push\(/g, '.insert('
    s = s.replace /\.pop\(/g, '.remove('
    s = s.replace /\.shift\(0?\)/g, '.remove(0)'

  if language is 'lua'
    s = s.replace /\ var /g, ' local '
    s = s.replace /\ = \[([^;]*)\];/g, ' = {$1};'
    s = s.replace /\(var /g, '(local '
    s = s.replace /\nvar /g, '\nlocal '
    s = s.replace /\ return \[([^;]*)\];/g, ' return {$1};'
  else if language in ['python', 'coffeescript']
    s = s.replace /^ *var [^=\n]*$\n/gm, ''  # Remove variable declarations without initialization
    s = s.replace /\ var /g, ' '
    s = s.replace /\(var /g, '('
    s = s.replace /\nvar /g, '\n'

  # Don't substitute these within comments
  noComment = '^ *([^/\\r\\n]*?)'
  if language in ['python', 'lua']
    newRegex = new RegExp(noComment + 'new ', 'gm')
    while newRegex.test(s)
      s = s.replace newRegex, '$1'

  # Rewrite comments
  commentStart = commentStarts[language] or '#'
  commentStartRegex = new RegExp "([ \t]*?)//", 'gm'
  s = s.replace commentStartRegex, "$1#{commentStart}"  # `    // Comment` -> `    # Comment`

  # No semicolons
  s = s.replace /;/g, ''

  # For Lua, replace periods with colons for method calls (but not other property accesses)
  if language is 'lua'
    s = s.replace /([$A-Z_][$0-9a-z_]*)\.([$A-Za-z_][0-9A-Za-z_$]*)\(/gi, '$1:$2('
    # We still use periods for Math (still using the JavaScript library), it's static vs. instance method thing
    # Hack: re-replace back to dots in those cases by looking at initial capital letter of variable name
    s = s.replace /([$A-Z_][$0-9a-z_]*):([$A-Za-z_][0-9A-Za-z_$]*)\(/g, '$1.$2('

  # Rewrite while loops
  if language is 'lua'
    s = s.replace /^(\s*while) ?\((.*)\) ?\{?/gm, '$1 $2 do'
  else if language is 'python'
    s = s.replace /^(\s*while) ?\((.*)\) ?\{?/gm, '$1 $2:'
  else if language is 'coffeescript'
    s = s.replace /^(\s*while) ?\((.*)\) ?\{?/gm, '$1 $2'

  # Rewrite if conditions
  if language is 'lua'
    s = s.replace /else if/g, 'elseif'
    s = s.replace /(} *)?( *(if|elseif)) ?\((.*)\) ?\{?/gm, '$2 $4 then'
  else if language is 'python'
    s = s.replace /else if/g, 'elif'
    s = s.replace /(} *)?( *(if|elif)) ?\((.*)\) ?\{?/gm, '$2 $4:'
    s = s.replace /(}\s*)?else\s*{/g, 'else:'
  else if language is 'coffeescript'
    s = s.replace /(} *)?( *(if|else if)) ?\((.*)\) ?\{?/gm, '$2 $4'
    s = s.replace /(}\s*)?else\s*{/g, 'else'

  # Rewrite else { to else
  s = s.replace /(}\s*)?else\s*{/g, 'else'

  if language is 'lua'
    # Rewrite standalone `}` to `end`
    s = s.replace /^(\s*)\} *$/gm, '$1end'
    # Remove `end` as part of part of if/elseif/else chains
    s = s.replace /^(\s*)end ?}?\n((\n|\s|--.*\n)*^\1)(elseif|else)/gm, '$2$4'  # The ^\1 only matches the same level of indentation
  else if language in ['python', 'coffeescript']
    # Remove stanadlone `}`
    s = s.replace /\n\s*\} *$/gm, ''

  if language is 'lua'
    s = s.replace /null/g, 'nil'
    s = s.replace /(\S+)\.length/g, '#$1'  # Do this after if/else paren/bracket replacement
  else if language is 'python'
    s = s.replace /true/g, 'True'
    s = s.replace /false/g, 'False'
    s = s.replace /null/g, 'None'
    s = s.replace /(\S+)\.length/g, 'len($1)'  # Do this after if/else paren/bracket replacement

  if language is 'coffeescript'
    # Remove unnecessary parenthesis in CofeeScript
    s = s.replace /([$A-Z_][0-9A-Z_$]*)\(([^()]+)\)(?!\))$/gim, '$1 $2'
    # Use simple loops in CoffeeScript
    s = s.replace /while true$/gm, 'loop'

  if language is 'lua'
    # Convert : to =. {x:1, y:1} -> {x=1, y=1}
    s = s.replace /\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+)\}/g, '{$1=$2}'  # 1 element
    s = s.replace /\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{$1=$2, $3=$4}'  # 2 elements
    s = s.replace /\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{$1=$2, $3=$4, $4=6}'  # 3 elements
    # TODO: something flexible for arbitrary n elements
  else if language is 'python'
    # Add quotes. {x:1, y:1} -> {"x": 1, "y": 1}
    s = s.replace /\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+)\}/g, '{"$1": $2}'  # 1 element
    s = s.replace /\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{"$1": $2, "$3": $4}'  # 2 elements
    s = s.replace /\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{"$1": $2, "$3": $4, "$5": $6}'  # 3 elements
    # TODO: something flexible for arbitrary n elements

  if language is 'lua'
    # Try incrementing all literal array indexes under, say, 10 by 1 to offset 1-based indexing. Hack, but most of those levels will need manual attention anyway.
    s = s.replace /\[(\d)\]/g, (match, index) -> "[#{parseInt(index, 10) + 1}]"

  # TODO: see if we can do something about lack of a continue statement in Lua? Maybe too hard and we should give up.

  lines = s.split '\n'
  output = (lines.map (line) -> line.slice 1).join('\n')  # Remove leading convenience whitespace that we added
  output

startsWithVowel = (s) -> s[0] in 'aeiouAEIOU'

module.exports.filterMarkdownCodeLanguages = (text, language) ->
  return '' unless text
  currentLanguage = language or me.get('aceConfig')?.language or 'python'
  excludedLanguages = _.without ['javascript', 'python', 'coffeescript', 'lua', 'java', 'cpp', 'html'], if currentLanguage == 'cpp' then 'javascript' else currentLanguage
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
  if currentLanguage == 'cpp'
    jsRegex = new RegExp "```javascript\n([^`]+)```", 'gm'
    text = text.replace jsRegex, (a, l) =>
      """```cpp
        #{@translateJS a[13..a.length-4], 'cpp', false}
      ```"""

  return text

# Note: These need to be double-escaped for insertion into regexes
commentStarts =
  javascript: '//'
  python: '#'
  coffeescript: '#'
  lua: '--'
  java: '//'
  cpp: '//'
  html: '<!--'
  css: '/\\*'
