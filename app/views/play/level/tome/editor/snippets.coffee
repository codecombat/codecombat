###
  This is essentially a copy from the snippet completer from Ace's ext/language-tools.js
  However this completer assigns a score to the snippets to ensure that snippet suggestions are
  treated better in the autocomplete than local values
###

{score} = fuzzaldrin
#score = (a, b) -> new Fuzziac(a).score b
lineBreak = /\r\n|[\n\r\u2028\u2029]/g
identifierRegex = /[\.a-zA-Z_0-9\$\-\u00A2-\uFFFF]/
Fuzziac = require './fuzziac' # https://github.com/stollcri/fuzziac.js

module.exports = (SnippetManager, autoLineEndings) ->
  {Range} = ace.require 'ace/range'
  util = ace.require 'ace/autocomplete/util'
  identifierRegexps: [identifierRegex]

  # Cleanup surrounding text
  baseInsertSnippet = SnippetManager.insertSnippet
  SnippetManager.insertSnippet = (editor, snippet) ->
    # Remove dangling snippet prefixes
    # Examples:
    #   "self self.moveUp()"
    #   "elf.self.moveUp()"
    #   "ssefl.moveUp()"
    #   "slef.moveUp()"
    # TODO: This function is a mess
    # TODO: Can some of this nonsense be done upstream in scrubSnippet?
    cursor = editor.getCursorPosition()
    line = editor.session.getLine cursor.row
    if cursor.column > 0
      prevWord = util.retrievePrecedingIdentifier line, cursor.column - 1, identifierRegex
      if prevWord.length > 0
        # Remove previous word if it's at the beginning of the snippet
        prevWordIndex = snippet.toLowerCase().indexOf prevWord.toLowerCase()
        if prevWordIndex is 0
          range = new Range cursor.row, cursor.column - 1 - prevWord.length, cursor.row, cursor.column
          editor.session.remove range
        else
          # console.log "Zatanna cursor.column=#{cursor.column} snippet='#{snippet}' line='#{line}' prevWord='#{prevWord}'"
          # console.log "Zatanna prevWordIndex=#{prevWordIndex}"

          # Lookup original completion
          # TODO: Can we identify correct completer somehow?
          for completer in editor.completers
            if completer.completions?
              for completion in completer.completions
                if completion.snippet is snippet
                  originalCompletion = completion
                  break
              break if originalCompletion

          if originalCompletion?
            # console.log 'Zatanna original completion', originalCompletion
            # Get original snippet prefix (accounting for extra '\n' and possibly autoLineEndings at end)
            lang = editor.session.getMode()?.$id?.substr 'ace/mode/'.length
            # console.log 'Zatanna lang', lang, autoLineEndings[lang]?.length
            extraEndLength = 1
            extraEndLength += autoLineEndings[lang].length if autoLineEndings[lang]?
            if snippetIndex = originalCompletion.content.indexOf snippet.substr(0, snippet.length - extraEndLength)
              originalPrefix = originalCompletion.content.substring 0, snippetIndex
            else
              originalPrefix = ''
            snippetStart = cursor.column - originalPrefix.length
            # console.log "Zatanna originalPrefix='#{originalPrefix}' snippetStart=#{snippetStart}"

            if snippetStart > 0 and snippetStart <= line.length
              extraIndex = snippetStart - 1
              # console.log "Zatanna prev char='#{line[extraIndex]}'"

              if line[extraIndex] is '.'
                # Fuzzy string match previous word before '.', and remove if a match to beginning of snippet
                originalObject = originalCompletion.content.substring(0, originalCompletion.content.indexOf('.'))
                prevObjectIndex = extraIndex - 1
                # console.log "Zatanna prevObjectIndex=#{prevObjectIndex}"
                if prevObjectIndex >= 0 and /\w/.test(line[prevObjectIndex])
                  prevObjectIndex-- while prevObjectIndex >= 0 and /\w/.test(line[prevObjectIndex])
                  prevObjectIndex++ if prevObjectIndex < 0 or not /\w/.test(line[prevObjectIndex])
                  # console.log "Zatanna prevObjectIndex=#{prevObjectIndex} extraIndex=#{extraIndex}"
                  prevObject = line.substring prevObjectIndex, extraIndex

                  #TODO: We use to use fuzziac here, but we forgot why.  Using
                  # fuzzaldren for now.
                  #fuzzer = {score: (n) -> score originalObject, n}
                  fuzzer = new Fuzziac originalObject
                  finalScore = 0
                  if fuzzer
                    finalScore = fuzzer.score prevObject

                  # console.log "Zatanna originalObject='#{originalObject}' prevObject='#{prevObject}'", finalScore
                  if finalScore > 0.5
                    range = new Range cursor.row, prevObjectIndex, cursor.row, snippetStart
                    editor.session.remove range
                  else if /^[^.]+\./.test snippet
                    # Remove the first part of the snippet, and use whats there.
                    snippet = snippet.replace /^[^.]+\./, ''

              else if /\w/.test(line[extraIndex])
                # Remove any alphanumeric characters on this line immediately before prefix
                extraIndex-- while extraIndex >= 0 and /\w/.test(line[extraIndex])
                extraIndex++ if extraIndex < 0 or not /\w/.test(line[extraIndex])
                range = new Range cursor.row, extraIndex, cursor.row, snippetStart
                editor.session.remove range

    #Remove anything that looks like an identifier after the completion
    afterIndex = cursor.column
    trailingText = line.substring afterIndex
    match = trailingText.match /^[a-zA-Z_0-9]*(\(\s*\))?/
    afterIndex += match[0].length if match
    afterRange = new Range cursor.row, cursor.column, cursor.row, afterIndex
    editor.session.remove afterRange

    baseInsertSnippet.call @, editor, snippet

  getCompletions: (editor, session, pos, prefix, callback) ->
    # console.log "Zatanna getCompletions pos.column=#{pos.column} prefix=#{prefix}"
    # Completion format:
    # prefix: text that will be replaced by snippet
    # caption: displayed left-justified in popup, and what's being matched
    # snippet: what will be inserted into document
    # score: used to order autocomplete snippet suggestions
    # meta: displayed right-justfied in popup
    lang = session.getMode()?.$id?.substr 'ace/mode/'.length
    line = session.getLine pos.row
    completions = []

    #If the prefix is a member expression, supress completions
    fullPrefix = getFullIdentifier session, pos
    fullPrefixParts = fullPrefix.split /[.:]/g
    word = getCurrentWord session, pos

    if fullPrefixParts.length > 2
      @completions = []
      return callback null, completions

    beginningOfLine = session.getLine(pos.row).substring(0,pos.column - prefix.length)

    unless (fullPrefixParts.length < 3 and /^(hero|self|this|@)$/.test(fullPrefixParts[0]) ) or /^\s*$/.test(beginningOfLine)
      console.log "Bailing", fullPrefixParts, '|', prefix, '|', beginningOfLine, '|', pos.column - prefix.length
      @completions = completions
      return callback null, completions

    #If the prefix is a reserved word, make enter just complete it
    keywords = session.getMode()?.$highlightRules?.$keywordList
    if keywords and prefix in keywords
      completions.push
        content: prefix
        caption: prefix
        snippet: prefix + "\n"
        score: 100
        meta: '\u21E5'

    snippetMap = SnippetManager.snippetMap

    SnippetManager.getActiveScopes(editor).forEach (scope) ->
      snippets = snippetMap[scope] or []
      for s in snippets
        caption  = s.name or s.tabTrigger
        continue unless caption
        [snippet, fuzzScore] = scrubSnippet s.content, caption, line, prefix, pos, lang, autoLineEndings, s.captureReturn
        completions.push
          content: s.content  # Used internally by Zatanna, not by ace autocomplete
          caption: caption
          snippet: snippet
          score: fuzzScore * s.importance ? 1.0
          meta: s.meta or (if s.tabTrigger and not s.name then s.tabTrigger + '\u21E5' else 'snippets')
    , @
    # console.log 'Zatanna snippet completions', completions
    @completions = completions
    callback null, completions

  # TODO: This shim doesn't work because our version of ace isn't updated to this change:
  # TODO: https://github.com/ajaxorg/ace/commit/7b01a4273e91985c9177f53d238d6b83fe99dc56
  # TODO: But, if it was we could use this and pass a 'completer: @' property for each completion
  # insertMatch: (editor, data) ->
  #   console.log 'Zatanna snippets insertMatch', editor, data
  #   if data.snippet
  #     SnippetManager.insertSnippet editor, data.snippet
  #   else
  #     editor.execCommand "insertstring", data.value || data

