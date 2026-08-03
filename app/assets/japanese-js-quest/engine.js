(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else root.JSQuestEngine = api
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const DIRECTIONS = {
    right: [1, 0],
    left: [-1, 0],
    up: [0, -1],
    down: [0, 1]
  }

  const TILE_NAMES = {
    '#': 'wall',
    '.': 'empty',
    H: 'empty',
    G: 'goal',
    '*': 'gem',
    K: 'key',
    D: 'door',
    T: 'trap',
    E: 'enemy'
  }

  const LOCKED_POWER_MESSAGE = 'この技はまだ使えないよ。'
  const INVALID_DIRECTION_MESSAGE = 'どの方向へ進めばいいのか、わからないよ。direction は "right"、"left"、"up"、"down" のどれかにしてね。'
  const INVALID_TRANSFORM_MESSAGE = '何に変身すればいいのか、わからないよ。'
  const FORM_LEVELS = Object.freeze({ hero: 1, frog: 1, dragon: 99 })
  const ALLOWED_FORMS = Object.freeze(Object.keys(FORM_LEVELS))

  function cloneGrid (rows) {
    const width = rows[0].length
    if (!rows.length || rows.some(row => row.length !== width)) {
      throw new Error('Mission map rows must have the same width.')
    }
    return rows.map(row => row.split(''))
  }

  function locateHero (grid) {
    for (let y = 0; y < grid.length; y++) {
      for (let x = 0; x < grid[y].length; x++) {
        if (grid[y][x] === 'H') {
          grid[y][x] = '.'
          return { x, y }
        }
      }
    }
    throw new Error('Mission map must contain one H tile.')
  }

  function createState (mission, variantIndex) {
    const variants = mission.variants || []
    if (!variants.length) throw new Error('Mission must contain at least one variant.')
    const safeIndex = ((variantIndex || 0) % variants.length + variants.length) % variants.length
    const variant = variants[safeIndex]
    const grid = cloneGrid(variant.map)
    const hero = locateHero(grid)
    return {
      missionId: mission.id,
      variantIndex: safeIndex,
      variant,
      width: grid[0].length,
      height: grid.length,
      grid,
      hero,
      form: 'hero',
      wizardLevel: Number(mission.wizardLevel) || 0,
      moves: 0,
      operations: 0,
      failedMoves: 0,
      trapHits: 0,
      gems: 0,
      hasKey: false,
      doorOpened: false,
      goalReached: false,
      says: [],
      trace: [],
      logs: []
    }
  }

  function tileAt (state, x, y) {
    if (y < 0 || y >= state.height || x < 0 || x >= state.width) return '#'
    return state.grid[y][x]
  }

  function isBlocked (state, tile) {
    if (tile === '#' || tile === 'E') return true
    if (tile === 'D' && !state.hasKey) return true
    return false
  }

  function touch (state) {
    state.operations++
    if (state.operations > 600) {
      throw new Error('命令が多すぎます。ループが終わる条件を確認してください。')
    }
  }

  function snapshot (state, extra) {
    return Object.assign({
      x: state.hero.x,
      y: state.hero.y,
      grid: state.grid.map(row => row.join('')),
      form: state.form,
      wizardLevel: state.wizardLevel,
      moves: state.moves,
      gems: state.gems,
      hasKey: state.hasKey,
      trapHits: state.trapHits,
      goalReached: state.goalReached,
      says: state.says.slice()
    }, extra || {})
  }

  function speak (state, message, extra) {
    touch(state)
    const text = String(message)
    state.says.push(text)
    state.logs.push(text)
    state.trace.push(snapshot(state, Object.assign({ type: 'say', speech: text }, extra || {})))
    return text
  }

  function failWithSpeech (state, message, errorCode) {
    speak(state, message, { commandError: errorCode })
    const error = new Error(message)
    error.jsQuestSpoken = true
    error.code = errorCode
    throw error
  }

  function requireNoArguments (state, methodName, args) {
    if (args.length === 0) return
    failWithSpeech(
      state,
      'hero.' + methodName + '() には、かっこの中の情報はいらないよ。',
      'unexpected-parameter'
    )
  }

  function requireDirectionArgument (state, args) {
    if (args.length !== 1) {
      failWithSpeech(state, INVALID_DIRECTION_MESSAGE, 'invalid-direction')
    }
    return args[0]
  }

  function directionDelta (state, direction) {
    const delta = typeof direction === 'string' ? DIRECTIONS[direction] : null
    if (!delta) failWithSpeech(state, INVALID_DIRECTION_MESSAGE, 'invalid-direction')
    return delta
  }

  function move (state, direction) {
    const [dx, dy] = directionDelta(state, direction)
    touch(state)
    const nx = state.hero.x + dx
    const ny = state.hero.y + dy
    const tile = tileAt(state, nx, ny)

    if (isBlocked(state, tile)) {
      state.failedMoves++
      state.trace.push(snapshot(state, { type: 'blocked', direction, tile: TILE_NAMES[tile] || tile }))
      return false
    }

    if (tile === 'D') {
      state.grid[ny][nx] = '.'
      state.doorOpened = true
    }

    state.hero.x = nx
    state.hero.y = ny
    state.moves++

    if (tile === '*') {
      state.gems++
      state.grid[ny][nx] = '.'
    } else if (tile === 'K') {
      state.hasKey = true
      state.grid[ny][nx] = '.'
    } else if (tile === 'T') {
      state.trapHits++
    } else if (tile === 'G') {
      state.goalReached = true
    }

    state.trace.push(snapshot(state, { type: 'move', direction, tile: TILE_NAMES[tile] || tile }))
    return true
  }

  function inspect (state, direction) {
    const [dx, dy] = directionDelta(state, direction)
    touch(state)
    const tile = tileAt(state, state.hero.x + dx, state.hero.y + dy)
    return TILE_NAMES[tile] || 'unknown'
  }

  function canMove (state, direction) {
    const [dx, dy] = directionDelta(state, direction)
    touch(state)
    return !isBlocked(state, tileAt(state, state.hero.x + dx, state.hero.y + dy))
  }

  function transform (state, args) {
    if (args.length !== 1 || typeof args[0] !== 'string') {
      failWithSpeech(state, INVALID_TRANSFORM_MESSAGE, 'invalid-transform')
    }

    const target = args[0]
    const requiredLevel = FORM_LEVELS[target]
    if (requiredLevel == null) {
      failWithSpeech(state, INVALID_TRANSFORM_MESSAGE, 'invalid-transform')
    }
    if (state.wizardLevel < requiredLevel) {
      speak(state, LOCKED_POWER_MESSAGE, {
        blockedPower: 'transform',
        requestedForm: target,
        requiredLevel
      })
      return false
    }

    touch(state)
    state.form = target
    state.trace.push(snapshot(state, { type: 'transform', form: target }))
    return true
  }

  function say (state, args) {
    if (args.length !== 1 || typeof args[0] !== 'string') {
      failWithSpeech(
        state,
        '何を言えばいいのか、わからないよ。hero.say("話す言葉") のように、文字列を1つ入れてね。',
        'invalid-say'
      )
    }
    return speak(state, args[0])
  }

  function unknownMethod (state, property) {
    const name = String(property)
    return function () {
      failWithSpeech(
        state,
        '「hero.' + name + '」という命令はわからないよ。つづりを確認してね。',
        'unknown-method'
      )
    }
  }

  function createHeroApi (state) {
    const methods = Object.freeze({
      move: function () { return move(state, requireDirectionArgument(state, arguments)) },
      canMove: function () { return canMove(state, requireDirectionArgument(state, arguments)) },
      look: function () { return inspect(state, requireDirectionArgument(state, arguments)) },
      readSign: function () {
        requireNoArguments(state, 'readSign', arguments)
        touch(state)
        return state.variant.sign
      },
      hasKey: function () {
        requireNoArguments(state, 'hasKey', arguments)
        touch(state)
        return state.hasKey
      },
      gemCount: function () {
        requireNoArguments(state, 'gemCount', arguments)
        touch(state)
        return state.gems
      },
      isAtGoal: function () {
        requireNoArguments(state, 'isAtGoal', arguments)
        touch(state)
        return state.goalReached
      },
      x: function () {
        requireNoArguments(state, 'x', arguments)
        touch(state)
        return state.hero.x
      },
      y: function () {
        requireNoArguments(state, 'y', arguments)
        touch(state)
        return state.hero.y
      },
      say: function () { return say(state, Array.from(arguments)) },
      transform: function () { return transform(state, Array.from(arguments)) }
    })

    return new Proxy(methods, {
      get: function (target, property) {
        if (Object.prototype.hasOwnProperty.call(target, property)) return target[property]
        if (typeof property === 'symbol') return target[property]
        return unknownMethod(state, property)
      },
      set: function () { return false }
    })
  }

  function simulate (code, mission, variantIndex) {
    const state = createState(mission, variantIndex)
    const hero = createHeroApi(state)
    const safeConsole = Object.freeze({
      log: (...values) => state.logs.push(values.map(String).join(' '))
    })

    try {
      const runner = new Function(
        'hero', 'console', 'window', 'document', 'self', 'globalThis',
        'fetch', 'XMLHttpRequest', 'WebSocket', 'Worker', 'Function',
        '"use strict";\n' + code
      )
      runner(hero, safeConsole, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined)
      return { ok: true, state: snapshot(state), trace: state.trace, logs: state.logs }
    } catch (error) {
      return {
        ok: false,
        state: snapshot(state),
        trace: state.trace,
        logs: state.logs,
        error: {
          name: error.name || 'Error',
          message: error.message || String(error),
          code: error.code || null,
          spoken: Boolean(error.jsQuestSpoken)
        }
      }
    }
  }

  const SYNTAX_CHECKS = {
    say: code => /hero\.say\s*\(/.test(code),
    transform: code => /hero\.transform\s*\(/.test(code),
    moveParameter: code => /hero\.move\s*\(\s*["'`](right|left|up|down)["'`]\s*\)/.test(code),
    if: code => /\bif\s*\(/.test(code),
    else: code => /\belse\b/.test(code),
    elseIf: code => /\belse\s+if\s*\(/.test(code),
    comparison: code => /(===|!==|==|!=|>=|<=|>|<)/.test(code),
    logicalAnd: code => /&&/.test(code),
    logicalOr: code => /\|\|/.test(code),
    forLoop: code => /\bfor\s*\(/.test(code),
    whileLoop: code => /\bwhile\s*\(/.test(code),
    anyLoop: code => /\b(for|while)\s*\(/.test(code),
    nestedLoops: code => ((code.match(/\b(for|while)\s*\(/g) || []).length >= 2),
    variable: code => /\b(let|const)\s+[A-Za-z_$]/.test(code),
    canMove: code => /hero\.canMove\s*\(/.test(code),
    look: code => /hero\.look\s*\(/.test(code),
    readSign: code => /hero\.readSign\s*\(/.test(code),
    hasKey: code => /hero\.hasKey\s*\(/.test(code),
    isAtGoal: code => /hero\.isAtGoal\s*\(/.test(code)
  }

  function normalizeText (value) {
    return String(value).trim().replace(/\s+/g, ' ').toLowerCase()
  }

  function evaluate (mission, result, code) {
    const messages = []
    if (!result.ok) {
      messages.push(result.error.spoken ? '命令を直して、もう一度ためしてみよう。' : 'コードエラー: ' + result.error.message)
      return { passed: false, messages }
    }

    const rules = mission.requirements || {}
    const stateRules = rules.state || {}
    const state = result.state

    if (stateRules.goal && !state.goalReached) messages.push('まだゴールに着いていません。')
    if (stateRules.minGems != null && state.gems < stateRules.minGems) {
      messages.push('宝石をあと ' + (stateRules.minGems - state.gems) + ' 個集めましょう。')
    }
    if (stateRules.key && !state.hasKey) messages.push('カギを取っていません。')
    if (stateRules.noTrap && state.trapHits > 0) messages.push('ワナを踏まずに進みましょう。')
    if (stateRules.maxMoves != null && state.moves > stateRules.maxMoves) {
      messages.push('移動が多すぎます（最大 ' + stateRules.maxMoves + ' 回）。')
    }
    if (stateRules.sayText != null) {
      const expected = normalizeText(stateRules.sayText)
      const said = (state.says || []).some(message => normalizeText(message) === expected)
      if (!said) messages.push('hero.say(...) で「' + stateRules.sayText + '」と言ってみましょう。')
    }

    for (const syntax of rules.syntax || []) {
      const checker = SYNTAX_CHECKS[syntax.type]
      if (checker && !checker(code)) messages.push(syntax.message)
    }

    return { passed: messages.length === 0, messages }
  }

  return {
    DIRECTIONS,
    TILE_NAMES,
    LOCKED_POWER_MESSAGE,
    INVALID_DIRECTION_MESSAGE,
    INVALID_TRANSFORM_MESSAGE,
    FORM_LEVELS,
    ALLOWED_FORMS,
    createState,
    simulate,
    evaluate
  }
})
