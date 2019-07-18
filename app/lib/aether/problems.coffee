ranges = require './ranges'

###
  This must be the library instead of our modified vendored version.
  `string_score` adds method `score` to the string prototype while our vendored
  version provides a function `score` which is made global.
  We expect both globally due to some subtle dependencies.
  E.g the string prototype method `score` is used in the component misc.PropertyErrorHelper
  in the editor.
###
string_score = require 'string_score'

# Problems #################################
#
# Error messages and hints:
#   Processed by markdown
#   In general, put correct replacement code in a markdown code span.  E.g. "Try `self.moveRight()`"
#
#
# Problem Context (problemContext)
#
# Aether accepts a problemContext parameter via the constructor options or directly to createUserCodeProblem
# This context can be used to craft better errors messages.
#
# Example:
#   Incorrect user code is 'this.attack(Brak);'
#   Correct user code is 'this.attack("Brak");'
#   Error: 'Brak is undefined'
#   If we had a list of expected string references, we could provide a better error message:
#   'Brak is undefined. Are you missing quotes? Try this.attack("Brak");'
#
# Available Context Properties:
#   stringReferences: values that should be referred to as a string instead of a variable (e.g. "Brak", not Brak)
#   thisMethods: methods available on the 'this' object
#   thisProperties: properties available on the 'this' object
#   commonThisMethods: methods that are available sometimes, but not awlays
#

# Esprima Harmony's error messages track V8's
# https://github.com/ariya/esprima/blob/harmony/esprima.js#L194

# JSHint's error and warning messages
# https://github.com/jshint/jshint/blob/master/src/messages.js

scoreFuzziness = 0.8
acceptMatchThreshold = 0.5

module.exports.createUserCodeProblem = (options) ->
  options ?= {}
  options.aether ?= @  # Can either be called standalone or as an Aether method
  if options.type is 'transpile' and options.error
    extractTranspileErrorDetails options
  if options.type is 'runtime'
    extractRuntimeErrorDetails options

  reporter = options.reporter or 'unknown'  # Source of the problem, like 'jshint' or 'esprima' or 'aether'
  kind = options.kind or 'Unknown'  # Like 'W075' or 'InvalidLHSInAssignment'
  id = reporter + '_' + kind  # Uniquely identifies reporter + kind combination
  config = options.aether?.options?.problems?[id] or {}  # Default problem level/message/hint overrides
  p = isUserCodeProblem: true
  p.id = id
  p.level = config.level or options.level or 'error'  # 'error', 'warning', 'info'
  p.type = options.type or 'generic'  # Like 'runtime' or 'transpile', maybe later 'lint'
  p.message = config.message or options.message or "Unknown #{p.type} #{p.level}"  # Main error message (short phrase)
  p.hint = config.hint or options.hint or ''  # Additional details about error message (sentence)
  p.range = options.range  # Like [{ofs: 305, row: 15, col: 15}, {ofs: 312, row: 15, col: 22}], or null
  p.userInfo = options.userInfo ? {}  # Record extra information with the error here
  p


# Transpile Errors