getCurrentWord = (doc, pos) ->
  end = pos.column
  start = end - 1
  text = doc.getLine(pos.row)
  start-- while start >= 0 and not text[start].match /\s+|[\.\@]/
  start++ if start >= 0
  text.substring start, end

getFullIdentifier = (doc, pos) ->
  end = pos.column
  start = end - 1
  text = doc.getLine(pos.row)
  start-- while start >= 0 and not text[start].match /\s+/
  start++ if start >= 0
  text.substring start, end

scrubSnippet = (snippet, caption, line, input, pos, lang, autoLineEndings, captureReturn) ->
  # console.log "Zatanna snippet=#{snippet} caption=#{caption} line=#{line} input=#{input} pos.column=#{pos.column} lang=#{lang}"
  fuzzScore = 0.1
  # input will be replaced by snippet
  # trim snippet prefix and suffix if already in the document (line)
  if prefixStart = snippet.toLowerCase().indexOf(input.toLowerCase()) > -1
    snippetLines = (snippet.match(lineBreak) || []).length
    captionStart = snippet.indexOf caption

    # Calculate snippet prefixes and suffixes. E.g. full snippet might be: "self." + "moveLeft" + "()"
    snippetPrefix = snippet.substring 0, captionStart
    snippetSuffix = snippet.substring snippetPrefix.length + caption.length

    # Calculate line prefixes and suffixes
    # linePrefix: beginning portion of snippet that already exists
    linePrefixIndex = pos.column - input.length - 1
    if linePrefixIndex >= 0 and snippetPrefix.length > 0 and line[linePrefixIndex] is snippetPrefix[snippetPrefix.length - 1]
      snippetPrefixIndex = snippetPrefix.length - 1
      while line[linePrefixIndex] is snippetPrefix[snippetPrefixIndex]
        break if linePrefixIndex is 0 or snippetPrefixIndex is 0
        linePrefixIndex--
        snippetPrefixIndex--
      linePrefix = line.substr linePrefixIndex, pos.column - input.length - linePrefixIndex
    else
      linePrefix = ''
    lineSuffix = line.substr pos.column, snippetSuffix.length - 1 + caption.length - input.length + 1
    lineSuffix = '' if snippet.indexOf(lineSuffix) < 0

    # TODO: This is broken for attack(find in Python, but seems ok in JavaScript.

    # Don't eat existing matched parentheses
    # console.log "Zatanna checking parentheses lineSuffix=#{lineSuffix} pos.column=#{pos.column} input.length=#{input.length}, prevChar=#{line[pos.column - input.length - 1]} line.length=#{line.length} nextChar=#{line[pos.column]}"
    if pos.column - input.length >= 0 and line[pos.column - input.length - 1] is '(' and pos.column < line.length and line[pos.column] is ')' and lineSuffix is ')'
      lineSuffix = ''

    # Score match before updating snippet
    fuzzScore += score snippet, linePrefix + input + lineSuffix

    # Update snippet based on surrounding document/line
    snippet = snippet.slice snippetPrefix.length if snippetPrefix.length > 0 and snippetPrefix is linePrefix
    snippet = snippet.slice 0, snippet.length - lineSuffix.length if lineSuffix.length > 0

    # Append automatic line ending and newline
    # If at end of line
    # And, no parentheses are before snippet. E.g. 'if ('
    # And, line doesn't start with whitespace followed by 'if ' or 'elif '
    # console.log "Zatanna autoLineEndings linePrefixIndex='#{linePrefixIndex}'"
    if lineSuffix.length is 0 and /^\s*$/.test line.slice pos.column
      # console.log 'Zatanna atLineEnd', pos.column, lineSuffix.length, line.slice(pos.column + lineSuffix.length), line
      toLinePrefix = line.substring 0, linePrefixIndex
      if linePrefixIndex < 0 or linePrefixIndex >= 0 and not /[\(\)]/.test(toLinePrefix) and not /^[ \t]*(?:if\b|elif\b)/.test(toLinePrefix)
        snippet += autoLineEndings[lang] if snippetLines is 0 and autoLineEndings[lang]
        snippet += "\n" if snippetLines is 0 and not /\$\{/.test(snippet)

        if captureReturn and /^\s*$/.test(toLinePrefix)
          snippet = captureReturn + linePrefix + snippet

    # console.log "Zatanna snippetPrefix=#{snippetPrefix} linePrefix=#{linePrefix} snippetSuffix=#{snippetSuffix} lineSuffix=#{lineSuffix} snippet=#{snippet} score=#{fuzzScore}"
  else
    fuzzScore += score snippet, input

  startsWith = (string, searchString, position) ->
    position = position or 0
    return string.substr(position, searchString.length) is searchString

  # Prefixing is twice as good as fuzzy mathing?
  fuzzScore *= 2 if startsWith(caption, input)

  # All things equal, a shorter snippet is better
  fuzzScore -= caption.length / 500

  # Exact match is really good.
  fuzzScore = 10 if caption == input

  [snippet, fuzzScore]
