/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
/*
  This is essentially a copy from the snippet completer from Ace's ext/language-tools.js
  However this completer assigns a score to the snippets to ensure that snippet suggestions are
  treated better in the autocomplete than local values
*/

const { score } = fuzzaldrin
// score = (a, b) -> new Fuzziac(a).score b
const lineBreak = /\r\n|[\n\r\u2028\u2029]/g
const identifierRegex = /[\.a-zA-Z_0-9\$\-\u00A2-\uFFFF]/
const Fuzziac = require('./fuzziac') // https://github.com/stollcri/fuzziac.js
const ace = require('lib/aceContainer')
const store = require('core/store')

const checkingParentheses = function (line, left) {
  const findRight = left
  let i = 0
  while (i < line.length) {
    const c = line[i]
    if (c === '(') { left += 1 }
    if (c === ')') { left -= 1 }
    i += 1
    if (findRight && !left) { break }
  }
  if (findRight) {
    return i
  } else {
    return left
  }
}

module.exports = function (SnippetManager, autoLineEndings) {
  const { Range } = ace.require('ace/range')
  const util = ace.require('ace/autocomplete/util');
  ({ identifierRegexps: [identifierRegex] })

  // Cleanup surrounding text
  const baseInsertSnippet = SnippetManager.insertSnippet
  SnippetManager.insertSnippet = function (editor, snippet) {
    let afterRange, length, removedEnd, removedStart
    store.commit('game/incrementTimesAutocompleteUsed')
    // Remove dangling snippet prefixes
    // Examples:
    //   "self self.moveUp()"
    //   "elf.self.moveUp()"
    //   "ssefl.moveUp()"
    //   "slef.moveUp()"
    // TODO: This function is a mess
    // TODO: Can some of this nonsense be done upstream in scrubSnippet?
    const cursor = editor.getCursorPosition()
    const line = editor.session.getLine(cursor.row)
    if (cursor.column > 0) {
      const prevWord = util.retrievePrecedingIdentifier(line, cursor.column - 1, identifierRegex)
      if (prevWord.length > 0) {
        // Remove previous word if it's at the beginning of the snippet
        let range
        const prevWordIndex = snippet.toLowerCase().indexOf(prevWord.toLowerCase())
        if (prevWordIndex === 0) {
          removedStart = cursor.column - 1 - prevWord.length
          removedEnd = cursor.column
          range = new Range(cursor.row, removedStart, cursor.row, removedEnd)
          editor.session.remove(range)
        } else {
          // console.log "Snippets cursor.column=#{cursor.column} snippet='#{snippet}' line='#{line}' prevWord='#{prevWord}'"
          // console.log "Snippets prevWordIndex=#{prevWordIndex}"

          // Lookup original completion
          // TODO: Can we identify correct completer somehow?
          let originalCompletion
          for (const completer of Array.from(editor.completers)) {
            if (completer.completions != null) {
              for (const completion of Array.from(completer.completions)) {
                if (completion.snippet === snippet) {
                  originalCompletion = completion
                  break
                }
              }
              if (originalCompletion) { break }
            }
          }

          if (originalCompletion != null) {
            // console.log 'Snippets original completion', originalCompletion
            // Get original snippet prefix (accounting for extra '\n' and possibly autoLineEndings at end)
            let originalPrefix, snippetIndex
            const lang = __guard__(__guard__(editor.session.getMode(), x1 => x1.$id), x => x.substr('ace/mode/'.length))
            // console.log 'Snippets lang', lang, autoLineEndings[lang]?.length
            let extraEndLength = 1
            if (autoLineEndings[lang] != null) { extraEndLength += autoLineEndings[lang].length }
            if ((snippetIndex = originalCompletion.content.indexOf(snippet.substr(0, snippet.length - extraEndLength)))) {
              originalPrefix = originalCompletion.content.substring(0, snippetIndex)
            } else {
              originalPrefix = ''
            }
            const snippetStart = cursor.column - originalPrefix.length
            // console.log "Snippets originalPrefix='#{originalPrefix}' snippetStart=#{snippetStart}"

            if ((snippetStart > 0) && (snippetStart <= line.length)) {
              let extraIndex = snippetStart - 1
              // console.log "Snippets prev char='#{line[extraIndex]}'"

              if (line[extraIndex] === '.') {
                // Fuzzy string match previous word before '.', and remove if a match to beginning of snippet
                const originalObject = originalCompletion.content.substring(0, originalCompletion.content.indexOf('.'))
                let prevObjectIndex = extraIndex - 1
                // console.log "Snippets prevObjectIndex=#{prevObjectIndex}"
                if ((prevObjectIndex >= 0) && /\w/.test(line[prevObjectIndex])) {
                  while ((prevObjectIndex >= 0) && /\w/.test(line[prevObjectIndex])) { prevObjectIndex-- }
                  if ((prevObjectIndex < 0) || !/\w/.test(line[prevObjectIndex])) { prevObjectIndex++ }
                  // console.log "Snippets prevObjectIndex=#{prevObjectIndex} extraIndex=#{extraIndex}"
                  const prevObject = line.substring(prevObjectIndex, extraIndex)

                  // TODO: We use to use fuzziac here, but we forgot why.  Using
                  // fuzzaldren for now.
                  // fuzzer = {score: (n) -> score originalObject, n}
                  const fuzzer = new Fuzziac(originalObject)
                  let finalScore = 0
                  if (fuzzer) {
                    finalScore = fuzzer.score(prevObject)
                  }

                  // console.log "Snippets originalObject='#{originalObject}' prevObject='#{prevObject}'", finalScore
                  if (finalScore > 0.5) {
                    removedStart = prevObjectIndex
                    removedEnd = snippetStart
                    range = new Range(cursor.row, removedStart, cursor.row, removedEnd)
                    editor.session.remove(range)
                  } else if (/^[^.]+\./.test(snippet)) {
                    // Remove the first part of the snippet, and use whats there.
                    snippet = snippet.replace(/^[^.]+\./, '')
                  }
                }
              } else if (/\w/.test(line[extraIndex])) {
                // Remove any alphanumeric characters on this line immediately before prefix
                while ((extraIndex >= 0) && /\w/.test(line[extraIndex])) { extraIndex-- }
                if ((extraIndex < 0) || !/\w/.test(line[extraIndex])) { extraIndex++ }
                removedStart = extraIndex
                removedEnd = snippetStart
                range = new Range(cursor.row, removedStart, cursor.row, removedEnd)
                editor.session.remove(range)
              }
            }
          }
        }
      }
    }

    // Remove anything that looks like an identifier after the completion
    let afterIndex = cursor.column
    const trailingText = line.substring(afterIndex)
    const newLine = editor.session.getLine(cursor.row) // get current session line
    let hasAfterRange = false
    if (newLine !== line) {
      // deal with we already remove some of code because of begging of the snippet
      const removedStr = line.slice(removedStart, removedEnd)
      const left = checkingParentheses(removedStr, 0)
      if (left) {
        length = checkingParentheses(newLine.substring(removedStart), left)
        afterRange = new Range(cursor.row, removedStart, cursor.row, removedStart + length)
        editor.session.remove(afterRange)
        hasAfterRange = true
      }
    }

    const match = trailingText.match(/^[a-zA-Z_0-9]*(\(\s*\))?/)
    if (match[0]) {
      afterIndex += match[0].length
      // debugLine = editor.session.getLine cursor.row # get current session line
      afterRange = new Range(cursor.row, cursor.column, cursor.row, afterIndex)
      editor.session.remove(afterRange)
    }

    return baseInsertSnippet.call(this, editor, snippet)
  }

  return {
    getCompletions (editor, session, pos, prefix, callback) {
      // console.log "Snippets getCompletions pos.column=#{pos.column} prefix=#{prefix}"
      // Completion format:
      // prefix: text that will be replaced by snippet
      // caption: displayed left-justified in popup, and what's being matched
      // snippet: what will be inserted into document
      // score: used to order autocomplete snippet suggestions
      // meta: displayed right-justfied in popup
      const lang = __guard__(__guard__(session.getMode(), x1 => x1.$id), x => x.substr('ace/mode/'.length))
      const line = session.getLine(pos.row)

      const completions = []

      // If the prefix is a member expression, supress completions
      const fullPrefix = getFullIdentifier(session, pos)
      const fullPrefixParts = fullPrefix.split(/[.:]/g)
      const word = getCurrentWord(session, pos)

      if (fullPrefixParts.length > 2) {
        this.completions = []
        return callback(null, completions)
      }

      const beginningOfLine = session.getLine(pos.row).substring(0, pos.column - prefix.length)
      const emptyBeginning = /^\s*$/.test(beginningOfLine)

      // we already returned if fullPrefixParts.length > 2, so fullPrefixParts.length < 3 always true here
      // and we want to enable auto completion when cursor is inside a function call as param. so add more check
      if (!/^(hero|pet|db|game|ui)$/.test(fullPrefixParts[0]) && !/^\s*$/.test(beginningOfLine) && !/(,| |\()$/.test(beginningOfLine)) {
        // console.log "DEBUG: autocomplete bailing", fullPrefixParts, '|', prefix, '|', beginningOfLine, '|', pos.column - prefix.length
        this.completions = completions
        return callback(null, completions)
      }

      const {
        snippetMap
      } = SnippetManager

      SnippetManager.getActiveScopes(editor).forEach(function (scope) {
        const snippets = snippetMap[scope] || []
        return (() => {
          const result = []
          for (const s of Array.from(snippets)) {
            var left
            const caption = s.name || s.tabTrigger
            if (!caption) { continue }
            if (/^['"]/.test(caption) && emptyBeginning) { continue } // don't show string completions at the end of line
            if (!s.content) { continue } // some new snippets have no content

            const [snippet, fuzzScore] = Array.from(scrubSnippet(s.content, caption, line, prefix, pos, lang, autoLineEndings, s.captureReturn))
            result.push(completions.push({
              content: s.content, // Used internally by Snippets, not by ace autocomplete
              caption,
              snippet,
              score: (left = fuzzScore * s.importance) != null ? left : 1.0,
              meta: s.meta || (s.tabTrigger && !s.name ? s.tabTrigger + '\u21E5' : 'snippets')
            }))
          }
          return result
        })()
      }
      , this)

      // If the prefix is a reserved word, only exact prefix snippets match
      const keywords = __guard__(__guard__(session.getMode(), x3 => x3.$highlightRules), x2 => x2.$keywordList)
      if (keywords && Array.from(keywords).includes(prefix)) {
        this.completions = _.filter(completions, x => x.caption.indexOf(prefix === 0))
        return callback(null, this.completions)
      }

      this.completions = completions
      return callback(null, completions)
    }
  }
}

// TODO: This shim doesn't work because our version of ace isn't updated to this change:
// TODO: https://github.com/ajaxorg/ace/commit/7b01a4273e91985c9177f53d238d6b83fe99dc56
// TODO: But, if it was we could use this and pass a 'completer: @' property for each completion
// insertMatch: (editor, data) ->
//   console.log 'Snippets snippets insertMatch', editor, data
//   if data.snippet
//     SnippetManager.insertSnippet editor, data.snippet
//   else
//     editor.execCommand "insertstring", data.value || data

var getCurrentWord = function (doc, pos) {
  const end = pos.column
  let start = end - 1
  const text = doc.getLine(pos.row)
  while ((start >= 0) && !text[start].match(/\s+|[\.\@]/)) { start-- }
  if (start >= 0) { start++ }
  return text.substring(start, end)
}

var getFullIdentifier = function (doc, pos) {
  const end = pos.column
  let start = end - 1
  const text = doc.getLine(pos.row)
  while ((start >= 0) && !text[start].match(/\s+/)) { start-- }
  if (start >= 0) { start++ }
  return text.substring(start, end)
}

var scrubSnippet = function (snippet, caption, line, input, pos, lang, autoLineEndings, captureReturn) {
  // console.log "Snippets snippet=#{snippet} caption=#{caption} line=#{line} input=#{input} pos.column=#{pos.column} lang=#{lang}"
  let prefixStart
  let fuzzScore = 0.1
  const snippetLineBreaks = (snippet.match(lineBreak) || []).length
  // input will be replaced by snippet
  // trim snippet prefix and suffix if already in the document (line)
  if (prefixStart = snippet.toLowerCase().indexOf(input.toLowerCase()) > -1) {
    let linePrefix
    const captionStart = snippet.indexOf(caption)

    // Calculate snippet prefixes and suffixes. E.g. full snippet might be: "self." + "moveLeft" + "()"
    const snippetPrefix = snippet.substring(0, captionStart)
    const snippetSuffix = snippet.substring(snippetPrefix.length + caption.length)

    // Calculate line prefixes and suffixes
    // linePrefix: beginning portion of snippet that already exists
    let linePrefixIndex = pos.column - input.length - 1
    if ((linePrefixIndex >= 0) && (snippetPrefix.length > 0) && (line[linePrefixIndex] === snippetPrefix[snippetPrefix.length - 1])) {
      let snippetPrefixIndex = snippetPrefix.length - 1
      while (line[linePrefixIndex] === snippetPrefix[snippetPrefixIndex]) {
        if ((linePrefixIndex === 0) || (snippetPrefixIndex === 0)) { break }
        linePrefixIndex--
        snippetPrefixIndex--
      }
      linePrefix = line.substr(linePrefixIndex, pos.column - input.length - linePrefixIndex)
    } else {
      linePrefix = ''
    }

    let lineSuffix = line.substr(pos.column, (((snippetSuffix.length - 1) + caption.length) - input.length) + 1)
    // eat un-matched quotes
    if (/['"]/.test(caption[0])) {
      const quote = caption[0]
      const num = (line.match(new RegExp(quote, 'g')) || []).length
      if ((num % 2) === 0) {
        lineSuffix = quote
      } else {
        if (!snippet.endsWith(lineSuffix)) { lineSuffix = '' }
      }
    } else {
      if (!snippet.endsWith(lineSuffix)) { lineSuffix = '' }
    }

    // TODO: This is broken for attack(find in Python, but seems ok in JavaScript.

    // Don't eat existing matched parentheses
    // console.log "Snippets checking parentheses lineSuffix=#{lineSuffix} pos.column=#{pos.column} input.length=#{input.length}, prevChar=#{line[pos.column - input.length - 1]} line.length=#{line.length} nextChar=#{line[pos.column]}"
    if (((pos.column - input.length) >= 0) && (line[pos.column - input.length - 1] === '(') && (pos.column < line.length) && (line[pos.column] === ')') && (lineSuffix === ')')) {
      lineSuffix = ''
    }

    // Score match before updating snippet
    fuzzScore += score(snippet, linePrefix + input + lineSuffix)

    // Update snippet based on surrounding document/line
    if ((snippetPrefix.length > 0) && (snippetPrefix === linePrefix)) { snippet = snippet.slice(snippetPrefix.length) }
    if (lineSuffix.length > 0) { snippet = snippet.slice(0, snippet.length - lineSuffix.length) }

    // Append automatic line ending and newline
    // If at end of line
    // And, no parentheses are before snippet. E.g. 'if ('
    // And, line doesn't start with whitespace followed by 'if ' or 'elif '
    // And, the snippet is a function
    // console.log "Snippets autoLineEndings linePrefixIndex='#{linePrefixIndex}'"
    if ((lineSuffix.length === 0) && /^\s*$/.test(line.slice(pos.column))) {
      // console.log 'Snippets atLineEnd', pos.column, lineSuffix.length, line.slice(pos.column + lineSuffix.length), line
      const toLinePrefix = line.substring(0, linePrefixIndex)
      if (((linePrefixIndex < 0) || ((linePrefixIndex >= 0) && !/[\(\)]/.test(toLinePrefix) && !/^[ \t]*(?:if\b|elif\b)/.test(toLinePrefix))) && /\([^)]*\)/.test(snippet)) {
        if ((snippetLineBreaks === 0) && autoLineEndings[lang]) { snippet += autoLineEndings[lang] }
        if ((snippetLineBreaks === 0) && !/\$\{/.test(snippet)) { snippet += '\n' }

        if (captureReturn && /^\s*$/.test(toLinePrefix)) {
          snippet = captureReturn + linePrefix + snippet
        }
      }
    }

    // console.log "Snippets snippetPrefix=#{snippetPrefix} linePrefix=#{linePrefix} snippetSuffix=#{snippetSuffix} lineSuffix=#{lineSuffix} snippet=#{snippet} score=#{fuzzScore}"
  } else {
    // Append automatic line ending and newline for simple scenario
    if (line.trim() === input) {
      if ((snippetLineBreaks === 0) && autoLineEndings[lang]) { snippet += autoLineEndings[lang] }
      if ((snippetLineBreaks === 0) && !/\$\{/.test(snippet)) { snippet += '\n' }
    }
    fuzzScore += score(snippet, input)
  }

  const startsWith = function (string, searchString, position) {
    position = position || 0
    return string.substr(position, searchString.length) === searchString
  }

  // Prefixing is twice as good as fuzzy mathing?
  if (startsWith(caption, input)) { fuzzScore *= 2 }

  // All things equal, a shorter snippet is better
  fuzzScore -= caption.length / 500

  // Exact match is really good.
  if (caption === input) { fuzzScore = 10 }

  return [snippet, fuzzScore]
}

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
