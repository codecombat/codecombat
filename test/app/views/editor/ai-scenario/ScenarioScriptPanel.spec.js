import { mount } from '@vue/test-utils'
import ScenarioScriptPanel from 'app/views/editor/ai-scenario/ScenarioScriptPanel.vue'
const Vue = require('vue')
const { createScriptStore } = require('lib/scenario-script')

const GAME = '<!doctype html><html><head><title>Merge Game</title></head><body>hi</body></html>'
const messages = [
  { _id: 'm1', actor: 'teacher', text: 'welcome to **AI HackStack**', actionData: { type: 'continue' }, documents: [], i18n: { he: { text: 'x' } } },
  { _id: 'm2', actor: 'user', text: 'Make a game', actionData: { type: 'prompt-quiz', answerIndex: 1, choices: [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a game', responseText: 'yes' }] }, documents: [] },
  { _id: 'm3', actor: 'model', text: `click **Output**\n\n\`\`\`html\n${GAME}\n\`\`\``, actionData: { type: 'continue' }, documents: [{ _id: 'd1', source: { type: 'link', url: 'https://example.com/poem', linkText: 'the poem' } }] },
]

function fetchJson (url, options = {}) {
  if (url === '/db/ai_scenario/v1/messages') { return Promise.resolve(JSON.parse(JSON.stringify(messages))) }
  if (options.method === 'PUT') { return Promise.resolve(options.json) }
  return Promise.reject(new Error(`no route for ${url}`))
}

function makeStorage () {
  const items = {}
  return { getItem: k => (k in items ? items[k] : null), setItem: (k, v) => { items[k] = v }, removeItem: k => { delete items[k] } }
}

describe('ScenarioScriptPanel', function () {
  beforeEach(function (done) {
    if (!Vue.prototype.$t) {
      Vue.prototype.$t = key => key
      this.installedT = true
    }
    this.store = createScriptStore({ scenario: { _id: 'v1', original: 'o1', initialActionQueue: ['m1', 'dead1', 'm2', 'm3'] }, fetchJson, storage: makeStorage() })
    this.wrapper = mount(ScenarioScriptPanel, { propsData: { store: this.store, readOnly: false, releasePhase: 'released', mode: 'learn to use' } })
    this.store.load().then(() => this.wrapper.vm.$nextTick()).then(done, done.fail)
  })

  afterEach(function () {
    this.wrapper.destroy()
    if (this.installedT) { delete Vue.prototype.$t }
  })

  it('renders a card per queue entry with markdown, quiz choices, lint, the live warning, Output and link chips', function () {
    const w = this.wrapper
    expect(w.findAll('.step').length).toBe(4)
    expect(w.findAll('.step.dead').length).toBe(1)
    expect(w.find('.live-warning').exists()).toBe(true)
    expect(w.find('.lint-strip').exists()).toBe(true)
    const texts = w.findAll('.step .text')
    expect(texts.at(0).html()).toContain('<strong>AI HackStack</strong>')
    expect(texts.at(2).html()).not.toContain('doctype')
    expect(w.findAll('.choices li').length).toBe(2)
    expect(w.findAll('.choices li.correct').length).toBe(1)
    expect(w.find('.output-button').text()).toContain('Merge Game')
    expect(w.find('a.chip.link').attributes('href')).toBe('https://example.com/poem')
  })

  it('selects a card, edits its text in the step panel and counts the change', function (done) {
    const w = this.wrapper
    w.findAll('.step').at(0).trigger('click')
    w.vm.$nextTick().then(() => {
      expect(w.find('.scenario-step-panel').exists()).toBe(true)
      w.find('.scenario-step-panel textarea').setValue('welcome back')
      return w.vm.$nextTick()
    }).then(() => {
      expect(this.store.state.steps[0].text).toBe('welcome back')
      expect(w.find('.chip.pending').exists()).toBe(true)
      const [changes, problems] = w.emitted('changed').slice(-1)[0]
      expect(changes.count).toBe(1)
      expect(problems.length).toBe(0)
    }).then(done, done.fail)
  })

  it('reports a new step without text as a save blocker, and opens the Output preview in a sandboxed frame', function (done) {
    const w = this.wrapper
    w.findAll('.add-row button').at(0).trigger('click')
    w.vm.$nextTick().then(() => {
      expect(w.findAll('.step').length).toBe(5)
      expect(w.find('.lint-strip.alert-danger').exists()).toBe(true)
      const [, problems] = w.emitted('changed').slice(-1)[0]
      expect(problems.length).toBe(1)
      w.find('.output-button').trigger('click')
      return w.vm.$nextTick()
    }).then(() => {
      const frame = w.find('iframe.preview-frame')
      expect(frame.exists()).toBe(true)
      expect(frame.attributes('sandbox')).toBe('allow-scripts')
      expect(frame.attributes('srcdoc')).toContain('<title>Merge Game</title>')
    }).then(done, done.fail)
  })
})
