(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestCurriculumEngine = api
    if (root.JSQuestEngine) api.apply(root.JSQuestEngine)
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const INVALID_BOOLEAN_MESSAGE = 'true か false のどちらを確かめればいいのか、わからないよ。boolean には true か false を1つ入れてね。'
  const TRUE_MESSAGE = '正しいです。'
  const FALSE_MESSAGE = '違いますよ。'

  function spokenBooleanFailure () {
    return [
      '(function () {',
      '  hero.say(' + JSON.stringify(INVALID_BOOLEAN_MESSAGE) + ');',
      '  const error = new Error(' + JSON.stringify(INVALID_BOOLEAN_MESSAGE) + ');',
      '  error.jsQuestSpoken = true;',
      '  error.code = "invalid-boolean";',
      '  throw error;',
      '})()'
    ].join('\n')
  }

  function booleanCheck (expression) {
    return [
      '(function (value) {',
      '  if (typeof value !== "boolean") {',
      '    hero.say(' + JSON.stringify(INVALID_BOOLEAN_MESSAGE) + ');',
      '    const error = new Error(' + JSON.stringify(INVALID_BOOLEAN_MESSAGE) + ');',
      '    error.jsQuestSpoken = true;',
      '    error.code = "invalid-boolean";',
      '    throw error;',
      '  }',
      '  return hero.say(value ? ' + JSON.stringify(TRUE_MESSAGE) + ' : ' + JSON.stringify(FALSE_MESSAGE) + ');',
      '})(' + expression + ')'
    ].join('\n')
  }

  function splitArguments (source) {
    if (!source.trim()) return []
    return source.split(',').map(value => value.trim())
  }

  function transformCode (code) {
    return String(code).replace(/hero\.isTrue\s*\(([^()]*)\)/g, (whole, rawArguments) => {
      const args = splitArguments(rawArguments)
      if (args.length !== 1 || !args[0]) return spokenBooleanFailure()
      return booleanCheck(args[0])
    })
  }

  function stripComments (source) {
    const text = String(source)
    let output = ''
    let state = 'code'
    let quote = ''
    let escaped = false

    for (let index = 0; index < text.length; index++) {
      const character = text[index]
      const next = text[index + 1]

      if (state === 'line-comment') {
        if (character === '\n') {
          output += '\n'
          state = 'code'
        } else {
          output += ' '
        }
        continue
      }

      if (state === 'block-comment') {
        if (character === '*' && next === '/') {
          output += '  '
          index++
          state = 'code'
        } else {
          output += character === '\n' ? '\n' : ' '
        }
        continue
      }

      if (state === 'string') {
        output += character
        if (escaped) {
          escaped = false
        } else if (character === '\\') {
          escaped = true
        } else if (character === quote) {
          state = 'code'
          quote = ''
        }
        continue
      }

      if (character === '/' && next === '/') {
        output += '  '
        index++
        state = 'line-comment'
      } else if (character === '/' && next === '*') {
        output += '  '
        index++
        state = 'block-comment'
      } else {
        output += character
        if (character === '"' || character === "'" || character === '`') {
          state = 'string'
          quote = character
        }
      }
    }

    return output
  }

  function codeOnly (source) {
    const text = stripComments(source)
    let output = ''
    let state = 'code'
    let quote = ''
    let escaped = false

    for (const character of text) {
      if (state === 'string') {
        output += character === '\n' ? '\n' : ' '
        if (escaped) {
          escaped = false
        } else if (character === '\\') {
          escaped = true
        } else if (character === quote) {
          state = 'code'
          quote = ''
        }
        continue
      }

      if (character === '"' || character === "'" || character === '`') {
        output += ' '
        state = 'string'
        quote = character
      } else {
        output += character
      }
    }

    return output
  }

  function countMethodCalls (code, method) {
    const safeMethod = String(method).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    const pattern = new RegExp('\\bhero\\s*\\.\\s*' + safeMethod + '\\s*\\(', 'g')
    return (codeOnly(code).match(pattern) || []).length
  }

  function evaluateBooleanDemo (base, mission, result, code) {
    if (!mission.requirements || !mission.requirements.booleanDemo || !result.ok) return base
    const messages = base.messages.slice()
    const says = result.state.says || []

    if (!/\bconst\s+alwaysTrue\s*=\s*true\s*;?/.test(code)) {
      messages.push('const alwaysTrue = true; をそのまま実行しましょう。')
    }
    if (!/\bconst\s+alwaysFalse\s*=\s*false\s*;?/.test(code)) {
      messages.push('const alwaysFalse = false; をそのまま実行しましょう。')
    }
    if ((code.match(/hero\.isTrue\s*\(/g) || []).length < 2) {
      messages.push('hero.isTrue(...) を2回実行しましょう。')
    }
    if (!says.includes(TRUE_MESSAGE)) messages.push('true を hero.isTrue(...) で確かめましょう。')
    if (!says.includes(FALSE_MESSAGE)) messages.push('false を hero.isTrue(...) で確かめましょう。')

    return { passed: messages.length === 0, messages }
  }

  function evaluateSourceCallLimits (base, mission, code) {
    const limits = mission.requirements && mission.requirements.sourceCallLimits
    if (!Array.isArray(limits) || !limits.length) return base
    const messages = base.messages.slice()

    for (const limit of limits) {
      const actual = countMethodCalls(code, limit.method)
      if (actual <= limit.max) continue
      messages.push(
        'コードに hero.' + limit.method + '(...) を書けるのは最大 ' + limit.max +
        ' 回です。今は ' + actual + ' 回あります。ループの中に命令を書いて繰り返しましょう。'
      )
    }

    return { passed: messages.length === 0, messages }
  }

  function apply (engine) {
    if (!engine || engine.__curriculumBooleanApplied) return engine
    const originalSimulate = engine.simulate.bind(engine)
    const originalEvaluate = engine.evaluate.bind(engine)

    engine.simulate = function (code, mission, variantIndex) {
      return originalSimulate(transformCode(code), mission, variantIndex)
    }

    engine.evaluate = function (mission, result, code) {
      const source = String(code)
      const executableSource = stripComments(source)
      const base = originalEvaluate(mission, result, executableSource)
      const booleanEvaluation = evaluateBooleanDemo(base, mission, result, executableSource)
      return evaluateSourceCallLimits(booleanEvaluation, mission, executableSource)
    }

    engine.INVALID_BOOLEAN_MESSAGE = INVALID_BOOLEAN_MESSAGE
    engine.BOOLEAN_TRUE_MESSAGE = TRUE_MESSAGE
    engine.BOOLEAN_FALSE_MESSAGE = FALSE_MESSAGE
    engine.stripComments = stripComments
    engine.countMethodCalls = countMethodCalls
    Object.defineProperty(engine, '__curriculumBooleanApplied', { value: true })
    return engine
  }

  return {
    apply,
    transformCode,
    stripComments,
    countMethodCalls,
    INVALID_BOOLEAN_MESSAGE,
    TRUE_MESSAGE,
    FALSE_MESSAGE
  }
})