extractTranspileErrorDetails = (options) ->
  code = options.code or ''
  codePrefix = options.codePrefix or ''
  error = options.error
  options.message = error.message
  errorContext = options.problemContext or options.aether?.options?.problemContext
  languageID = options.aether?.options?.language

  originalLines = code.slice(codePrefix.length).split '\n'
  lineOffset = codePrefix.split('\n').length - 1

  # TODO: move these into language-specific plugins
  switch options.reporter
    when 'jshint'
      options.message ?= error.reason
      options.kind ?= error.code

      # TODO: Put this transpile error hint creation somewhere reasonable
      if doubleVar = options.message.match /'([\w]+)' is already defined\./
        # TODO: Check that it's a var and not a function
        options.hint = "Don't use the 'var' keyword for '#{doubleVar[1]}' the second time."

      unless options.level
        options.level = {E: 'error', W: 'warning', I: 'info'}[error.code[0]]
      line = error.line - codePrefix.split('\n').length
      if line >= 0
        if error.evidence?.length
          startCol = originalLines[line].indexOf error.evidence
          endCol = startCol + error.evidence.length
        else
          [startCol, endCol] = [0, originalLines[line].length - 1]
        # TODO: no way this works; what am I doing with code prefixes?
        options.range = [ranges.rowColToPos(line, startCol, code, codePrefix),
                         ranges.rowColToPos(line, endCol, code, codePrefix)]
      else
        # TODO: if we type an unmatched {, for example, then it thinks that line -2's function wrapped() { is unmatched...
        # TODO: no way this works; what am I doing with code prefixes?
        options.range = [ranges.offsetToPos(0, code, codePrefix),
                         ranges.offsetToPos(code.length - 1, code, codePrefix)]
    when 'esprima'
      # TODO: column range should extend to whole token. Mod Esprima, or extend to end of line?
      # TODO: no way this works; what am I doing with code prefixes?
      options.range = [ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column - 1, code, codePrefix),
                       ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column, code, codePrefix)]
    when 'acorn_loose'
      null

    when 'csredux'
      options.range = [ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column - 1, code, codePrefix),
                       ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column, code, codePrefix)]
    when 'aether'
      null

    when 'closer'
      if error.startOffset and error.endOffset
        range = ranges.offsetsToRange(error.startOffset, error.endOffset, code)
        options.range = [range.start, range.end]

    when 'lua2js'
      options.message ?= error.message
      rng = ranges.offsetsToRange(error.offset, error.offset, code, '')
      options.range = [rng.start, rng.end]

    when 'filbert'
      console.log "Incomming Error", error
      if error.loc
        columnOffset = 0
        # filbert lines are 1-based, columns are 0-based
        row = error.loc.line - lineOffset - 1
        col = error.loc.column - columnOffset
        start = ranges.rowColToPos(row, col, code, codePrefix)
        end = ranges.rowColToPos(row, col + error.raisedAt - error.pos, code, codePrefix)
        options.range = [start, end]

        switch error.extra.kind
          when 'STATEMENT_EOF'
            options.message = 'Unexpected token'
          when 'CLASSIFY'
            if error.extra.value == "'"
              options.message = "Unterminated string constant"

        console.log "Extra", error.extra
        options.extra = error.extra if error.extra
        console.log "Outexpected Error", options

    when 'iota'
      null

    when 'cashew'
      options.range = [ranges.offsetToPos(error.range[0], code, codePrefix),
                       ranges.offsetToPos(error.range[1], code, codePrefix)]
      options.hint = error.message
    when 'jaba'
      options.range = [error.location.start.offset, error.location.end.offset]
      options.hint = error.message
    else
      console.warn "Unhandled UserCodeProblem reporter", options.reporter

  options.hint = options.hint or error.hint or getTranspileHint options.message, errorContext, languageID, options.aether.raw, options.range, options.aether.options?.simpleLoops
  options

