import { mount } from '@vue/test-utils'
import ScenarioScriptPanel from 'app/views/editor/ai-scenario/ScenarioScriptPanel.vue'
const Vue = require('vue')
const { createScriptStore } = require('lib/scenario-script')

const GAME = '<!doctype html><html><head><title>Merge Game</title></head><body>hi</body></html>'
const messages = [
  { _id: 'm1', actor: 'teacher', text: 'welcome to **AI HackStack**', actionData: { type: 'continue', autoAdvance: 0 }, documents: [], i18n: { he: { text: 'x' } }, character: 'local', objective: 'recolor' },
  { _id: 'm2', actor: 'user', text: 'Make a game', actionData: { type: 'prompt-quiz', answerIndex: 1, choices: [{ text: 'Make a story', responseText: 'no' }, { text: 'Make a game', responseText: 'yes' }] }, documents: [] },
  { _id: 'm3', actor: 'model', text: `click **Output**\n\n\`\`\`html\n${GAME}\n\`\`\``, actionData: { type: 'continue' }, documents: [{ _id: 'd1', source: { type: 'link', url: 'https://example.com/poem', linkText: 'the poem' } }] },
]

function fetchJson (url, options = {}) {
  if (url === '/db/ai_scenario/v1/messages') { return Promise.resolve(JSON.parse(JSON.stringify(messages))) }
  if (options.method === 'PUT') { return Promise.resolve(options.json) }
  return Promise.reject(new Error(`no route for ${url}`))
}

const storyContext = {
  isStory: true,
  storyWorld: 'hour-of-ai',
  worldChain: ['hour-of-ai', 'galaxy'],
  characters: [{ id: 'local', name: 'Local', role: 'npc', source: 'scenario' }, { id: 'hq', name: 'HQ', role: 'ally', source: 'galaxy' }, { id: 'you', name: 'You', role: 'player', source: 'galaxy' }],
  objectives: [{ id: 'recolor', text: 'Change the star' }],
  backgrounds: [{ id: 'camp', source: 'scenario' }, { id: 'bridge', source: 'galaxy' }],
  defaultAlly: 'hq',
  missingWorld: null,
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

  it('shows story chips and, with a story context, the summary strip and the Story block', function (done) {
    const w = this.wrapper
    const chips = () => w.findAll('.step').at(0).findAll('.chip.story').wrappers.map(c => c.text())
    expect(w.find('.story-summary').exists()).toBe(false)
    expect(chips().slice(0, 2)).toEqual(['→ ⚠ local', '◎ recolor'])
    expect(chips()[2]).toMatch(/^⏱ /) // "wait", through whichever $t the test run has
    w.setProps({ storyContext })
    w.vm.$nextTick().then(() => {
      expect(w.find('.story-summary').text()).toContain('galaxy ← hour-of-ai')
      expect(w.find('.story-summary').text()).toContain('local (npc) · hq (ally) · you (player)')
      expect(chips()[0]).toBe('→ Local')
      expect(w.findAll('.step').at(0).findAll('.chip.story.unknown').length).toBe(0)
      w.findAll('.step').at(0).trigger('click')
      return w.vm.$nextTick()
    }).then(() => {
      const panel = w.find('.scenario-step-panel')
      const speaker = panel.find('select.speaker')
      expect(speaker.element.value).toBe('local')
      expect(speaker.findAll('option').at(0).text()).toContain('HQ')
      expect(speaker.findAll('optgroup').wrappers.map(g => g.attributes('label'))).toEqual(['scenario', 'galaxy'])
      expect(panel.find('select.objective').element.value).toBe('recolor')
      expect(panel.find('select.background').findAll('option').length).toBe(3)
      expect(panel.find('.pacing input[value="wait"]').element.checked).toBe(true)
      speaker.setValue('')
      panel.find('.pacing input[value="auto"]').setChecked()
      return w.vm.$nextTick()
    }).then(() => {
      const [first] = this.store.state.steps
      expect(first.character).toBe(null)
      expect(first.actionData.autoAdvance).toBe(1000)
      expect(chips()).toEqual(['◎ recolor', '⏱ 1000 ms'])
      const ms = w.find('.scenario-step-panel .pacing input.ms')
      ms.element.value = '2500'
      ms.trigger('change') // the field writes on change, not per keystroke
      return w.vm.$nextTick()
    }).then(() => {
      expect(this.store.state.steps[0].actionData.autoAdvance).toBe(2500)
      // A player line has no speaker select: the page resolves it by role.
      w.find('.scenario-step-panel .row-2 select').setValue('user')
      return w.vm.$nextTick()
    }).then(() => {
      expect(w.find('.scenario-step-panel select.speaker').exists()).toBe(false)
      expect(w.find('.scenario-step-panel .story .static').exists()).toBe(true)
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
