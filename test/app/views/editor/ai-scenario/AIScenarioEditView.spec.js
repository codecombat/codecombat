/* eslint-env jasmine */
const AIScenarioEditView = require('views/editor/ai-scenario/AIScenarioEditView')

// GET /db/ai_scenario/<handle> gives the exact document an id names, and the original id is the
// _id of v0.0: these fixtures are what the server answers for each handle.
const ORIGINAL = '6adb146e0e103758a145abb2'
const OLD = '6adc000000000000000000a3'
const LATEST = '6adf50523c6ce3962e63cf56'
const base = { original: ORIGINAL, slug: 'fabricator-training', name: 'Fabricator Training', releasePhase: 'draft', initialActionQueue: [], permissions: [] }
const v0 = Object.assign({}, base, { _id: ORIGINAL, name: 'Fabricator', version: { major: 0, minor: 0 } })
const v3 = Object.assign({}, base, { _id: OLD, version: { major: 0, minor: 3 } })
const latest = Object.assign({}, base, { _id: LATEST, version: { major: 0, minor: 15, isLatestMajor: true, isLatestMinor: true } })
const VERSION_URL = `/db/ai_scenario/${ORIGINAL}/version`

function jsonResponse (body) {
  return Promise.resolve({ status: 200, headers: { get: () => 'application/json' }, json: () => Promise.resolve(JSON.parse(JSON.stringify(body))) })
}

function fakeFetch (routes) {
  return spyOn(window, 'fetch').and.callFake(url => {
    const path = url.split('?')[0]
    if (path in routes) { return jsonResponse(routes[path]) }
    if (/\/messages$/.test(path)) { return jsonResponse([]) }
    return Promise.resolve({ status: 404, headers: { get: () => 'text/plain' }, text: () => Promise.resolve(`no route for ${url}`) })
  })
}

// Opens the editor at a handle and answers the model fetch the way the server would.
function open (handle, loaded, version = null) {
  spyOn(AIScenarioEditView.prototype, 'locationVersion').and.returnValue(version)
  const view = new AIScenarioEditView({}, handle)
  jasmine.Ajax.requests.mostRecent().respondWith({ status: 200, responseText: JSON.stringify(loaded) })
  return view
}

function settled (view) {
  return new Promise(resolve => {
    const tick = () => (view.supermodel.finished() ? resolve() : setTimeout(tick, 5))
    tick()
  })
}

describe('AIScenarioEditView', function () {
  beforeEach(function () {
    spyOn(window.history, 'replaceState')
    spyOn(console, 'warn')
  })

  afterEach(function () {
    if (this.view) { this.view.destroy() }
  })

  it('edits the latest version when opened by the original id, and shows the slug in the URL', function (done) {
    fakeFetch({ [VERSION_URL]: latest })
    this.view = open(ORIGINAL, v0)
    settled(this.view).then(() => {
      expect(this.view.scenario.id).toBe(LATEST)
      expect(this.view.scenario.get('name')).toBe('Fabricator Training')
      expect(this.view.scenario.loaded).toBe(true)
      expect(this.view.scenario.saveBackups).toBe(true)
      expect(this.view.latestVersion._id).toBe(LATEST)
      expect(window.history.replaceState.calls.mostRecent().args[2]).toBe('/editor/ai-scenario/fabricator-training')
      done()
    })
  })

  it('keeps an old version opened by its own id, as Version history does', function (done) {
    fakeFetch({ [VERSION_URL]: latest })
    this.view = open(OLD, v3)
    settled(this.view).then(() => {
      expect(this.view.scenario.id).toBe(OLD)
      expect(this.view.latestVersion._id).toBe(LATEST)
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    })
  })

  it('keeps v0.0 when the original id comes with ?version=0.0', function (done) {
    const fetch = fakeFetch({ [VERSION_URL]: latest })
    this.view = open(ORIGINAL, v0, '0.0')
    settled(this.view).then(() => {
      expect(this.view.scenario.id).toBe(ORIGINAL)
      expect(fetch.calls.allArgs().map(args => args[0])).not.toContain(`${VERSION_URL}/0.0`)
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    })
  })

  it('loads the exact version ?version names', function (done) {
    fakeFetch({ [VERSION_URL]: latest, [`${VERSION_URL}/0.3`]: v3 })
    this.view = open('fabricator-training', latest, '0.3')
    settled(this.view).then(() => {
      expect(this.view.scenario.id).toBe(OLD)
      expect(this.view.latestVersion._id).toBe(LATEST)
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    })
  })

  it('keeps the loaded document and the URL when the latest cannot be fetched', function (done) {
    fakeFetch({})
    this.view = open(ORIGINAL, v0)
    settled(this.view).then(() => {
      expect(this.view.scenario.id).toBe(ORIGINAL)
      expect(this.view.versionCheckFailed).toBe(true)
      expect(this.view.latestVersion).toBeUndefined()
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    })
  })
})
