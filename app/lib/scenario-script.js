/*
 * Working copy of a scenario's script for the scenario editor.
 *
 * A scenario's script is `initialActionQueue`, message ids in play order; the
 * messages are separate `ai_chat_message` documents. The store loads them into
 * steps, keeps every edit in memory, and writes messages back only in
 * saveMessages(): new steps are POSTed, edited ones PUT (changed fields only),
 * and the queue ids come back for the scenario version the view saves.
 * Deletes wait until that version is saved (applyDeletes), so a failed version
 * save never leaves the published queue pointing at deleted messages. The
 * store never writes the scenario itself.
 *
 * Unsaved work is mirrored to localStorage so a reload can offer it back.
 *
 * Story fields (character, objective, background) are plain ids on the
 * message. In the working copy `null` means "cleared": the PUT sends null and
 * the server removes the field; a new step's POST leaves unset fields out.
 */

const ACTORS = ['teacher', 'user', 'model', 'celebrate', 'alert']
// Player and HackStack lines are resolved by role on the story page; a character id on them is ignored.
const BY_ROLE_ACTORS = ['user', 'model']
const ACTION_TYPES = ['continue', 'prompt-quiz', 'prompt-input', 'end-of-lesson', 'prompt-live']
// Buttons an end step can offer; a new end step starts with Next level only, authors add the rest.
const EXIT_KINDS = ['next-level', 'map', 'free-chat']
const STORY_FIELDS = ['character', 'objective', 'background']
const EDITABLE_FIELDS = ['actor', 'text', 'actionData', ...STORY_FIELDS]
const BACKUP_PREFIX = 'scenario-script-backup:'
const { translatedPaths, staleTranslations } = require('./stale-translations')
const MESSAGE_TRANSLATED_PATHS = translatedPaths(require('schemas/models/ai_chat_message.schema'))

// Same shapes the HackStack builder creates (useInsertTeacherMessage, End lesson).
const STEP_TEMPLATES = {
  teacher: () => ({ actor: 'teacher', text: '', actionData: { type: 'continue' } }),
  model: () => ({ actor: 'model', text: '', actionData: { type: 'continue' } }),
  quiz: () => ({
    actor: 'user',
    text: '',
    actionData: { type: 'prompt-quiz', answerIndex: 0, choices: [{ text: '', responseText: '' }, { text: '', responseText: '' }] },
  }),
  end: () => ({ actor: 'celebrate', text: '', actionData: { type: 'end-of-lesson', exits: [{ kind: 'next-level' }] } }),
  // A teacher line with the prompt box attached: the script goes on once HackStack has replied.
  prompt: () => ({ actor: 'teacher', text: '', actionData: { type: 'prompt-live' } }),
}

function queueIdOf (item) {
  if (typeof item === 'string') { return item }
  return item && item._id ? String(item._id) : null
}

function clone (value) {
  return value === undefined ? undefined : JSON.parse(JSON.stringify(value))
}

// A cleared story field (null) and one never set compare equal, so clearing what was never there is no change.
function editableSnapshot (step) {
  const picked = {}
  for (const field of EDITABLE_FIELDS) { picked[field] = step[field] === null ? undefined : step[field] }
  return JSON.stringify(picked)
}

// Every step has every story key, set or not: Vue observes own keys only, and a backup (JSON) drops undefined ones.
function blankStoryFields () {
  const fields = {}
  for (const field of STORY_FIELDS) { fields[field] = undefined }
  return fields
}

/** The story fields set on a message or step, non-empty strings only. */
function storyFieldsOf (source) {
  const fields = {}
  for (const field of STORY_FIELDS) {
    if (typeof source[field] === 'string' && source[field]) { fields[field] = source[field] }
  }
  return fields
}

/**
 * @param {Object} options
 * @param {Object} options.scenario plain attributes of the loaded scenario version: _id, original, initialActionQueue
 * @param {Function} [options.fetchJson] core/api/fetch-json or a stand-in
 * @param {Object} [options.storage] localStorage or a stand-in with getItem / setItem / removeItem
 * @param {Function} [options.now] clock, for backups
 */
