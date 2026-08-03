(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else root.JSQuestSolutionHelp = api
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const METHOD_SIGNATURES = Object.freeze({
    say: 'hero.say(message)',
    move: 'hero.move(direction)',
    transform: 'hero.transform(form)',
    isTrue: 'hero.isTrue(boolean)',
    readSign: 'hero.readSign()',
    look: 'hero.look(direction)',
    canMove: 'hero.canMove(direction)',
    hasKey: 'hero.hasKey()',
    isAtGoal: 'hero.isAtGoal()',
  })

  function isExecutableLine (line) {
    const text = line.trim()
    if (!text || text.startsWith('//')) return false
    if (/^[{}]+;?$/.test(text)) return false
    if (text.endsWith('{')) return false
    return true
  }

  function candidateIndices (lines) {
    const actions = []
    const others = []
    for (let index = lines.length - 1; index >= 0; index--) {
      if (!isExecutableLine(lines[index])) continue
      if (/hero\.[A-Za-z_$][\w$]*\s*\(/.test(lines[index])) actions.push(index)
      else others.push(index)
    }
    return actions.concat(others)
  }

  function lineHint (line) {
    const method = line.match(/hero\.([A-Za-z_$][\w$]*)\s*\(/)?.[1]
    if (method) {
      const signature = METHOD_SIGNATURES[method] || ('hero.' + method + '(...)')
      return 'ヒント: ' + signature + ' を使い、この場所で必要な値を考えよう。'
    }
    if (/\b(const|let)\b/.test(line)) {
      return 'ヒント: 値に分かりやすいローマ字の名前をつけよう。'
    }
    if (/\b(if|else|while|for)\b/.test(line)) {
      return 'ヒント: 条件と波かっこの中で実行する命令を確認しよう。'
    }
    return 'ヒント: 前後のコードとミッションの目的を見て、必要な1行を考えよう。'
  }

  function buildCandidate (mission, lines, targetIndex) {
    const original = lines[targetIndex]
    const indent = original.match(/^\s*/)[0]
    const hints = Array.isArray(mission.hints) ? mission.hints.slice(0, 2) : []
    const header = [
      '// ほぼ完成したコードです。大切な1行だけ、自分で完成させよう。',
      ...hints.map(hint => '// ヒント: ' + hint),
      '',
    ]
    const candidate = lines.slice()
    candidate.splice(
      targetIndex,
      1,
      indent + '// TODO: ここに必要な命令を1行書こう。',
      indent + '// ' + lineHint(original),
    )
    return header.concat(candidate).join('\n')
  }

  function failsAtLeastOneField (code, mission, engine) {
    if (!engine || mission.infiniteLoopDemo) return code !== String(mission.solution || '')
    return mission.variants.some((_, variantIndex) => {
      const result = engine.simulate(code, mission, variantIndex)
      return !engine.evaluate(mission, result, code).passed
    })
  }

  function partialForMission (mission, engine) {
    const solution = String(mission && mission.solution ? mission.solution : '')
    const lines = solution.split('\n')

    for (const index of candidateIndices(lines)) {
      const candidate = buildCandidate(mission, lines, index)
      if (candidate !== solution && failsAtLeastOneField(candidate, mission, engine)) return candidate
    }

    const hints = Array.isArray(mission && mission.hints) ? mission.hints.slice(0, 2) : []
    return [
      '// ほぼ完成したコードの代わりに、重要なヒントを確認しよう。',
      ...hints.map(hint => '// ヒント: ' + hint),
      '// TODO: ミッションを完成させる命令を書こう。',
    ].join('\n')
  }

  return Object.freeze({
    partialForMission,
  })
})
