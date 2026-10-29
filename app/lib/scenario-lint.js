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
const LEARN_MODE = 'learn to use'
// Actors of the lines HackStack's live prompt compares against when it decides its instruction is already logged
const SCRIPTED_ACTORS = ['teacher', 'celebrate']

function isLive (step) {
  return step.kind !== 'dead'
}

function isQuiz (step) {
  return !!step.actionData && step.actionData.type === 'prompt-quiz'
}

function isLivePrompt (step) {
  return !!step.actionData && step.actionData.type === 'prompt-live'
}

function isEnd (step) {
  return !!step.actionData && step.actionData.type === 'end-of-lesson'
}

function exitsOf (step) {
  return step.actionData && step.actionData.type === 'end-of-lesson' && Array.isArray(step.actionData.exits) ? step.actionData.exits : []
}

// The same fields HackStack compares (prompt-live-flow sameLine)
function sameLine (a, b) {
  return a.actor === b.actor && a.text === b.text &&
    ['character', 'objective', 'background'].every(field => (a[field] || null) === (b[field] || null))
}

// The steps a player can reach: everything up to and including the first end step, which finishes the level
function reachable (live) {
  const end = live.findIndex(isEnd)
  return end < 0 ? live : live.slice(0, end + 1)
}

// After the script the player prompts freely in every mode but learn when no end step stops it, or when the end
// step offers Keep chatting. An old end step without exits shows Feedback / New Project and never opens free chat.
function hasFreeChat (played, mode) {
  if (mode === LEARN_MODE) { return false }
  const end = played.find(isEnd)
  return !end || exitsOf(end).some(exit => exit.kind === 'free-chat')
}

const OBJECTIVE_EVENTS = {
  'quiz-correct': 'a quiz answered correctly',
  'prompt-replied': "a reply to the player's own prompt",
  default: 'a quiz answered correctly or a reply to a prompt',
}

// HackStack completes an objective on the first event of its kind at or after the line that names it
// (lib/story/objectives): a quiz, or a live prompt or free chat prompt that gets a reply.
function lintObjectives (story, live, steps, mode, findings) {
  const played = reachable(live)
  for (const objective of story.objectives) {
    const at = played.findIndex(step => step.objective === objective.id)
    if (at < 0) { continue }
    const after = played.slice(at)
    const quiz = after.some(isQuiz)
    const prompt = after.some(isLivePrompt) || hasFreeChat(played, mode)
    const completes = objective.kind === 'quiz-correct' ? quiz : objective.kind === 'prompt-replied' ? prompt : quiz || prompt
    if (!completes) {
      const event = OBJECTIVE_EVENTS[objective.kind] || OBJECTIVE_EVENTS.default
      findings.push(finding('objective-never-completes', 'warning', `objective ${objective.id} completes on ${event}, and none can happen after this line; it never gets its ✓`, played[at], steps.indexOf(played[at])))
    }
  }
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
  const liveIndices = steps.map((step, index) => (isLive(step) ? index : -1)).filter(index => index >= 0)

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
    if (isLivePrompt(step) && scenario.mode === LEARN_MODE) {
      findings.push(finding('prompt-live-in-learn', 'warning', 'learn levels never call HackStack otherwise; this live prompt works, but each try costs the player a credit', step, index))
    }
    if (isLivePrompt(step)) {
      const before = steps.slice(0, index).filter(isLive).reverse().find(earlier => SCRIPTED_ACTORS.includes(earlier.actor))
      if (before && sameLine(before, step)) {
        findings.push(finding('live-repeats-line', 'warning', `same text, speaker, character, objective and scene as step ${steps.indexOf(before) + 1}; players see that line in its place, so change one of them`, step, index))
      }
    }
    const playsAfter = liveIndices.filter(later => later > index).length
    if (isEnd(step) && playsAfter) {
      findings.push(finding('steps-after-end', 'warning', `${playsAfter} step${playsAfter === 1 ? '' : 's'} after this end step never play; it finishes the level`, step, index))
    }
    if (scenario.mode === LEARN_MODE && exitsOf(step).some(exit => exit.kind === 'free-chat')) {
      findings.push(finding('free-chat-in-learn', 'warning', 'a learn level ends on Level complete, so the Keep chatting exit is not shown', step, index))
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

  if (live.length && isLivePrompt(live[live.length - 1])) {
    const last = live[live.length - 1]
    findings.push(finding('prompt-live-last', 'info', 'a live prompt as the last step plays like the free chat that follows the script anyway', last, steps.indexOf(last)))
  }

  if (scenario.mode === LEARN_MODE && live.length) {
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
    lintObjectives(story, live, steps, scenario.mode, findings)
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