function createScriptStore ({ scenario, fetchJson, storage, now } = {}) {
  if (!scenario || !scenario._id) { throw new Error('createScriptStore needs the scenario attributes with _id') }
  fetchJson = fetchJson || require('core/api/fetch-json')
  storage = storage || (typeof window !== 'undefined' ? window.localStorage : null)
  now = now || (() => Date.now())

  let nextKey = 1
  const state = {
    loaded: false,
    steps: [],
    deleted: [],
    selectedKey: null,
    loadedQueue: [],
  }

  function makeStep (fields, extra) {
    const step = Object.assign({
      key: `step-${nextKey++}`,
      id: null,
      kind: 'new',
      actor: 'teacher',
      text: '',
      actionData: { type: 'continue' },
      documents: [],
      i18n: undefined,
      ownerID: undefined,
    }, blankStoryFields(), clone(fields), extra)
    step.snapshot = step.kind === 'live' ? editableSnapshot(step) : null
    return step
  }

  function stepByKey (key) {
    const step = state.steps.find(s => s.key === key)
    if (!step) { throw new Error(`no step with key ${key}`) }
    return step
  }

  function indexOfKey (key) {
    return state.steps.findIndex(s => s.key === key)
  }

  function isDirty (step) {
    return step.kind === 'live' && editableSnapshot(step) !== step.snapshot
  }

  function buildSteps (queue, messages) {
    const byId = {}
    for (const message of messages) { byId[String(message._id)] = message }
    return queue.map(item => {
      const id = queueIdOf(item)
      const message = id && byId[id]
      if (!message) { return makeStep({}, { id, kind: 'dead' }) }
      return makeStep(Object.assign({
        actor: message.actor,
        text: message.text,
        actionData: message.actionData,
        documents: message.documents,
        i18n: message.i18n,
        ownerID: message.ownerID,
      }, storyFieldsOf(message)), { id, kind: 'live' })
    })
  }

  function touch () {
    writeBackup()
  }

  // ---- loading

  /** Fetch the queue's messages and build the steps. Dead ids become `dead` steps. */
  function load () {
    const queue = (scenario.initialActionQueue || []).slice()
    return fetchJson(`/db/ai_scenario/${scenario._id}/messages`).then(messages => {
      state.steps = buildSteps(queue, messages || [])
      state.deleted = []
      state.loadedQueue = queue.map(queueIdOf)
      state.loaded = true
      state.selectedKey = null
      return state.steps
    })
  }

  // ---- edits

  function select (key) {
    state.selectedKey = key
  }

  function setActor (key, actor) {
    if (!ACTORS.includes(actor)) { throw new Error(`unknown actor ${actor}`) }
    const step = stepByKey(key)
    if (isLivePrompt(step) && actor !== 'teacher') { throw new Error('a live prompt is a teacher line') }
    step.actor = actor
    if (BY_ROLE_ACTORS.includes(actor) && step.character) { step.character = null }
    touch()
  }

  /** `value` is an id or null; blanks clear the field. */
  function setStoryField (key, field, value) {
    if (!STORY_FIELDS.includes(field)) { throw new Error(`unknown story field ${field}`) }
    const trimmed = typeof value === 'string' ? value.trim() : ''
    stepByKey(key)[field] = trimmed || null
    touch()
  }

  /**
   * Pacing of a continue step: null = derived from the queue by the story page,
   * 0 = wait for Continue, a positive integer = auto-advance after that many ms.
   */
  function setAutoAdvance (key, value) {
    const step = stepByKey(key)
    if (!step.actionData || step.actionData.type !== 'continue') { throw new Error(`step ${key} is not a continue action`) }
    // A new actionData object, not a key added or deleted in place: the panel's Vue watchers only see replaced values.
    if (value === null || value === undefined) {
      const next = Object.assign({}, step.actionData)
      delete next.autoAdvance
      step.actionData = next
    } else if (Number.isInteger(value) && value >= 0) {
      step.actionData = Object.assign({}, step.actionData, { autoAdvance: value })
    } else {
      throw new Error(`autoAdvance must be null, 0 or a positive integer of ms, not ${value}`)
    }
    touch()
  }

  function setText (key, text) {
    stepByKey(key).text = text
    touch()
  }

  /**
   * Switching to a quiz adds two empty choices, to an end step the default exits, to a live prompt makes the line a
   * teacher's; switching away keeps only the type.
   */
  function setActionType (key, type) {
    if (!ACTION_TYPES.includes(type)) { throw new Error(`unknown action type ${type}`) }
    const step = stepByKey(key)
    if ((step.actionData || {}).type === type) { return }
    if (type === 'prompt-quiz') {
      step.actionData = STEP_TEMPLATES.quiz().actionData
      if (step.text) { step.actionData.choices[0].text = step.text }
    } else if (type === 'end-of-lesson') {
      step.actionData = STEP_TEMPLATES.end().actionData
    } else {
      step.actionData = { type }
    }
    if (type === 'prompt-live') { step.actor = 'teacher' }
    touch()
  }

  function isLivePrompt (step) {
    return !!step.actionData && step.actionData.type === 'prompt-live'
  }

  function endOf (step) {
    if (!step.actionData || step.actionData.type !== 'end-of-lesson') { throw new Error(`step ${step.key} is not an end step`) }
    return step.actionData
  }

  // Exits and the next level change a new actionData object: the panel's Vue watchers only see replaced values.
  function setExits (step, exits) {
    step.actionData = Object.assign({}, endOf(step), { exits })
    touch()
  }

  function exitsOf (step) {
    return (endOf(step).exits || []).map(exit => Object.assign({}, exit))
  }

  function addExit (key, kind) {
    if (!EXIT_KINDS.includes(kind)) { throw new Error(`unknown exit kind ${kind}`) }
    const step = stepByKey(key)
    setExits(step, exitsOf(step).concat([{ kind }]))
  }

  /** `fields`: kind and/or label; a blank label is removed, so the button shows the default for its kind. */
  function setExit (key, index, fields) {
    const step = stepByKey(key)
    const exits = exitsOf(step)
    if (!exits[index]) { throw new Error(`no exit ${index} on step ${key}`) }
    if (fields.kind !== undefined && !EXIT_KINDS.includes(fields.kind)) { throw new Error(`unknown exit kind ${fields.kind}`) }
    const exit = Object.assign(exits[index], fields)
    if (typeof exit.label === 'string' && !exit.label.trim()) { delete exit.label }
    setExits(step, exits)
  }

  function removeExit (key, index) {
    const step = stepByKey(key)
    const exits = exitsOf(step)
    if (!exits[index]) { throw new Error(`no exit ${index} on step ${key}`) }
    exits.splice(index, 1)
    setExits(step, exits)
  }

  function moveExit (key, index, delta) {
    const step = stepByKey(key)
    const exits = exitsOf(step)
    const to = index + delta
    if (!exits[index] || to < 0 || to >= exits.length) { return false }
    const [exit] = exits.splice(index, 1)
    exits.splice(to, 0, exit)
    setExits(step, exits)
    return true
  }

  /** The scenario `next-level` goes to, by its original; null or blank = the map's next level. */
  function setNextLevel (key, original) {
    const step = stepByKey(key)
    const next = Object.assign({}, endOf(step))
    const trimmed = typeof original === 'string' ? original.trim() : ''
    if (trimmed) { next.nextLevel = trimmed } else { delete next.nextLevel }
    step.actionData = next
    touch()
  }

  function quizOf (step) {
    if (!step.actionData || step.actionData.type !== 'prompt-quiz') { throw new Error(`step ${step.key} is not a prompt quiz`) }
    if (!Array.isArray(step.actionData.choices)) { step.actionData.choices = [] }
    if (typeof step.actionData.answerIndex !== 'number') { step.actionData.answerIndex = 0 }
    return step.actionData
  }

  // The correct choice is the prompt the player sends, so the message text follows it.
  function syncQuizText (step) {
    const quiz = quizOf(step)
    const answer = quiz.choices[quiz.answerIndex]
    if (answer) { step.text = answer.text }
  }

  function setChoice (key, index, fields) {
    const step = stepByKey(key)
    const quiz = quizOf(step)
    if (!quiz.choices[index]) { throw new Error(`no choice ${index} on step ${key}`) }
    Object.assign(quiz.choices[index], fields)
    if (index === quiz.answerIndex) { syncQuizText(step) }
    touch()
  }

  function addChoice (key) {
    const step = stepByKey(key)
    quizOf(step).choices.push({ text: '', responseText: '' })
    touch()
  }

  function removeChoice (key, index) {
    const step = stepByKey(key)
    const quiz = quizOf(step)
    if (quiz.choices.length <= 1) { throw new Error('a quiz keeps at least one choice') }
    quiz.choices.splice(index, 1)
    if (quiz.answerIndex >= quiz.choices.length) { quiz.answerIndex = quiz.choices.length - 1 } else if (index < quiz.answerIndex) { quiz.answerIndex -= 1 }
    syncQuizText(step)
    touch()
  }

  function setAnswerIndex (key, index) {
    const step = stepByKey(key)
    const quiz = quizOf(step)
    if (!quiz.choices[index]) { throw new Error(`no choice ${index} on step ${key}`) }
    quiz.answerIndex = index
    syncQuizText(step)
    touch()
  }

  // ---- queue

  function move (key, delta) {
    const from = indexOfKey(key)
    const to = from + delta
    if (from < 0 || to < 0 || to >= state.steps.length) { return false }
    const [step] = state.steps.splice(from, 1)
    state.steps.splice(to, 0, step)
    touch()
    return true
  }

  /**
   * Insert a fresh step after `afterKey` (null = at the start). `kind` is one
   * of teacher, model, quiz, end. Returns the new step.
   */
  function insertAfter (afterKey, kind) {
    const template = STEP_TEMPLATES[kind]
    if (!template) { throw new Error(`unknown step kind ${kind}`) }
    const step = makeStep(template())
    const at = afterKey === null || afterKey === undefined ? 0 : indexOfKey(afterKey) + 1
    state.steps.splice(at, 0, step)
    state.selectedKey = step.key
    touch()
    return step
  }

  function append (kind) {
    const last = state.steps.length ? state.steps[state.steps.length - 1].key : null
    return insertAfter(last, kind)
  }

  /** A new step with the same content, placed right after the source. Attachments are shared by reference. */
  function duplicate (key) {
    const source = stepByKey(key)
    if (source.kind === 'dead') { throw new Error('cannot duplicate a dead step') }
    const step = makeStep(Object.assign({ actor: source.actor, text: source.text, actionData: source.actionData, documents: source.documents, i18n: source.i18n }, storyFieldsOf(source)))
    state.steps.splice(indexOfKey(key) + 1, 0, step)
    state.selectedKey = step.key
    touch()
    return step
  }

  /** Fetch any message by id and insert a copy of it after `afterKey`. */
  function insertCopyById (afterKey, id) {
    return fetchJson(`/db/ai_chat_message/${id}`).then(message => {
      const step = makeStep(Object.assign({ actor: message.actor, text: message.text, actionData: message.actionData, documents: message.documents, i18n: message.i18n }, storyFieldsOf(message)))
      const at = afterKey === null || afterKey === undefined ? 0 : indexOfKey(afterKey) + 1
      state.steps.splice(at, 0, step)
      state.selectedKey = step.key
      touch()
      return step
    })
  }

  /** Drop the step from the queue; the message document stays. */
  function removeFromQueue (key) {
    const at = indexOfKey(key)
    if (at < 0) { return }
    state.steps.splice(at, 1)
    if (state.selectedKey === key) { state.selectedKey = null }
    touch()
  }

  /** Drop the step and delete its message on save. Other scenarios and running projects lose it too. */
  function deleteMessage (key) {
    const step = stepByKey(key)
    removeFromQueue(key)
    if (step.kind === 'live' && !state.deleted.includes(step.id)) { state.deleted.push(step.id) }
    touch()
  }

  function discard () {
    return load().then(steps => {
      clearBackup()
      return steps
    })
  }

  // ---- state summaries

  function newSteps () { return state.steps.filter(s => s.kind === 'new') }
  function editedSteps () { return state.steps.filter(isDirty) }

  /** The translations the server clears when this edited step is saved: those of a text, choice or exit label that changed. */
  function staleTranslationsOf (step) {
    if (!isDirty(step)) { return [] }
    const before = Object.assign(JSON.parse(step.snapshot), { i18n: step.i18n })
    return staleTranslations(before, { text: step.text, actionData: step.actionData, i18n: step.i18n }, MESSAGE_TRANSLATED_PATHS)
  }

  function queueIds () {
    return state.steps.map(s => s.id)
  }

  function queueChanged () {
    const ids = queueIds()
    if (ids.length !== state.loadedQueue.length) { return true }
    return ids.some((id, i) => id !== state.loadedQueue[i])
  }

  function changes () {
    const added = newSteps()
    const edited = editedSteps()
    const deleted = state.deleted.slice()
    const queue = queueChanged()
    return {
      newSteps: added,
      editedSteps: edited,
      deletedIds: deleted,
      queueChanged: queue,
      count: added.length + edited.length + deleted.length + (queue ? 1 : 0),
      any: added.length > 0 || edited.length > 0 || deleted.length > 0 || queue,
    }
  }

  /** Problems that should block Save (lint covers the softer checks). */
  function validate () {
    const problems = []
    state.steps.forEach((step, i) => {
      if (step.kind === 'dead') { return }
      if (step.kind !== 'new' && !isDirty(step)) { return }
      if (!step.text || !step.text.trim()) { problems.push({ key: step.key, index: i, message: 'empty text' }) }
      if (step.actionData && step.actionData.type === 'prompt-quiz') {
        const quiz = step.actionData
        if (!quiz.choices || quiz.choices.length < 2) { problems.push({ key: step.key, index: i, message: 'a quiz needs at least two choices' }) }
        if (quiz.choices && quiz.choices.some(c => !c.text || !c.text.trim())) { problems.push({ key: step.key, index: i, message: 'empty choice' }) }
      }
      const exits = step.actionData && step.actionData.type === 'end-of-lesson' ? step.actionData.exits : undefined
      if (Array.isArray(exits)) {
        if (!exits.length) { problems.push({ key: step.key, index: i, message: 'an end step needs at least one exit' }) }
        if (exits.some(exit => !EXIT_KINDS.includes(exit && exit.kind))) { problems.push({ key: step.key, index: i, message: 'unknown exit kind' }) }
      }
    })
    return problems
  }

  // ---- saving

  function changedFields (step) {
    const before = JSON.parse(step.snapshot)
    const body = {}
    for (const field of EDITABLE_FIELDS) {
      const value = step[field] === null ? undefined : step[field]
      if (JSON.stringify(value) === JSON.stringify(before[field])) { continue }
      body[field] = value === undefined ? null : value // null asks the server to remove the field
    }
    return body
  }

  function documentIds (step) {
    return (step.documents || []).map(d => (typeof d === 'string' ? d : d._id))
  }

  function markClean (step) {
    step.kind = 'live'
    step.snapshot = editableSnapshot(step)
  }

  function sequence (items, fn) {
    return items.reduce((chain, item) => chain.then(() => fn(item)), Promise.resolve())
  }

  function failAt (step, action) {
    return err => {
      throw Object.assign(err instanceof Error ? err : new Error(err && err.message ? err.message : String(err)), { step, action, code: err && err.code })
    }
  }

  /**
   * Write the pending message changes, in order: new steps POSTed (so the
   * queue has ids), then edited steps PUT with their changed fields. Stops at
   * the first failure; what succeeded stays clean, the rest stays pending.
   * Resolves with the queue ids for the scenario version. The backup stays,
   * now with the saved ids, until the version is in and the view clears it.
   */
  function saveMessages () {
    if (!state.loaded) { return Promise.reject(new Error('the script has not loaded, nothing was written')) }
    const problems = validate()
    if (problems.length) {
      return Promise.reject(Object.assign(new Error(`cannot save: ${problems.map(p => `step ${p.index + 1} ${p.message}`).join(', ')}`), { problems }))
    }
    return sequence(newSteps(), step => {
      const body = Object.assign({
        parent: scenario.original,
        parentKind: 'scenario',
        actor: step.actor,
        text: step.text,
        actionData: step.actionData,
        documents: documentIds(step),
      }, storyFieldsOf(step))
      if (step.i18n) { body.i18n = step.i18n }
      return fetchJson('/db/ai_chat_message', { method: 'POST', json: body }).then(saved => {
        step.id = String(typeof saved === 'string' ? saved : saved._id)
        markClean(step)
      }, failAt(step, 'create'))
    }).then(() => sequence(editedSteps(), step => {
      return fetchJson(`/db/ai_chat_message/${step.id}`, { method: 'PUT', json: changedFields(step) }).then(() => {
        markClean(step)
      }, failAt(step, 'update'))
    })).then(() => {
      writeBackup()
      return queueIds()
    })
  }

  /**
   * DELETE the messages marked for deletion. Run after the scenario version
   * with the new queue is saved; a message that fails to delete stays as an
   * orphan outside every queue, which is harmless.
   */
  function applyDeletes () {
    return sequence(state.deleted.slice(), id => {
      return fetchJson(`/db/ai_chat_message/${id}`, { method: 'DELETE' }).then(() => {
        state.deleted = state.deleted.filter(d => d !== id)
      }, failAt({ id }, 'delete'))
    })
  }

  /** After the view saved the scenario version with new attributes, forget the old queue. */
  function adoptScenario (attributes) {
    scenario = attributes
    state.loadedQueue = (attributes.initialActionQueue || []).map(queueIdOf)
  }

  // ---- backups

  function backupKey () {
    return `${BACKUP_PREFIX}${scenario.original || scenario._id}`
  }

  function writeBackup () {
    if (!storage) { return }
    try {
      if (!changes().any) {
        storage.removeItem(backupKey())
        return
      }
      storage.setItem(backupKey(), JSON.stringify({
        at: now(),
        scenarioId: scenario._id,
        steps: state.steps,
        deleted: state.deleted,
        nextKey,
      }))
    } catch (err) {
      // storage can be full or blocked; the editor still works without backups
    }
  }

  function readBackup () {
    if (!storage) { return null }
    try {
      const raw = storage.getItem(backupKey())
      if (!raw) { return null }
      const backup = JSON.parse(raw)
      // A backup from another version of the scenario would restore a stale queue.
      if (backup.scenarioId !== scenario._id) { return null }
      return backup
    } catch (err) {
      return null
    }
  }

  function restoreFromBackup () {
    const backup = readBackup()
    if (!backup) { return false }
    state.steps = backup.steps.map(step => Object.assign(blankStoryFields(), step))
    state.deleted = backup.deleted || []
    nextKey = Math.max(nextKey, backup.nextKey || 1)
    state.selectedKey = null
    return true
  }

  function clearBackup () {
    if (!storage) { return }
    try { storage.removeItem(backupKey()) } catch (err) { /* see writeBackup */ }
  }

  return {
    state,
    ACTORS,
    BY_ROLE_ACTORS,
    ACTION_TYPES,
    EXIT_KINDS,
    STORY_FIELDS,
    load,
    select,
    setActor,
    setText,
    setActionType,
    setStoryField,
    setAutoAdvance,
    setChoice,
    addChoice,
    removeChoice,
    setAnswerIndex,
    addExit,
    setExit,
    removeExit,
    moveExit,
    setNextLevel,
    move,
    insertAfter,
    append,
    duplicate,
    insertCopyById,
    removeFromQueue,
    deleteMessage,
    discard,
    isDirty,
    changes,
    staleTranslationsOf,
    validate,
    queueIds,
    saveMessages,
    applyDeletes,
    adoptScenario,
    readBackup,
    restoreFromBackup,
    clearBackup,
  }
}

module.exports = { createScriptStore, ACTORS, BY_ROLE_ACTORS, ACTION_TYPES, EXIT_KINDS, STORY_FIELDS, STEP_TEMPLATES, queueIdOf }
