/*
 * Checks over a scenario script (the steps of lib/scenario-script) that are
 * worth a warning but should not block Save. Pure: steps in, findings out.
 *
 * A finding: { code, severity: 'warning'|'info', index, key, message }.
 * `index` and `key` point at one step; script-wide findings have neither.
 */

const { BY_ROLE_ACTORS } = require('./scenario-script')

const PLACEHOLDER_CHOICE = /^[A-D]$/i
const PLACEHOLDER_FEEDBACK = /that'?s not right/i
const INSTRUCTION = /prompt/i
// Modes whose story page shows the objective chip; a learn level is teacher-led and needs none.
const OBJECTIVE_MODES = ['practice', 'use', 'capstone']

function isLive (step) {
  return step.kind !== 'dead'
}

function isQuiz (step) {
  return !!step.actionData && step.actionData.type === 'prompt-quiz'
}

function languagesOf (step) {
  return Object.keys(step.i18n || {}).filter(lang => lang !== '-')
}

function finding (code, severity, message, step, index) {
  const f = { code, severity, message }
  if (step) {
    f.index = index
    f.key = step.key
  }
  return f
}

// Story references are plain ids; the story page ignores what it cannot resolve, so say so here.
function lintStoryStep (story, step, index, findings) {
  if (step.character) {
    if (BY_ROLE_ACTORS.includes(step.actor)) {
      findings.push(finding('character-by-role', 'warning', `${step.actor} lines are resolved by role; the character ${step.character} is ignored`, step, index))
    } else if (!story.characters.some(c => c.id === step.character)) {
      findings.push(finding('unknown-character', 'warning', `character ${step.character} is not in the scenario or its worlds`, step, index))
    }
  }
  if (step.objective && !story.objectives.some(o => o.id === step.objective)) {
    findings.push(finding('unknown-objective', 'warning', `objective ${step.objective} is not in the scenario's objectives`, step, index))
  }
  if (step.background && !story.backgrounds.some(b => b.id === step.background)) {
    findings.push(finding('unknown-background', 'warning', `scene ${step.background} is not in the scenario or its worlds`, step, index))
  }
  const autoAdvance = step.actionData && step.actionData.autoAdvance
  if (autoAdvance !== undefined && autoAdvance !== null && step.actionData.type !== 'continue') {
    findings.push(finding('auto-advance-ignored', 'info', 'pacing (autoAdvance) only applies to a Continue step', step, index))
  }
}

/**
 * @param {Array<Object>} steps from lib/scenario-script state.steps
 * @param {{mode?: string, story?: Object}} [scenario] mode decides the learn-level ending check;
 *   story (lib/story-world-chain buildStoryContext) turns on the story checks
 * @returns {Array<Object>} findings, in step order, script-wide ones last
 */
function lintScript (steps, scenario = {}) {
  const findings = []
  const seen = {}
  const story = scenario.story

  steps.forEach((step, index) => {
    if (step.kind === 'dead') {
      findings.push(finding('dead-id', 'warning', 'points to a deleted message; players skip it', step, index))
      return
    }
    if (step.id) {
      if (seen[step.id]) { findings.push(finding('duplicate-id', 'warning', `same message as step ${seen[step.id]}; edits change both`, step, index)) } else { seen[step.id] = index + 1 }
    }
    if (!step.text || !step.text.trim()) {
      findings.push(finding('empty-text', 'warning', 'empty text', step, index))
    }
    if (isQuiz(step)) {
      const quiz = step.actionData
      const choices = Array.isArray(quiz.choices) ? quiz.choices : []
      if (choices.length < 2) {
        findings.push(finding('quiz-few-choices', 'warning', `quiz with ${choices.length} choice${choices.length === 1 ? '' : 's'}`, step, index))
      }
      const answer = typeof quiz.answerIndex === 'number' ? choices[quiz.answerIndex] : null
      if (!answer) {
        findings.push(finding('quiz-no-correct', 'warning', 'quiz without a correct choice', step, index))
      } else if ((answer.text || '').trim() !== (step.text || '').trim()) {
        findings.push(finding('quiz-text-mismatch', 'warning', 'message text differs from the correct choice', step, index))
      }
      const placeholders = choices.filter(c => PLACEHOLDER_CHOICE.test((c.text || '').trim()) || PLACEHOLDER_FEEDBACK.test(c.responseText || ''))
      if (placeholders.length) {
        findings.push(finding('placeholder-distractor', 'warning', `${placeholders.length} placeholder choice${placeholders.length === 1 ? '' : 's'} (A/B/C/D or "that's not right")`, step, index))
      }
    }
    if (story) { lintStoryStep(story, step, index, findings) }
  })

  const live = steps.filter(isLive)
  const translated = live.filter(step => languagesOf(step).length)
  if (translated.length && translated.length < live.length) {
    const langs = Array.from(new Set(translated.reduce((all, step) => all.concat(languagesOf(step)), []))).sort()
    live.forEach(step => {
      if (languagesOf(step).length) { return }
      findings.push(finding('untranslated', 'info', `no translations while other steps have ${langs.join(', ')}`, step, steps.indexOf(step)))
    })
  }

  if (scenario.mode === 'learn to use' && live.length) {
    const last = live[live.length - 1]
    if (last.actor === 'teacher' && INSTRUCTION.test(last.text || '')) {
      findings.push(finding('learn-ends-on-instruction', 'info', 'learn level ends on an instruction; the player sees Level complete with no input', last, steps.indexOf(last)))
    }
  }

  if (story) {
    if (story.missingWorld) {
      findings.push(finding('missing-world', 'warning', `world ${story.missingWorld} could not be loaded; its characters and scenes are not offered`))
    }
    if (story.isStory && OBJECTIVE_MODES.includes(scenario.mode) && live.length && !live.some(step => step.objective)) {
      findings.push(finding('no-objective-chip', 'info', 'story level with no objective on any step; the player sees no goal chip'))
    }
  }

  return findings
}

/** Findings grouped by step key, for chips on the cards. */
function findingsByKey (findings) {
  const byKey = {}
  for (const f of findings) {
    if (!f.key) { continue }
    if (!byKey[f.key]) { byKey[f.key] = [] }
    byKey[f.key].push(f)
  }
  return byKey
}

module.exports = { lintScript, findingsByKey }