getTranspileHint = (msg, context, languageID, code, range, simpleLoops=false) ->
  #console.log 'get transpile hint', msg, context, languageID, code, range
  # TODO: Only used by Python currently
  # TODO: JavaScript blocked by jshint range bug: https://github.com/codecombat/aether/issues/113
  if msg in ["Unterminated string constant", "Unclosed string."] and range?
    codeSnippet = code.substring range[0].ofs, range[1].ofs
    # Trim codeSnippet so we can construct the correct suggestion with an ending quote
    firstQuoteIndex = codeSnippet.search /['"]/
    if firstQuoteIndex isnt -1
      quoteCharacter = codeSnippet[firstQuoteIndex]
      codeSnippet = codeSnippet.slice firstQuoteIndex + 1
      codeSnippet = codeSnippet.substring 0, nonAlphNumMatch.index if nonAlphNumMatch = codeSnippet.match /[^\w]/
      return "Missing a quotation mark. Try `#{quoteCharacter}#{codeSnippet}#{quoteCharacter}`"

  else if msg is "Unexpected indent"
    if range?
      index = range[0].ofs
      index-- while index > 0 and /\s/.test(code[index])
      if index >= 3 and /else/.test(code.substring(index - 3, index + 1))
        return "You are missing a ':' after 'else'. Try `else:`"
    return "Code needs to line up."

  else if ((msg.indexOf("Unexpected token") >= 0) or (msg.indexOf("Unexpected identifier") >= 0)) and context?
    codeSnippet = code.substring range[0].ofs, range[1].ofs
    lineStart = code.substring range[0].ofs - range[0].col, range[0].ofs
    lineStartLow = lineStart.toLowerCase()
    # console.log "Aether transpile problem codeSnippet='#{codeSnippet}' lineStart='#{lineStart}'"

    # Check for extra thisValue + space at beginning of line
    # E.g. 'self self.moveRight()'
    hintCreator = new HintCreator context, languageID
    if lineStart.indexOf(hintCreator.thisValue) is 0 and lineStart.trim().length < lineStart.length
      # TODO: update error range so this extra bit is highlighted
      if codeSnippet.indexOf(hintCreator.thisValue) is 0
        return "Delete extra `#{hintCreator.thisValue}`"
      else
        return hintCreator.getReferenceErrorHint codeSnippet

    # Check for two commands on a single line with no semi-colon
    # E.g. "self.moveRight()self.moveDown()"
    # Check for problems following a ')'
    prevIndex = range[0].ofs - 1
    prevIndex-- while prevIndex >= 0 and /[\t ]/.test(code[prevIndex])
    if prevIndex >= 0 and code[prevIndex] is ')'
      if codeSnippet is ')'
        return "Delete extra `)`"
      else if not /^\s*$/.test(codeSnippet)
        return "Put each command on a separate line"

    parens = 0
    parens += (if c is '(' then 1 else if c is ')' then -1 else 0) for c in lineStart
    return "Your parentheses must match." unless parens is 0

    # Check for uppercase loop
    # TODO: Should get 'loop' from problem context
    if simpleLoops and codeSnippet is ':' and lineStart isnt lineStartLow and lineStartLow is 'loop'
      return "Should be lowercase. Try `loop`"

    # Check for malformed if statements
    if /^\s*if /.test(lineStart)
      if codeSnippet is ':'
        return "Your if statement is missing a test clause. Try `if True:`"
      else if /^\s*$/.test(codeSnippet)
        # TODO: Upate error range to be around lineStart in this case
        return "You are missing a ':' after '#{lineStart}'. Try `#{lineStart}:`"

    # Catchall hint for 'Unexpected token' error
    if /Unexpected (token|identifier)/.test(msg)
      return "There is a problem with your code."

# Runtime Errors


esperLocToAetherLoc = (loc) ->
  return undefined unless loc? and loc.start? and loc.end?
  [
    {row: loc.start.line-1, col: loc.start.column, ofs: loc.start.pos},
    {row: loc.end.line-1, col: loc.end.column, ofs: loc.end.pos}
  ]

extractRuntimeErrorDetails = (options) ->
  if error = options.error
    options.kind ?= error.name  # I think this will pick up [Error, EvalError, RangeError, ReferenceError, SyntaxError, TypeError, URIError, DOMException]

    if options.aether.options.useInterpreter
      options.message = error.toString()
    else
      options.message = error.message or error.toString()
    options.hint = error.hint or getRuntimeHint options
    options.level ?= error.level
    options.userInfo ?= error.userInfo

  # NOTE: lastStatementRange set via instrumentation.logStatementStart(originalNode.originalRange)
  options.range ?= options.aether?.lastStatementRange
  if options.aether?
    loc = options.aether?.esperEngine?.evaluator?.topFrame?.ast?.loc
    options.range ?= esperLocToAetherLoc loc

  if options.error.name?
    options.message = "#{options.error.name}: #{options.message}"

  if options.range?
    lineNumber = options.range[0].row + 1
    if options.message.search(/^Line \d+/) != -1
      options.message = options.message.replace /^Line \d+/, (match, n) -> "Line #{lineNumber}"
    else
      options.message = "Line #{lineNumber}: #{options.message}"

getRuntimeHint = (options) ->
  code = options.aether.raw or ''
  context = options.problemContext or options.aether.options?.problemContext
  languageID = options.aether.options?.language
  simpleLoops = options.aether.options?.simpleLoops

  # Check stack overflow
  return "Did you call a function recursively?" if options.message is "RangeError: Maximum call stack size exceeded"

  # Check loop ReferenceError
  if simpleLoops and languageID is 'python' and /ReferenceError: loop is not defined/.test options.message
    # TODO: move this language-specific stuff to language-specific code
    if options.range?
      index = options.range[1].ofs
      index++ while index < code.length and /[^\n:]/.test code[index]
      hint = "You are missing a ':' after 'loop'. Try `loop:`" if index >= code.length or code[index] is '\n'
    else
      hint = "Are you missing a ':' after 'loop'? Try `loop:`"
    return hint

  # Use problemContext to add hints
  return unless context?
  hintCreator = new HintCreator context, languageID
  hintCreator.getHint code, options

class HintCreator
  # Create hints for an error message based on a problem context
  # TODO: better class name, move this to a separate file

  constructor: (context, languageID) ->
    # TODO: move this language-specific stuff to language-specific code
    @thisValue = switch languageID
      when 'python' then 'self'
      when 'cofeescript' then '@'
      else 'this'

    @realThisValueAccess = switch languageID
      when 'python' then 'self.'
      when 'cofeescript' then '@'
      else 'this.'

    # We use `hero` as `this` in CodeCombat now, so all `this` related hints
    # we get in the problem context should really refrence `hero`
    @thisValueAccess = switch languageID
      when 'python' then 'hero.'
      when 'cofeescript' then 'hero.'
      when 'lua' then 'hero:'
      else 'hero.'

    @newVariableTemplate = switch languageID
      when 'javascript' then _.template('var <%= name %> = ')
      else _.template('<%= name %> = ')

    @methodRegex = switch languageID
      when 'python' then new RegExp "self\\.(\\w+)\\s*\\("
      when 'cofeescript' then new RegExp "@(\\w+)\\s*\\("
      else new RegExp "this\\.(\\w+)\\("

    @context = context ? {}

  getHint: (code, {message, range, error, aether}) ->
    console.log error
    return unless @context?
    if error.code is 'UndefinedVariable' and error.when is 'write' and aether.language.id is 'javascript'
      return "Missing `var`. Use `var #{error.ident} =` to make a new variable."

    if error.code is "CallNonFunction"
      ast = error.targetAst
      if ast.type is "MemberExpression" and not ast.computed
        extra = ""
        target = ast.property.name
        if error.candidates?
          candidatesLow = (s.toLowerCase() for s in error.candidates)
          idx = candidatesLow.indexOf(target.toLowerCase())
          if idx isnt -1
            newName = error.targetName.replace target, error.candidates[idx]
            return "Look out for capitalization: `#{error.targetName}` should be `#{newName}`."
          sm = @getScoreMatch target, [{candidates: error.candidates, msgFormatFn: (match) -> match}]
          if sm?
            newName = error.targetName.replace target, sm
            return "Look out for spelling issues: did you mean `#{newName}` instead of `#{error.targetName}`?"
        
        return "`#{ast.object.srcName}` has no method `#{ast.property.name}`."

    if (missingMethodMatch = message.match(/has no method '(.*?)'/)) or message.match(/is not a function/) or message.match(/has no method/)
      # NOTE: We only get this for valid thisValue and parens: self.blahblah()
      # NOTE: We get different error messages for this based on javascript engine:
      # Chrome: 'undefined is not a function'
      # Firefox: 'tmp5[tmp6] is not a function'
      # test framework: 'Line 1: Object #<Object> has no method 'moveright'
      if missingMethodMatch
        target = missingMethodMatch[1]
      else if range?
        # TODO: this is not covered by any test cases yet, because our test environment throws different errors
        codeSnippet = code.substring range[0].ofs, range[1].ofs
        missingMethodMatch = @methodRegex.exec codeSnippet
        target = missingMethodMatch[1] if missingMethodMatch?
      hint = if target? then @getNoFunctionHint target
    else if missingReference = message.match /([^\s]+) is not defined/
      hint = @getReferenceErrorHint missingReference[1]
    else if missingProperty = message.match /Cannot (?:read|call) (?:property|method) '([\w]+)' of (?:undefined|null)/
      # Chrome: "Cannot read property 'moveUp' of undefined"
      # TODO: Firefox: "tmp5 is undefined"
      hint = @getReferenceErrorHint missingProperty[1]

      # Chrome: "Cannot read property 'pos' of null"
      # TODO: Firefox: "tmp10 is null"
      # TODO: range is pretty busted, but row seems ok so we'll use that.
      # TODO: Should we use a different message if object was 'undefined' instead of 'null'?
      if not hint? and range?
        line = code.substring range[0].ofs - range[0].col, code.indexOf('\n', range[1].ofs)
        nullObjRegex = new RegExp "(\\w+)\\.#{missingProperty[1]}"
        if nullObjMatch = nullObjRegex.exec line
          hint = "'#{nullObjMatch[1]}' was null. Use a null check before accessing properties. Try `if #{nullObjMatch[1]}:`"
    hint

  getNoFunctionHint: (target) ->
    # Check thisMethods
    hint = @getNoCaseMatch target, @context.thisMethods, (match) =>
      # TODO: Remove these format tests someday.
      # "Uppercase or lowercase problem. Try #{@thisValueAccess}#{match}()"
      # "Uppercase or lowercase problem.  \n  \n\tTry: #{@thisValueAccess}#{match}()  \n\tHad: #{codeSnippet}"
      # "Uppercase or lowercase problem.  \n  \nTry:  \n`#{@thisValueAccess}#{match}()`  \n  \nInstead of:  \n`#{codeSnippet}`"
      "Uppercase or lowercase problem. Try `#{@thisValueAccess}#{match}()`"
    hint ?= @getScoreMatch target, [candidates: @context.thisMethods, msgFormatFn: (match) =>
      "Try `#{@thisValueAccess}#{match}()`"]
    # Check commonThisMethods
    hint ?= @getExactMatch target, @context.commonThisMethods, (match) ->
      "You do not have an item equipped with the #{match} skill."
    hint ?= @getNoCaseMatch target, @context.commonThisMethods, (match) ->
      "Did you mean #{match}? You do not have an item equipped with that skill."
    hint ?= @getScoreMatch target, [candidates: @context.commonThisMethods, msgFormatFn: (match) ->
      "Did you mean #{match}? You do not have an item equipped with that skill."]
    hint ?= "You don't have a `#{target}` method."
    hint

  getReferenceErrorHint: (target) ->
    # Check missing quotes
    hint = @getExactMatch target, @context.stringReferences, (match) ->
      "Missing quotes. Try `\"#{match}\"`"
    # Check this props
    hint ?= @getExactMatch target, @context.thisMethods, (match) =>
      "Try `#{@thisValueAccess}#{match}()`"
    hint ?= @getExactMatch target, @context.thisProperties, (match) =>
      "Try `#{@thisValueAccess}#{match}`"
    # Check case-insensitive, quotes, this props
    if not hint? and target.toLowerCase() is @thisValue.toLowerCase()
      hint = "Uppercase or lowercase problem. Try `#{@thisValue}`"
    hint ?= @getNoCaseMatch target, @context.stringReferences, (match) ->
      "Missing quotes.  Try `\"#{match}\"`"
    hint ?= @getNoCaseMatch target, @context.thisMethods, (match) =>
      "Try `#{@thisValueAccess}#{match}()`"
    hint ?= @getNoCaseMatch target, @context.thisProperties, (match) =>
      "Try `#{@thisValueAccess}#{match}`"
    # Check score match, quotes, this props
    hint ?= @getScoreMatch target, [
      {candidates: [@thisValue], msgFormatFn: (match) -> "Try `#{match}`"},
      {candidates: @context.stringReferences, msgFormatFn: (match) -> "Missing quotes. Try `\"#{match}\"`"},
      {candidates: @context.thisMethods, msgFormatFn: (match) => "Try `#{@thisValueAccess}#{match}()`"},
      {candidates: @context.thisProperties, msgFormatFn: (match) => "Try `#{@thisValueAccess}#{match}`"}]
    # Check commonThisMethods
    hint ?= @getExactMatch target, @context.commonThisMethods, (match) ->
      "You do not have an item equipped with the #{match} skill."
    hint ?= @getNoCaseMatch target, @context.commonThisMethods, (match) ->
      "Did you mean #{match}? You do not have an item equipped with that skill."
    hint ?= @getScoreMatch target, [candidates: @context.commonThisMethods, msgFormatFn: (match) ->
      "Did you mean #{match}? You do not have an item equipped with that skill."]
    # Check enemy defined
    if not hint and target.toLowerCase().indexOf('enemy') > -1 and _.contains(@context.thisMethods, 'findNearestEnemy')
      hint = "There is no `#{target}`. Use `#{@newVariableTemplate({name:target})}#{@thisValueAccess}findNearestEnemy()` first."

    # Try score match with this value prefixed
    # E.g. target = 'selfmoveright', try 'self.moveRight()''
    if not hint? and @context?.thisMethods?
      thisPrefixed = (@thisValueAccess + method for method in @context.thisMethods)
      hint = @getScoreMatch target, [candidates: thisPrefixed, msgFormatFn: (match) ->
        "Try `#{match}()`"]

    hint

  getExactMatch: (target, candidates, msgFormatFn) ->
    return unless candidates?
    msgFormatFn target if target in candidates

  getNoCaseMatch: (target, candidates, msgFormatFn) ->
    return unless candidates?
    candidatesLow = (s.toLowerCase() for s in candidates)
    msgFormatFn candidates[index] if (index = candidatesLow.indexOf target.toLowerCase()) >= 0

  getScoreMatch: (target, candidatesList) ->
    # candidatesList is an array of candidates objects. E.g. [{candidates: [], msgFormatFn: ()->}, ...]
    # This allows a score match across multiple lists of candidates (e.g. thisMethods and thisProperties)
    return unless string_score?
    [closestMatch, closestScore, msg] = ['', 0, '']
    for set in candidatesList
      if set.candidates?
        for match in set.candidates
          matchScore = match.score target, scoreFuzziness
          [closestMatch, closestScore, msg] = [match, matchScore, set.msgFormatFn(match)] if matchScore > closestScore
    msg if closestScore >= acceptMatchThreshold
