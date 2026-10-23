const { lintScript, findingsByKey } = require('lib/scenario-lint')

function step (fields) {
  return Object.assign({ key: `k-${Math.random().toString(36).slice(2, 8)}`, id: null, kind: 'live', actor: 'teacher', text: 'hello', actionData: { type: 'continue' }, documents: [] }, fields)
}

function quiz (text, choices, answerIndex, fields) {
  return step(Object.assign({ actor: 'user', text, actionData: { type: 'prompt-quiz', answerIndex, choices } }, fields))
}

describe('lib/scenario-lint', function () {
  it('finds nothing on a clean script', function () {
    const steps = [
      step({ id: 'a', text: 'welcome' }),
      quiz('Make a game', [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a game', responseText: 'yes' }], 1, { id: 'b' }),
      step({ id: 'c', actor: 'model', text: 'here it is' }),
    ]
    expect(lintScript(steps, { mode: 'learn to use' })).toEqual([])
  })

  it('flags dead ids, duplicates and empty text with the step index', function () {
    const steps = [
      step({ id: 'a', text: 'welcome' }),
      { key: 'dead', id: 'gone', kind: 'dead' },
      step({ id: 'a', text: 'welcome' }),
      step({ id: 'd', text: '   ' }),
    ]
    const codes = lintScript(steps).map(f => [f.code, f.index])
    expect(codes).toEqual([['dead-id', 1], ['duplicate-id', 2], ['empty-text', 3]])
    expect(lintScript(steps)[1].message).toContain('step 1')
  })

  it('checks quiz shape: choices, correct answer, text mismatch, placeholders', function () {
    const steps = [
      quiz('Make a game', [{ text: 'Make a game', responseText: 'yes' }], 0),
      quiz('Make a game', [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a game', responseText: 'yes' }], 7),
      quiz('Make a game', [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a poem', responseText: 'yes' }], 1),
      quiz('How much revenue?', [{ text: 'A', responseText: "that's not right :/" }, { text: 'B', responseText: "that's not right :/" }, { text: 'How much revenue?', responseText: 'yes' }], 2),
    ]
    const found = lintScript(steps)
    expect(found.map(f => f.code)).toEqual(['quiz-few-choices', 'quiz-no-correct', 'quiz-text-mismatch', 'placeholder-distractor'])
    expect(found[3].message).toContain('2 placeholder choices')
  })

  it('reports untranslated steps only when other steps carry translations', function () {
    const none = [step({ id: 'a' }), step({ id: 'b' })]
    expect(lintScript(none)).toEqual([])
    const mixed = [
      step({ id: 'a', i18n: { he: { text: 'x' }, 'zh-HANS': { text: 'y' } } }),
      step({ id: 'b' }),
      { key: 'dead', id: 'gone', kind: 'dead' },
      step({ id: 'c', i18n: { he: { text: 'z' } } }),
    ]
    const found = lintScript(mixed).filter(f => f.code === 'untranslated')
    expect(found.length).toBe(1)
    expect(found[0].index).toBe(1)
    expect(found[0].severity).toBe('info')
    expect(found[0].message).toContain('he, zh-HANS')
  })

  it('warns when a learn level ends on a teacher instruction, and only then', function () {
    const ending = [step({ id: 'a', text: 'now you are ready to write your first ***prompt***!' })]
    expect(lintScript(ending, { mode: 'learn to use' }).map(f => f.code)).toEqual(['learn-ends-on-instruction'])
    expect(lintScript(ending, { mode: 'practice' })).toEqual([])
    const fine = [step({ id: 'a', text: 'prompt me', actor: 'teacher' }), step({ id: 'b', actor: 'model', text: 'done' })]
    expect(lintScript(fine, { mode: 'learn to use' })).toEqual([])
  })

  describe('story checks', function () {
    const story = { isStory: true, characters: [{ id: 'hq', role: 'ally' }, { id: 'local', role: 'npc' }], objectives: [{ id: 'recolor' }], backgrounds: [{ id: 'camp' }], missingWorld: null }

    it('are all skipped without a story context', function () {
      const steps = [
        step({ id: 'a', character: 'ghost', objective: 'nope', background: 'void' }),
        step({ id: 'b', actor: 'user', character: 'local', actionData: { type: 'prompt-input', autoAdvance: 0 } }),
      ]
      expect(lintScript(steps, { mode: 'practice' })).toEqual([])
    })

    it('flag unknown ids, a character on a by-role line and pacing on a non-continue step', function () {
      const steps = [
        step({ id: 'a', character: 'local', objective: 'recolor', background: 'camp' }),
        step({ id: 'b', character: 'ghost' }),
        step({ id: 'c', objective: 'nope' }),
        step({ id: 'd', background: 'void' }),
        step({ id: 'e', actor: 'user', character: 'local' }),
        step({ id: 'f', actor: 'user', actionData: { type: 'prompt-input', autoAdvance: 0 } }),
      ]
      const found = lintScript(steps, { mode: 'practice', story })
      expect(found.map(f => [f.code, f.index])).toEqual([['unknown-character', 1], ['unknown-objective', 2], ['unknown-background', 3], ['character-by-role', 4], ['auto-advance-ignored', 5]])
      expect(found.map(f => f.severity)).toEqual(['warning', 'warning', 'warning', 'warning', 'info'])
      expect(found[0].message).toContain('ghost')
    })

    it('note a story level without any objective, in the modes that show the chip', function () {
      const steps = [step({ id: 'a' }), step({ id: 'b', actor: 'model' })]
      const found = lintScript(steps, { mode: 'practice', story })
      expect(found.map(f => f.code)).toEqual(['no-objective-chip'])
      expect(found[0].index).toBeUndefined()
      expect(lintScript(steps, { mode: 'learn to use', story })).toEqual([])
      expect(lintScript(steps, { mode: 'practice', story: Object.assign({}, story, { isStory: false }) })).toEqual([])
      expect(lintScript([step({ id: 'a', objective: 'recolor' })], { mode: 'practice', story })).toEqual([])
    })

    it('warn once, script-wide, when a world could not be loaded', function () {
      const found = lintScript([step({ id: 'a' })], { story: Object.assign({}, story, { isStory: false, missingWorld: 'lost' }) })
      expect(found.map(f => f.code)).toEqual(['missing-world'])
      expect(found[0].message).toContain('lost')
      expect(found[0].key).toBeUndefined()
    })
  })

  it('groups findings by step key', function () {
    const s = step({ id: 'x', text: '' })
    const grouped = findingsByKey(lintScript([s, { key: 'dead', id: 'gone', kind: 'dead' }]))
    expect(Object.keys(grouped).sort()).toEqual([s.key, 'dead'].sort())
    expect(grouped[s.key][0].code).toBe('empty-text')
  })
})
