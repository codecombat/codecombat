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

  function installWorkerAdapter (rootObject, engine) {
    if (!rootObject || !rootObject.Worker || rootObject.Worker.__jsQuestBooleanAdapter) return
    const NativeWorker = rootObject.Worker

    function AdaptedWorker () {
      const worker = Reflect.construct(NativeWorker, Array.from(arguments))
      const nativePostMessage = worker.postMessage.bind(worker)
      let lastPayload = null
      let userOnMessage = null
      let listenerInstalled = false

      worker.postMessage = function (payload) {
        lastPayload = payload
        const forwarded = payload && typeof payload === 'object'
          ? Object.assign({}, payload, { code: transformCode(payload.code) })
          : payload
        return nativePostMessage(forwarded)
      }

      Object.defineProperty(worker, 'onmessage', {
        configurable: true,
        enumerable: true,
        get: function () { return userOnMessage },
        set: function (handler) {
          userOnMessage = handler
          if (listenerInstalled) return
          listenerInstalled = true
          worker.addEventListener('message', event => {
            if (typeof userOnMessage !== 'function') return
            let data = event.data
            if (lastPayload && data && data.result) {
              data = Object.assign({}, data, {
                evaluation: engine.evaluate(lastPayload.mission, data.result, lastPayload.code)
              })
            }
            userOnMessage.call(worker, { data })
          })
        }
      })

      return worker
    }

    AdaptedWorker.prototype = NativeWorker.prototype
    Object.setPrototypeOf(AdaptedWorker, NativeWorker)
    Object.defineProperty(AdaptedWorker, '__jsQuestBooleanAdapter', { value: true })
    rootObject.Worker = AdaptedWorker
  }

  function apply (engine) {
    if (!engine || engine.__curriculumBooleanApplied) return engine
    const originalSimulate = engine.simulate.bind(engine)
    const originalEvaluate = engine.evaluate.bind(engine)

    engine.simulate = function (code, mission, variantIndex) {
      return originalSimulate(transformCode(code), mission, variantIndex)
    }

    engine.evaluate = function (mission, result, code) {
      const base = originalEvaluate(mission, result, code)
      return evaluateBooleanDemo(base, mission, result, String(code))
    }

    engine.INVALID_BOOLEAN_MESSAGE = INVALID_BOOLEAN_MESSAGE
    engine.BOOLEAN_TRUE_MESSAGE = TRUE_MESSAGE
    engine.BOOLEAN_FALSE_MESSAGE = FALSE_MESSAGE
    Object.defineProperty(engine, '__curriculumBooleanApplied', { value: true })

    if (typeof window !== 'undefined') installWorkerAdapter(window, engine)
    return engine
  }

  return {
    apply,
    transformCode,
    INVALID_BOOLEAN_MESSAGE,
    TRUE_MESSAGE,
    FALSE_MESSAGE
  }
})
