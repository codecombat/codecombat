(function (root) {
  'use strict'

  if (typeof document !== 'undefined' && !document.querySelector('link[href="adventure-ui.css"]')) {
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = 'adventure-ui.css'
    document.head.appendChild(link)
  }

  const engine = root.JSQuestEngine
  if (!engine || engine.__guarded) return

  if (Array.isArray(engine.ALLOWED_FORMS) && !engine.ALLOWED_FORMS.includes('dragon')) {
    engine.ALLOWED_FORMS.push('dragon')
  }

  const originalSimulate = engine.simulate.bind(engine)
  const directionMessage = '方向がわからないよ。right、left、up、down のどれかを使ってね。'
  const unknownMethodMessage = name => '「hero.' + name + '」という命令はわからないよ。つづりを確認してね。'
  const noArgumentMessage = name => 'hero.' + name + '() には、かっこの中の情報はいらないよ。'
  const sayMessage = 'hero.say(message) には、言ってほしい文字列を一つ入れてね。'
  const transformMessage = '何に変身すればいいのかわからないよ。'
  const lockedPowerMessage = 'この技はまだ使えないよ。'

  const knownMethods = new Set([
    'move', 'canMove', 'look', 'readSign', 'hasKey', 'gemCount',
    'isAtGoal', 'x', 'y', 'say', 'transform'
  ])
  const noArgumentMethods = new Set(['readSign', 'hasKey', 'gemCount', 'isAtGoal', 'x', 'y'])
  const directionMethods = new Set(['move', 'canMove', 'look'])
  const validDirections = new Set(['right', 'left', 'up', 'down'])

  function splitArguments (source) {
    if (!source.trim()) return []
    return source.split(',').map(value => value.trim())
  }

  function quotedValue (source) {
    const match = source.match(/^(['"])([\s\S]*)\1$/)
    return match ? match[2] : null
  }

  function speechExpression (message) {
    return 'hero.say(' + JSON.stringify(message) + ')'
  }

  function preprocess (code, mission) {
    return String(code).replace(/hero\.([A-Za-z_$][\w$]*)\s*\(([^()]*)\)/g, (whole, name, rawArguments) => {
      if (!knownMethods.has(name)) return speechExpression(unknownMethodMessage(name))

      const args = splitArguments(rawArguments)
      if (noArgumentMethods.has(name) && args.length > 0) return speechExpression(noArgumentMessage(name))

      if (directionMethods.has(name)) {
        if (args.length !== 1) return speechExpression(directionMessage)
        const literal = quotedValue(args[0])
        if (literal !== null && !validDirections.has(literal)) return speechExpression(directionMessage)
      }

      if (name === 'say' && (args.length !== 1 || quotedValue(args[0]) === null)) {
        return speechExpression(sayMessage)
      }

      if (name === 'transform') {
        if (args.length !== 1) return speechExpression(transformMessage)
        const form = quotedValue(args[0])
        if (form === null) return whole
        if (!['hero', 'frog', 'dragon'].includes(form)) return speechExpression(transformMessage)
        const requiredLevel = form === 'dragon' ? 99 : 1
        if ((Number(mission.wizardLevel) || 0) < requiredLevel) return speechExpression(lockedPowerMessage)
      }

      return whole
    })
  }

  function appendFailureSpeech (result, message) {
    const state = result.state || {}
    const text = String(message)
    state.says = Array.isArray(state.says) ? state.says.concat(text) : [text]
    result.logs = Array.isArray(result.logs) ? result.logs.concat(text) : [text]
    result.trace = Array.isArray(result.trace) ? result.trace : []
    result.trace.push({
      type: 'say',
      speech: text,
      x: state.x,
      y: state.y,
      grid: state.grid,
      form: state.form || 'hero',
      wizardLevel: state.wizardLevel,
      moves: state.moves || 0,
      gems: state.gems || 0,
      hasKey: Boolean(state.hasKey),
      trapHits: state.trapHits || 0,
      goalReached: Boolean(state.goalReached),
      says: state.says
    })
    return result
  }

  function understandableError (result) {
    if (result.ok || !result.error) return result
    const message = String(result.error.message || '')
    if (/方向は/.test(message)) return appendFailureSpeech(result, directionMessage)
    if (/is not a function/.test(message)) {
      const match = message.match(/hero\.([A-Za-z_$][\w$]*)/)
      return appendFailureSpeech(result, unknownMethodMessage(match ? match[1] : '???'))
    }
    if (/form は/.test(message)) return appendFailureSpeech(result, transformMessage)
    return result
  }

  engine.simulate = function (code, mission, variantIndex) {
    return understandableError(originalSimulate(preprocess(code, mission), mission, variantIndex))
  }

  engine.ERROR_MESSAGES = Object.freeze({
    direction: directionMessage,
    transform: transformMessage,
    lockedPower: lockedPowerMessage
  })
  Object.defineProperty(engine, '__guarded', { value: true })
})(typeof self !== 'undefined' ? self : this)
