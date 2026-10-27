import { mount } from '@vue/test-utils'
import ScenarioStepExits from 'app/views/editor/ai-scenario/ScenarioStepExits.vue'
const Vue = require('vue')
const { createScriptStore } = require('lib/scenario-script')

const messages = [
  { _id: 'm1', actor: 'celebrate', text: 'mission accomplished', actionData: { type: 'end-of-lesson', exits: [{ kind: 'next-level', label: 'Next story' }, { kind: 'map' }], nextLevel: 'orig9' }, documents: [] },
  { _id: 'm2', actor: 'celebrate', text: 'old ending', actionData: { type: 'end-of-lesson' }, documents: [] },
]

describe('ScenarioStepExits', function () {
  beforeEach(function (done) {
    if (!Vue.prototype.$t) {
      Vue.prototype.$t = key => key
      this.installedT = true
    }
    this.calls = []
    const fetchJson = url => {
      this.calls.push(url)
      if (url === '/db/ai_scenario/v1/messages') { return Promise.resolve(JSON.parse(JSON.stringify(messages))) }
      if (url === '/db/ai_scenario/orig9/version?project=name') { return Promise.resolve({ name: 'Build a Gift' }) }
      if (url.startsWith('/db/ai_scenario?term=remix')) { return Promise.resolve([{ _id: 'v3', original: 'orig3', name: 'Remix for Lumis' }]) }
      return Promise.reject(new Error(`no route for ${url}`))
    }
    this.fetchJson = fetchJson
    this.store = createScriptStore({ scenario: { _id: 'v1', original: 'o1', initialActionQueue: ['m1', 'm2'] }, fetchJson, storage: { getItem: () => null, setItem () {}, removeItem () {} } })
    this.store.load().then(done, done.fail)
  })

  afterEach(function () {
    if (this.wrapper) { this.wrapper.destroy() }
    if (this.installedT) { delete Vue.prototype.$t }
  })

  function mountFor (spec, index) {
    spec.wrapper = mount(ScenarioStepExits, { propsData: { store: spec.store, step: spec.store.state.steps[index], fetchJson: spec.fetchJson } })
    return spec.wrapper
  }

  it('lists the exits in order with their labels, and names the next level', function (done) {
    const w = mountFor(this, 0)
    const rows = w.findAll('.exit')
    expect(rows.length).toBe(2)
    expect(rows.at(0).find('input').element.value).toBe('Next story')
    expect(rows.at(1).find('input').attributes('placeholder')).toBe(w.vm.$t('editor.scenario_step_exit_map'))
    setTimeout(() => {
      expect(w.find('.next-level .current').text()).toContain('Build a Gift')
      done()
    }, 0)
  })

  it('edits through the store: label, order, removal, a new exit', function () {
    const w = mountFor(this, 0)
    const step = this.store.state.steps[0]
    w.findAll('.exit').at(0).find('input').setValue('Onward')
    expect(step.actionData.exits[0].label).toBe('Onward')
    w.findAll('.exit').at(1).findAll('button').at(0).trigger('click')
    expect(step.actionData.exits.map(e => e.kind)).toEqual(['map', 'next-level'])
    w.findAll('.add-exit button').at(2).trigger('click')
    expect(step.actionData.exits.map(e => e.kind)).toEqual(['map', 'next-level', 'free-chat'])
    w.findAll('.exit').at(0).findAll('button').at(2).trigger('click')
    expect(step.actionData.exits.map(e => e.kind)).toEqual(['next-level', 'free-chat'])
    expect(w.emitted('changed').length).toBe(4)
  })

  it('searches scenarios and stores the picked original, or goes back to the map', function (done) {
    const w = mountFor(this, 0)
    const step = this.store.state.steps[0]
    w.find('.next-level input').setValue('remix')
    // past the search delay (250 ms), real time: jasmine.clock() disconnects the Karma browser here
    setTimeout(() => {
      w.vm.$nextTick().then(() => {
        const result = w.find('.results a')
        expect(result.text()).toContain('Remix for Lumis')
        result.trigger('click')
        expect(step.actionData.nextLevel).toBe('orig3')
        w.find('.next-level .current button').trigger('click')
        expect('nextLevel' in step.actionData).toBe(false)
      }).then(done, done.fail)
    }, 300)
  })

  it('keeps the newer results when an older search fails afterwards', function (done) {
    const pending = {}
    const fetchJson = url => {
      const term = (url.match(/term=([^&]+)/) || [])[1]
      if (!term) { return Promise.resolve({}) } // the next level's name
      return new Promise((resolve, reject) => { pending[term] = { resolve, reject } })
    }
    this.wrapper = mount(ScenarioStepExits, { propsData: { store: this.store, step: this.store.state.steps[0], fetchJson } })
    const w = this.wrapper
    w.vm.runSearch('old')
    w.vm.runSearch('remix')
    pending.remix.resolve([{ _id: 'v3', original: 'orig3', name: 'Remix for Lumis' }])
    setTimeout(() => {
      expect(w.vm.results.length).toBe(1)
      pending.old.reject(new Error('timeout'))
      setTimeout(() => {
        expect(w.vm.results.map(r => r.original)).toEqual(['orig3'])
        done()
      }, 0)
    }, 0)
  })

  it('on an old end step without exits says so, and adds the first one', function () {
    const w = mountFor(this, 1)
    expect(w.find('.hint').text()).toBe(w.vm.$t('editor.scenario_step_exits_none'))
    w.findAll('.add-exit button').at(0).trigger('click')
    expect(this.store.state.steps[1].actionData.exits).toEqual([{ kind: 'next-level' }])
  })
})
