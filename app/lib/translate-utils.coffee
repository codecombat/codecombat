{ commentStarts } = require '../core/utils'
module.exports.translateJS = (jsCode, language='cpp', fullCode=true) ->
  return translateJSBrackets(jsCode, language, fullCode) if language in ['cpp', 'java']
  return translateJSWhitespace(jsCode, language) if language in ['python', 'lua', 'coffeescript']
  return jsCode if language is 'javascript'
  console.warn 'Unsupported language translation: from javascript to', language
  return jsCode

translateJSBrackets = (jsCode, language='cpp', fullCode=true) ->
# Supports cpp or java

# Find all global statement(except global variables) and move into main function
  reorderGlobals = (strs) ->
    insertPlace = strs.length-1
    for i in [strs.length-2..0] by -1
      continue if /\n?function/.test(strs[i])
      continue if /^[ \t]+\/\//.test(strs[i])
      insertPlace -= 1
      strs.splice(insertPlace, 0, strs.splice(i,1)[0])

    mainLen = strs[strs.length-1].split('\n').length
    final = strs.splice(insertPlace).join('')
    finals = final.split('\n')
    insertPlace = finals.length - mainLen
    for i in [finals.length-mainLen-1..0] by -1
      continue unless finals[i]
      continue if /var /.test(finals[i])
      insertPlace -= 1
      finals.splice(insertPlace, 0, finals.splice(i,1)[0])

    return strs.concat([finals.slice(0, insertPlace).join('\n'), finals.slice(insertPlace).join('\n')])

  # Find header comments function definitions in order to hoist them out of the main function
  matchBrackets = (str, startIndex) ->
    cc = 0
    for i in [startIndex...str.length]
      cc += 1 if str[i] == '{'
      if str[i] == '}'
        cc -= 1
        return i+2 unless cc
  splitFunctions = (str) ->
    creg = /\n?[ \t]*[^\/]/
    startCommentReg = /^\n?(\/\/.*?\n)*\n/
    comments = startCommentReg.exec(str)
    if comments
      startComments = comments[0].slice(0, -1) # left the tailing \n
      str = str.slice startComments.length
      unless creg.exec str
        return [startComments, str]
    else
      strComments = ''

    indices = []
    reg = /\n(\/\/.*?\n)*function/gi
    indices.push 0 if str.startsWith("function ")
    while (result = reg.exec(str))
      indices.push result.index+1
    split = []
    end = 0
    # split.push {s: 0, e: indices[0]} if indices.length
    for i in indices
      split.push {s: end, e: i} if end != i
      end = matchBrackets str, i
      split.push {s: i, e: end}
    split.push {s: end, e: str.length}
    header = if startComments then [startComments] else []
    return header.concat(reorderGlobals(split.map (s) -> str.slice s.s, s.e ))

  jsCodes = splitFunctions jsCode
  if fullCode
# Remove whitespace-only pieces, except for in the last piece
    jsCodes = _.filter(jsCodes.slice(0, jsCodes.length - 1), (piece) -> piece.replace(/\s/g, '').length).concat(jsCodes[jsCodes.length - 1])
  else
# Remove all whitespace-only pieces
    jsCodes = _.filter jsCodes, (piece) -> piece.replace(/\s/g, '').length
  len = jsCodes.length
  if len
    lines = jsCodes[len-1].trimStart().split '\n'
  else
    lines = []
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
      if len > 2 and !(/function/.test jsCodes[len-2])
        jsCodes[len-2] = (jsCodes[len-2].split('\n').map (line) ->
          if / = /.test line
            line = 'static ' + line
          line
        ).join('\n')

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
  else if len
    jsCodes[len-1] = (lines.map (line) -> ' ' + line).join('\n')  # Add whitespace at beginning of each line to make regexes easier

  functionReturnType = if language is 'cpp' then 'auto' else 'public static var'  # TODO: figure out some auto return types for Java
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
    s = s.replace /hero\.throw\(/g, 'hero.throwEnemy('
    s = s.replace /\ = \[([^;]*)\];/g, ' = {$1};'

    if language is 'cpp'
      s = s.replace /\.length/g, '.size()'
      s = s.replace /\.push\(/g, '.push_back('
      s = s.replace /\.pop\(/g, '.pop_back('
      s = s.replace /\.shift\(/g, '.pop('
      s = s.replace /\ (var|let) /g, ' auto '
      s = s.replace /\((var|let) /g, '(auto '
      s = s.replace /\n(var|let) /g, '\nauto '
      s = s.replace /\ const /g, ' const auto '
      s = s.replace /\nconst /g, '\nconst auto '
      s = s.replace /\ return \[([^;]*)\];/g, ' return {$1};'

    # TODO: figure out how we are going to call other methods in Java
    # TODO: figure out how we are going to handle {x: 34, y: 30} object literals in Java
    # TODO: figure out how we are going to handle array methods in Java

    # Don't substitute these within comments
    noComment = '^( *[^/\\r\\n]*?)' # keep leading whitespace
    if language is 'cpp'
      newRegex = new RegExp(noComment + '([^*])new ', 'gm')
      while newRegex.test(s)
        s = s.replace newRegex, '$1$2*new '
    quotesReg = new RegExp(noComment + "'(.*?)'", 'gm')
    while quotesReg.test(s)
      s = s.replace quotesReg, '$1"$2"'
    # first replace ' to " then replace object
    if language is 'cpp'
      s = s.replace /\{\s*"?x"?\s*:\s*([^,]+),\s*"?y"?\s*:\s*([^\}]*)\}/g, '{$1, $2}'  # {x:1, y:1} -> {1, 1}
    else if language is 'java'
      # Let's use Vectors instead of object literals in this case
      s = s.replace /\{\s*"?x"?\s*:\s*([^,]+),\s*"?y"?\s*:\s*([^\}]*)\}/g, 'new Vector($1, $2)'  # {x:1, y:1} -> new Vector(1, 1)
    jsCodes[i] = s

  unless fullCode
    if len
      lines = jsCodes[len-1].split '\n'
      jsCodes[len-1] = (lines.map (line) -> line.slice 1).join('\n')  # Remove leading convenience whitespace that we added
    else
      jsCodes = []

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

# Duplicated again from core/utils because of import issues from server
commentStarts =
  javascript: '//'
  python: '#'
  coffeescript: '#'
  lua: '--'
  java: '//'
  cpp: '//'
  html: '<!--'
  css: '/\\*'
