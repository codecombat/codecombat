/* eslint-env jasmine */
const ScenarioSaveVersionModal = require('views/editor/ai-scenario/ScenarioSaveVersionModal')
const AIScenario = require('models/AIScenario')

describe('ScenarioSaveVersionModal', function () {
  const notice = { viewing: '0.3', latest: '0.15', latestUrl: '/editor/ai-scenario/fabricator-training', text: 'You are viewing v0.3. Saving makes it the latest and replaces v0.15.' }

  function makeModel () {
    const model = new AIScenario({ _id: '6adc000000000000000000a3', original: '6adb146e0e103758a145abb2', name: 'Fabricator Training', version: { major: 0, minor: 3 } })
    model.loaded = true
    model.markToRevert()
    return model
  }

  beforeEach(function () {
    me.set('anonymous', false)
    spyOn(me, 'isAdmin').and.returnValue(true)
  })

  afterEach(function () {
    if (this.modal) { this.modal.destroy() }
  })

  it('names the version the save replaces and keeps Save off until the replace is ticked', function () {
    this.modal = new ScenarioSaveVersionModal({ model: makeModel(), noNewMajorVersions: true, versionNotice: notice })
    this.modal.render()
    expect(this.modal.$el.find('.version-notice strong').text()).toBe(notice.text)
    const button = this.modal.$el.find('#save-version-button')
    expect(button.prop('disabled')).toBe(true)
    const saves = []
    this.modal.on('save-new-version', e => saves.push(e))
    this.modal.saveChanges()
    expect(saves.length).toBe(0)
    this.modal.$el.find('#replace-latest').prop('checked', true).trigger('change')
    expect(button.prop('disabled')).toBe(false)
    this.modal.saveChanges()
    expect(saves.length).toBe(1)
  })

  it('adds nothing when the latest version is edited', function () {
    this.modal = new ScenarioSaveVersionModal({ model: makeModel(), noNewMajorVersions: true, versionNotice: null, scriptSummary: ['Updated message at step 1'] })
    this.modal.render()
    expect(this.modal.$el.find('.version-notice').length).toBe(0)
    expect(this.modal.$el.find('#save-version-button').prop('disabled')).toBe(false)
  })

  it('tells a patcher too, in the words the view picks for a non-writer, without the tick', function () {
    me.isAdmin.and.returnValue(false)
    const model = makeModel()
    model.set('name', 'Renamed')
    const patchNotice = Object.assign({}, notice, { text: 'You are viewing v0.3, not the latest (v0.15).' })
    this.modal = new ScenarioSaveVersionModal({ model, versionNotice: patchNotice })
    this.modal.render()
    expect(this.modal.isPatch).toBe(true)
    expect(this.modal.$el.find('.version-notice strong').text()).toBe(patchNotice.text)
    expect(this.modal.$el.find('#replace-latest').length).toBe(0)
  })
})
