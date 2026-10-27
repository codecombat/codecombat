const { createScriptStore } = require('lib/scenario-script')

// A stand-in for core/api/fetch-json: routes "METHOD url" to a handler and records every call.
function makeFetch (routes) {
  const calls = []
  const fetchJson = (url, options = {}) => {
    const method = options.method || 'GET'
    calls.push({ method, url, json: options.json })
    const handler = routes[`${method} ${url}`] || routes[`${method} *`]
    if (!handler) { return Promise.reject(Object.assign(new Error(`no route for ${method} ${url}`), { code: 404 })) }
    try {
      return Promise.resolve(handler({ url, method, json: options.json, calls }))
    } catch (err) {
      return Promise.reject(err)
    }
  }
  fetchJson.calls = calls
  return fetchJson
}

function makeStorage () {
  const items = {}
  return {
    items,
    getItem: key => (key in items ? items[key] : null),
    setItem: (key, value) => { items[key] = String(value) },
    removeItem: key => { delete items[key] },
  }
}

const scenario = {
  _id: 'version1',
  original: 'orig1',
  initialActionQueue: ['m1', 'dead1', 'm2', { _id: 'm3' }],
}

const messages = [
  { _id: 'm3', actor: 'model', text: 'reply', actionData: { type: 'continue' }, documents: [{ _id: 'doc1', source: { type: 'code' } }], i18n: { he: { text: 'x' } }, ownerID: 'u1' },
  { _id: 'm1', actor: 'teacher', text: 'welcome', actionData: { type: 'continue' }, documents: [], ownerID: 'u1', character: 'hq', background: 'camp' },
  { _id: 'm2', actor: 'user', text: 'Make a game', actionData: { type: 'prompt-quiz', answerIndex: 1, choices: [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a game', responseText: 'yes' }] }, documents: [], ownerID: 'u1' },
]

function clone (value) { return JSON.parse(JSON.stringify(value)) }

describe('lib/scenario-script', function () {
  beforeEach(function () {
    this.routes = {
      'GET /db/ai_scenario/version1/messages': () => clone(messages),
      'POST /db/ai_chat_message': ({ json, calls }) => Object.assign({ _id: `new${calls.length}` }, json),
      'PUT *': ({ json }) => json,
      'DELETE *': () => '',
    }
    this.fetchJson = makeFetch(this.routes)
    this.storage = makeStorage()
    this.clock = 1000
    this.store = createScriptStore({ scenario: clone(scenario), fetchJson: this.fetchJson, storage: this.storage, now: () => this.clock })
  })

  describe('load', function () {
    it('orders the steps by the queue, not by the response, and marks dead ids', function (done) {
      this.store.load().then(steps => {
        expect(steps.map(s => s.kind)).toEqual(['live', 'dead', 'live', 'live'])
        expect(steps.map(s => s.id)).toEqual(['m1', 'dead1', 'm2', 'm3'])
        expect(steps[0].text).toBe('welcome')
        expect(steps[3].documents[0]._id).toBe('doc1')
        expect(steps[3].i18n.he.text).toBe('x')
        expect(this.store.changes().any).toBe(false)
        expect(this.store.state.loaded).toBe(true)
      }).then(done, done.fail)
    })
  })

  describe('edits', function () {
    beforeEach(function (done) {
      this.store.load().then(() => done(), done.fail)
    })

    it('marks an edited live step dirty and discard reloads it clean', function (done) {
      const [first] = this.store.state.steps
      this.store.setText(first.key, 'hello')
      expect(this.store.isDirty(first)).toBe(true)
      expect(this.store.changes().editedSteps.length).toBe(1)
      expect(this.store.changes().count).toBe(1)
      this.store.setText(first.key, 'welcome')
      expect(this.store.isDirty(first)).toBe(false)
      this.store.setActor(first.key, 'model')
      this.store.discard().then(() => {
        expect(this.store.state.steps[0].actor).toBe('teacher')
        expect(this.store.changes().any).toBe(false)
      }).then(done, done.fail)
    })

    it('refuses unknown actors and action types', function () {
      const [first] = this.store.state.steps
      expect(() => this.store.setActor(first.key, 'robot')).toThrow()
      expect(() => this.store.setActionType(first.key, 'dance')).toThrow()
    })

    it('turns a step into a quiz with two empty choices and the text as the first one', function () {
      const [first] = this.store.state.steps
      this.store.setActionType(first.key, 'prompt-quiz')
      expect(first.actionData.type).toBe('prompt-quiz')
      expect(first.actionData.choices.length).toBe(2)
      expect(first.actionData.choices[0].text).toBe('welcome')
      expect(first.actionData.answerIndex).toBe(0)
      this.store.setActionType(first.key, 'continue')
      expect(first.actionData).toEqual({ type: 'continue' })
    })

    it('keeps the message text equal to the correct choice', function () {
      const quiz = this.store.state.steps[2]
      this.store.setAnswerIndex(quiz.key, 0)
      expect(quiz.text).toBe('Make a story')
      this.store.setChoice(quiz.key, 0, { text: 'Make a poem' })
      expect(quiz.text).toBe('Make a poem')
      this.store.setChoice(quiz.key, 1, { responseText: 'later' })
      expect(quiz.text).toBe('Make a poem')
      this.store.addChoice(quiz.key)
      expect(quiz.actionData.choices.length).toBe(3)
      this.store.removeChoice(quiz.key, 0)
      expect(quiz.actionData.answerIndex).toBe(0)
      expect(quiz.text).toBe('Make a game')
      expect(() => this.store.setAnswerIndex(quiz.key, 9)).toThrow()
    })

    it('moves, inserts, duplicates and removes steps in the queue', function () {
      const keys = () => this.store.state.steps.map(s => s.id || s.kind)
      const [first, dead] = this.store.state.steps
      expect(this.store.move(first.key, -1)).toBe(false)
      expect(this.store.move(first.key, 1)).toBe(true)
      expect(keys()).toEqual(['dead1', 'm1', 'm2', 'm3'])
      expect(this.store.changes().queueChanged).toBe(true)

      const teacher = this.store.insertAfter(first.key, 'teacher')
      expect(teacher.kind).toBe('new')
      expect(teacher.actor).toBe('teacher')
      expect(this.store.state.steps[2]).toBe(teacher)
      expect(this.store.state.selectedKey).toBe(teacher.key)

      const copy = this.store.duplicate(this.store.state.steps[4].key)
      expect(copy.text).toBe('reply')
      expect(copy.documents[0]._id).toBe('doc1')
      expect(this.store.state.steps[5]).toBe(copy)

      const end = this.store.append('end')
      expect(end.actionData.type).toBe('end-of-lesson')
      expect(this.store.state.steps[this.store.state.steps.length - 1]).toBe(end)

      this.store.removeFromQueue(dead.key)
      expect(keys()[0]).toBe('m1')
      expect(this.store.changes().newSteps.length).toBe(3)
      expect(() => this.store.insertAfter(first.key, 'song')).toThrow()
    })

    it('inserts a copy of a message fetched by id', function (done) {
      this.routes['GET /db/ai_chat_message/other'] = () => ({ _id: 'other', actor: 'teacher', text: 'from elsewhere', actionData: { type: 'continue' }, documents: [] })
      const [first] = this.store.state.steps
      this.store.insertCopyById(first.key, 'other').then(step => {
        expect(step.kind).toBe('new')
        expect(step.id).toBe(null)
        expect(step.text).toBe('from elsewhere')
        expect(this.store.state.steps[1]).toBe(step)
      }).then(done, done.fail)
    })

    it('deleting a message removes it from the queue and remembers the delete', function () {
      const quiz = this.store.state.steps[2]
      this.store.deleteMessage(quiz.key)
      expect(this.store.state.steps.map(s => s.id)).toEqual(['m1', 'dead1', 'm3'])
      expect(this.store.changes().deletedIds).toEqual(['m2'])
    })

    it('blocks saving a step with empty text or an empty choice', function (done) {
      const teacher = this.store.append('teacher')
      expect(this.store.validate().map(p => p.message)).toEqual(['empty text'])
      this.store.setText(teacher.key, 'hi')
      const quiz = this.store.append('quiz')
      this.store.setChoice(quiz.key, 0, { text: 'A prompt' })
      expect(this.store.validate().map(p => p.message)).toEqual(['empty choice'])
      this.store.saveMessages().then(() => done.fail('expected a rejection'), err => {
        expect(err.problems.length).toBe(1)
        expect(this.fetchJson.calls.filter(c => c.method !== 'GET').length).toBe(0)
        done()
      })
    })
  })

  describe('live prompt and end steps', function () {
    beforeEach(function (done) {
      this.store.load().then(() => done(), done.fail)
    })

    it('inserts a live prompt as a teacher line, and keeps it one', function () {
      const live = this.store.append('prompt')
      expect(live.actor).toBe('teacher')
      expect(live.actionData).toEqual({ type: 'prompt-live' })
      expect(() => this.store.setActor(live.key, 'user')).toThrow()
      this.store.setActor(live.key, 'teacher')
      expect(live.actor).toBe('teacher')
    })

    it('switching a player line to a live prompt makes it a teacher line', function () {
      const quiz = this.store.state.steps.find(s => s.id === 'm2')
      this.store.setActionType(quiz.key, 'prompt-live')
      expect(quiz.actor).toBe('teacher')
      expect(quiz.actionData).toEqual({ type: 'prompt-live' })
    })

    it('a new end step, and a step switched to one, offers next level then the map', function () {
      const end = this.store.append('end')
      expect(end.actionData).toEqual({ type: 'end-of-lesson', exits: [{ kind: 'next-level' }, { kind: 'map' }] })
      const first = this.store.state.steps[0]
      this.store.setActionType(first.key, 'end-of-lesson')
      expect(first.actionData.exits.map(e => e.kind)).toEqual(['next-level', 'map'])
    })

    it('edits the exits with a new actionData each time: add, label, kind, move, remove', function () {
      const end = this.store.append('end')
      const before = end.actionData
      this.store.addExit(end.key, 'free-chat')
      expect(end.actionData).not.toBe(before)
      this.store.setExit(end.key, 2, { label: 'Continue' })
      this.store.setExit(end.key, 0, { label: 'Next story' })
      this.store.setExit(end.key, 0, { label: '  ' })
      this.store.setExit(end.key, 1, { kind: 'free-chat' })
      expect(() => this.store.setExit(end.key, 1, { kind: 'shop' })).toThrow()
      expect(() => this.store.addExit(end.key, 'shop')).toThrow()
      expect(this.store.moveExit(end.key, 2, -2)).toBe(true)
      expect(this.store.moveExit(end.key, 0, -1)).toBe(false)
      this.store.removeExit(end.key, 1)
      expect(end.actionData.exits).toEqual([{ kind: 'free-chat', label: 'Continue' }, { kind: 'free-chat' }])
    })

    it('sets and clears the next level, on end steps only', function () {
      const end = this.store.append('end')
      this.store.setNextLevel(end.key, ' orig2 ')
      expect(end.actionData.nextLevel).toBe('orig2')
      this.store.setNextLevel(end.key, null)
      expect('nextLevel' in end.actionData).toBe(false)
      expect(() => this.store.setNextLevel(this.store.state.steps[0].key, 'orig2')).toThrow()
    })

    it('blocks saving an end step without exits', function () {
      const end = this.store.append('end')
      this.store.setText(end.key, 'bye')
      this.store.removeExit(end.key, 0)
      expect(this.store.validate()).toEqual([])
      this.store.removeExit(end.key, 0)
      expect(this.store.validate().map(p => p.message)).toEqual(['an end step needs at least one exit'])
    })

    it('saves the exits and the next level with the message', function (done) {
      const end = this.store.append('end')
      this.store.setText(end.key, 'mission accomplished')
      this.store.setNextLevel(end.key, 'orig2')
      this.store.saveMessages().then(() => {
        const post = this.fetchJson.calls.find(c => c.method === 'POST')
        expect(post.json.actionData).toEqual({ type: 'end-of-lesson', exits: [{ kind: 'next-level' }, { kind: 'map' }], nextLevel: 'orig2' })
        done()
      }, done.fail)
    })
  })

  describe('story fields', function () {
    beforeEach(function (done) {
      this.store.load().then(() => done(), done.fail)
    })

    it('loads them, PUTs only the changed ones, and sends null to clear a live field', function (done) {
      const [first] = this.store.state.steps
      expect(first.character).toBe('hq')
      expect(first.background).toBe('camp')
      expect(this.store.isDirty(first)).toBe(false)
      this.store.setStoryField(first.key, 'objective', ' recolor ')
      expect(first.objective).toBe('recolor')
      this.store.setStoryField(first.key, 'character', '')
      expect(first.character).toBe(null)
      expect(this.store.isDirty(first)).toBe(true)
      expect(() => this.store.setStoryField(first.key, 'mood', 'x')).toThrow()
      this.store.saveMessages().then(() => {
        const puts = this.fetchJson.calls.filter(c => c.method === 'PUT')
        expect(puts.length).toBe(1)
        expect(puts[0].json).toEqual({ character: null, objective: 'recolor' })
        expect(this.store.isDirty(first)).toBe(false)
      }).then(done, done.fail)
    })

    it('clearing a field that was never set is not a change', function () {
      const quiz = this.store.state.steps[2]
      this.store.setStoryField(quiz.key, 'objective', 'recolor')
      expect(this.store.isDirty(quiz)).toBe(true)
      this.store.setStoryField(quiz.key, 'objective', null)
      expect(this.store.isDirty(quiz)).toBe(false)
      expect(this.store.changes().any).toBe(false)
    })

    it('a new step POSTs the fields that are set and leaves cleared ones out', function (done) {
      const step = this.store.append('teacher')
      this.store.setText(step.key, 'hi')
      this.store.setStoryField(step.key, 'character', 'local')
      this.store.setStoryField(step.key, 'background', 'camp')
      this.store.setStoryField(step.key, 'background', null)
      this.store.saveMessages().then(() => {
        const [post] = this.fetchJson.calls.filter(c => c.method === 'POST')
        expect(post.json).toEqual({ parent: 'orig1', parentKind: 'scenario', actor: 'teacher', text: 'hi', actionData: { type: 'continue' }, documents: [], character: 'local' })
      }).then(done, done.fail)
    })

    it('duplicate and copy-by-id keep the fields and the pacing', function (done) {
      const [first] = this.store.state.steps
      const copy = this.store.duplicate(first.key)
      expect(copy.character).toBe('hq')
      expect(copy.background).toBe('camp')
      expect(copy.objective).toBeUndefined()
      this.routes['GET /db/ai_chat_message/other'] = () => ({ _id: 'other', actor: 'teacher', text: 'x', actionData: { type: 'continue', autoAdvance: 1500 }, documents: [], objective: 'recolor' })
      this.store.insertCopyById(first.key, 'other').then(step => {
        expect(step.objective).toBe('recolor')
        expect(step.actionData.autoAdvance).toBe(1500)
        expect(step.character).toBeUndefined()
      }).then(done, done.fail)
    })

    it('backups round-trip the fields', function (done) {
      const [first] = this.store.state.steps
      this.store.setStoryField(first.key, 'objective', 'recolor')
      const fresh = createScriptStore({ scenario: clone(scenario), fetchJson: this.fetchJson, storage: this.storage })
      fresh.load().then(() => {
        expect(fresh.restoreFromBackup()).toBe(true)
        const [restored, , quiz] = fresh.state.steps
        expect(restored.objective).toBe('recolor')
        expect(restored.character).toBe('hq')
        expect(fresh.isDirty(restored)).toBe(true)
        // JSON dropped the unset keys; the restored step gets them back so it has the same shape as a loaded one.
        expect(Object.keys(quiz)).toEqual(jasmine.arrayContaining(['character', 'objective', 'background']))
        expect(quiz.character).toBeUndefined()
      }).then(done, done.fail)
    })

    it('setAutoAdvance writes, deletes and refuses non-continue steps and bad values', function () {
      const [first, , quiz] = this.store.state.steps
      const before = first.actionData
      this.store.setAutoAdvance(first.key, 0)
      expect(first.actionData).toEqual({ type: 'continue', autoAdvance: 0 })
      expect(first.actionData).not.toBe(before) // replaced, so a Vue watcher on actionData sees it
      expect(this.store.isDirty(first)).toBe(true)
      this.store.setAutoAdvance(first.key, 1500)
      expect(first.actionData.autoAdvance).toBe(1500)
      this.store.setAutoAdvance(first.key, null)
      expect(first.actionData).toEqual({ type: 'continue' })
      expect(this.store.isDirty(first)).toBe(false)
      expect(() => this.store.setAutoAdvance(first.key, -5)).toThrow()
      expect(() => this.store.setAutoAdvance(first.key, 1.5)).toThrow()
      expect(() => this.store.setAutoAdvance(quiz.key, 0)).toThrow()
    })

    it('switching the actor to player or AI drops the character those lines resolve by role', function (done) {
      const [first] = this.store.state.steps
      this.store.setActor(first.key, 'user')
      expect(first.character).toBe(null)
      this.store.setActor(first.key, 'teacher')
      expect(first.character).toBe(null)
      this.store.saveMessages().then(() => {
        const [put] = this.fetchJson.calls.filter(c => c.method === 'PUT')
        expect(put.json).toEqual({ character: null })
      }).then(done, done.fail)
    })
  })

  describe('saveMessages before load', function () {
    it('refuses, so an empty queue is never saved', function (done) {
      expect(this.store.changes().any).toBe(false)
      this.store.saveMessages().then(() => done.fail('expected a rejection'), err => {
        expect(err.message).toContain('not loaded')
        expect(this.fetchJson.calls.length).toBe(0)
        done()
      })
    })
  })

  describe('saveMessages', function () {
    beforeEach(function (done) {
      this.store.load().then(() => done(), done.fail)
    })

    it('creates new steps in order, updates edited ones with their changed fields, returns the queue ids, deletes only afterwards', function (done) {
      const [first, dead, quiz, reply] = this.store.state.steps
      this.store.setText(first.key, 'welcome back')
      const inserted = this.store.insertAfter(first.key, 'teacher')
      this.store.setText(inserted.key, 'new one')
      this.store.setAnswerIndex(quiz.key, 0)
      this.store.deleteMessage(reply.key)
      this.store.removeFromQueue(dead.key)
      this.store.saveMessages().then(ids => {
        const writes = this.fetchJson.calls.filter(c => c.method !== 'GET')
        expect(writes.map(c => `${c.method} ${c.url}`)).toEqual([
          'POST /db/ai_chat_message',
          'PUT /db/ai_chat_message/m1',
          'PUT /db/ai_chat_message/m2',
        ])
        expect(writes[0].json).toEqual({ parent: 'orig1', parentKind: 'scenario', actor: 'teacher', text: 'new one', actionData: { type: 'continue' }, documents: [] })
        expect(writes[1].json).toEqual({ text: 'welcome back' })
        expect(Object.keys(writes[2].json)).toEqual(['text', 'actionData'])
        expect(writes[2].json.actionData.answerIndex).toBe(0)
        expect(inserted.id).toBe('new2')
        expect(inserted.kind).toBe('live')
        expect(ids).toEqual(['m1', 'new2', 'm2'])
        // The queue and the delete are still pending until the version is saved; the backup now carries the saved ids.
        expect(this.store.changes().queueChanged).toBe(true)
        expect(this.store.changes().deletedIds).toEqual(['m3'])
        const backup = JSON.parse(this.storage.items['scenario-script-backup:orig1'])
        expect(backup.steps.map(s => s.id)).toEqual(['m1', 'new2', 'm2'])
        return this.store.applyDeletes()
      }).then(() => {
        expect(this.fetchJson.calls.filter(c => c.method === 'DELETE').map(c => c.url)).toEqual(['/db/ai_chat_message/m3'])
        expect(this.store.changes().deletedIds).toEqual([])
        this.store.adoptScenario({ _id: 'version2', original: 'orig1', initialActionQueue: ['m1', 'new2', 'm2'] })
        this.store.clearBackup()
        expect(this.store.changes().any).toBe(false)
        expect(this.storage.items['scenario-script-backup:orig1']).toBeUndefined()
      }).then(done, done.fail)
    })

    it('a restored backup after the message writes does not write them again', function (done) {
      const [first] = this.store.state.steps
      this.store.setText(first.key, 'welcome back')
      const inserted = this.store.append('teacher')
      this.store.setText(inserted.key, 'new one')
      this.store.saveMessages().then(() => {
        const fresh = createScriptStore({ scenario: clone(scenario), fetchJson: this.fetchJson, storage: this.storage })
        return fresh.load().then(() => {
          expect(fresh.restoreFromBackup()).toBe(true)
          expect(fresh.changes().newSteps.length).toBe(0)
          expect(fresh.changes().editedSteps.length).toBe(0)
          expect(fresh.changes().queueChanged).toBe(true)
          const before = this.fetchJson.calls.length
          return fresh.saveMessages().then(ids => {
            expect(ids).toEqual(['m1', 'dead1', 'm2', 'm3', 'new2'])
            expect(this.fetchJson.calls.length).toBe(before)
          })
        })
      }).then(done, done.fail)
    })

    it('stops at the first failure and keeps the rest pending', function (done) {
      this.routes['PUT /db/ai_chat_message/m1'] = () => { throw Object.assign(new Error('forbidden'), { code: 403 }) }
      const [first, , quiz] = this.store.state.steps
      const inserted = this.store.append('model')
      this.store.setText(inserted.key, 'generated')
      this.store.setText(first.key, 'changed')
      this.store.setText(quiz.key, 'Make a story')
      this.store.saveMessages().then(() => done.fail('expected a rejection'), err => {
        expect(err.action).toBe('update')
        expect(err.step).toBe(first)
        expect(err.code).toBe(403)
        expect(inserted.kind).toBe('live')
        expect(inserted.id).toBe('new2')
        expect(this.store.isDirty(first)).toBe(true)
        expect(this.store.isDirty(quiz)).toBe(true)
        expect(this.fetchJson.calls.filter(c => c.method === 'PUT').length).toBe(1)
        expect(this.store.changes().count).toBe(3)
        done()
      })
    })
  })

  describe('backups', function () {
    beforeEach(function (done) {
      this.store.load().then(() => done(), done.fail)
    })

    it('writes a backup on every change and drops it when nothing is pending', function () {
      const [first] = this.store.state.steps
      this.store.setText(first.key, 'edited')
      const backup = JSON.parse(this.storage.items['scenario-script-backup:orig1'])
      expect(backup.scenarioId).toBe('version1')
      expect(backup.at).toBe(1000)
      expect(backup.steps[0].text).toBe('edited')
      this.store.setText(first.key, 'welcome')
      expect(this.storage.items['scenario-script-backup:orig1']).toBeUndefined()
    })

    it('restores a backup of the same scenario version and ignores one from another', function (done) {
      const [first] = this.store.state.steps
      this.store.setText(first.key, 'edited')
      this.store.append('teacher')
      const fresh = createScriptStore({ scenario: clone(scenario), fetchJson: this.fetchJson, storage: this.storage })
      fresh.load().then(() => {
        expect(fresh.readBackup()).not.toBe(null)
        expect(fresh.restoreFromBackup()).toBe(true)
        expect(fresh.state.steps[0].text).toBe('edited')
        expect(fresh.isDirty(fresh.state.steps[0])).toBe(true)
        expect(fresh.state.steps.length).toBe(5)
        expect(fresh.changes().newSteps.length).toBe(1)
        const added = fresh.append('model')
        expect(added.key).not.toBe(fresh.state.steps[4].key)

        const other = createScriptStore({ scenario: Object.assign(clone(scenario), { _id: 'version2' }), fetchJson: makeFetch({ 'GET /db/ai_scenario/version2/messages': () => clone(messages) }), storage: this.storage })
        expect(other.readBackup()).toBe(null)
        expect(other.restoreFromBackup()).toBe(false)
      }).then(done, done.fail)
    })
  })
})
