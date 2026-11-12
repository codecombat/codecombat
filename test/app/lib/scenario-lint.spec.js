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

    it('warn about an objective that nothing after its line can complete', function () {
      const objectives = [{ id: 'make-a-game', kind: 'quiz-correct' }, { id: 'recolor', kind: 'prompt-replied' }, { id: 'gift', kind: null }]
      const context = Object.assign({}, story, { objectives })
      const never = (steps, mode) => lintScript(steps, { mode, story: context }).filter(f => f.code === 'objective-never-completes').map(f => [f.index, f.severity])
      const answer = quiz('Make a game', [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a game', responseText: 'yes' }], 1)
      const livePrompt = step({ text: '***prompt*** HackStack to change the star.', actionData: { type: 'prompt-live' } })

      // learn: no free chat, so only the steps after the line count
      expect(never([step({ objective: 'make-a-game' }), answer], 'learn to use')).toEqual([])
      expect(never([answer, step({ objective: 'make-a-game' })], 'learn to use')).toEqual([[1, 'warning']])
      expect(never([step({ objective: 'recolor' }), answer], 'learn to use')).toEqual([[0, 'warning']])
      expect(never([step({ objective: 'recolor' }), livePrompt], 'learn to use')).toEqual([])
      expect(never([step({ objective: 'gift' }), answer], 'learn to use')).toEqual([])
      expect(never([step({ objective: 'gift' })], 'learn to use')).toEqual([[0, 'warning']])
      // a quiz step that names the objective completes it itself
      expect(never([quiz('Make a game', [{ text: 'Make a game', responseText: 'yes' }], 0, { objective: 'make-a-game' })], 'learn to use')).toEqual([])

      // practice: free chat follows the script, unless an end step ends the level without Keep chatting
      expect(never([step({ objective: 'recolor' })], 'practice')).toEqual([])
      expect(never([step({ objective: 'make-a-game' })], 'practice')).toEqual([[0, 'warning']])
      const endWith = kinds => step({ actor: 'celebrate', text: 'done', actionData: { type: 'end-of-lesson', exits: kinds.map(kind => ({ kind })) } })
      expect(never([step({ objective: 'recolor' }), endWith(['next-level', 'map'])], 'practice')).toEqual([[0, 'warning']])
      expect(never([step({ objective: 'recolor' }), endWith(['next-level', 'free-chat'])], 'practice')).toEqual([])
      // an old end step without exits shows Feedback / New Project, never free chat
      const oldEnd = step({ actor: 'celebrate', text: 'done', actionData: { type: 'end-of-lesson' } })
      expect(never([step({ objective: 'recolor' }), oldEnd], 'practice')).toEqual([[0, 'warning']])
      // nothing after the first end step plays, so a quiz there completes nothing
      expect(never([step({ objective: 'make-a-game' }), endWith(['map']), answer], 'practice')).toEqual([[0, 'warning']])
      expect(never([step({ objective: 'make-a-game' }), answer, endWith(['map'])], 'practice')).toEqual([])

      // an objective no line names gets no warning here
      expect(never([step()], 'learn to use')).toEqual([])
      expect(lintScript([step({ objective: 'gift' })], { mode: 'learn to use', story: context })[0].message).toContain('gift')
    })

    it('warn once, script-wide, when a world could not be loaded', function () {
      const found = lintScript([step({ id: 'a' })], { story: Object.assign({}, story, { isStory: false, missingWorld: 'lost' }) })
      expect(found.map(f => f.code)).toEqual(['missing-world'])
      expect(found[0].message).toContain('lost')
      expect(found[0].key).toBeUndefined()
    })
  })

  describe('live prompts and end exits', function () {
    const live = fields => step(Object.assign({ text: '***prompt*** HackStack to change the star.', actionData: { type: 'prompt-live' } }, fields))
    const end = (exits, fields) => step(Object.assign({ actor: 'celebrate', text: 'done!', actionData: { type: 'end-of-lesson', exits } }, fields))

    it('warn about a live prompt in a learn level, which costs a credit there', function () {
      const steps = [live({ id: 'a' }), step({ id: 'b', text: 'nice' })]
      expect(lintScript(steps, { mode: 'learn to use' }).map(f => [f.code, f.severity, f.index])).toEqual([['prompt-live-in-learn', 'warning', 0]])
      expect(lintScript(steps, { mode: 'practice' })).toEqual([])
    })

    it('warn about a live prompt that repeats the last scripted line before it', function () {
      const repeats = code => lintScript(code, { mode: 'practice' }).filter(f => f.code === 'live-repeats-line')
      const earlier = step({ id: 'a', text: 'Remix this', objective: 'recolor' })
      const reply = step({ id: 'b', actor: 'model', text: 'here it is' })
      const found = repeats([earlier, reply, live({ id: 'c', text: 'Remix this', objective: 'recolor' }), step({ id: 'd' })])
      expect(found.map(f => [f.severity, f.index])).toEqual([['warning', 2]])
      expect(found[0].message).toContain('step 1')
      // another scene, or another scripted line in between, tells them apart
      expect(repeats([earlier, reply, live({ id: 'c', text: 'Remix this', objective: 'recolor', background: 'camp' }), step({ id: 'd' })])).toEqual([])
      expect(repeats([earlier, step({ id: 'e', text: 'Now you' }), live({ id: 'c', text: 'Remix this', objective: 'recolor' }), step({ id: 'd' })])).toEqual([])
    })

    it('note a live prompt as the last step', function () {
      const steps = [step({ id: 'a' }), live({ id: 'b' }), { key: 'dead', id: 'gone', kind: 'dead' }]
      const found = lintScript(steps, { mode: 'practice' }).filter(f => f.code === 'prompt-live-last')
      expect(found.map(f => [f.severity, f.index])).toEqual([['info', 1]])
    })

    it('warn about steps after an end step, with or without exits, which never play', function () {
      const steps = [step({ id: 'a' }), end([{ kind: 'map' }], { id: 'b' }), step({ id: 'c' }), { key: 'dead', id: 'gone', kind: 'dead' }, step({ id: 'd' })]
      const found = lintScript(steps, { mode: 'practice' }).filter(f => f.code === 'steps-after-end')
      expect(found.map(f => [f.severity, f.index])).toEqual([['warning', 1]])
      expect(found[0].message).toContain('2 steps')
      expect(lintScript([step({ id: 'a' }), end(undefined, { id: 'b' }), step({ id: 'c' })], { mode: 'practice' }).map(f => f.code)).toEqual(['steps-after-end'])
      expect(lintScript([step({ id: 'a' }), end([{ kind: 'map' }], { id: 'b' })], { mode: 'practice' })).toEqual([])
    })

    it('warn about a Keep chatting exit in a learn level, where it is not shown', function () {
      const steps = [step({ id: 'a' }), end([{ kind: 'next-level' }, { kind: 'free-chat' }], { id: 'b' })]
      expect(lintScript(steps, { mode: 'learn to use' }).map(f => [f.code, f.index])).toEqual([['free-chat-in-learn', 1]])
      expect(lintScript(steps, { mode: 'use' })).toEqual([])
      expect(lintScript([end(undefined, { id: 'c' })], { mode: 'learn to use' })).toEqual([])
    })
  })

  it('groups findings by step key', function () {
    const s = step({ id: 'x', text: '' })
    const grouped = findingsByKey(lintScript([s, { key: 'dead', id: 'gone', kind: 'dead' }]))
    expect(Object.keys(grouped).sort()).toEqual([s.key, 'dead'].sort())
    expect(grouped[s.key][0].code).toBe('empty-text')
  })
})
