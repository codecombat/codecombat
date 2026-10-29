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

// Answers after `hold` settles, so a test can destroy the view while a request is in flight.
function fakeFetch (routes, hold = Promise.resolve()) {
  return spyOn(window, 'fetch').and.callFake(url => hold.then(() => {
    const path = url.split('?')[0]
    if (path in routes) { return jsonResponse(routes[path]) }
    if (/\/messages$/.test(path)) { return jsonResponse([]) }
    return { status: 404, headers: { get: () => 'text/plain' }, text: () => Promise.resolve(`no route for ${url}`) }
  }))
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

  it('keeps an old version opened by its own id, as Version history does, and words the notice by write access', function (done) {
    fakeFetch({ [VERSION_URL]: latest })
    this.view = open(OLD, v3)
    settled(this.view).then(() => {
      expect(this.view.scenario.id).toBe(OLD)
      expect(this.view.latestVersion._id).toBe(LATEST)
      expect(window.history.replaceState).not.toHaveBeenCalled()
      spyOn(this.view.scenario, 'hasWriteAccess').and.returnValue(true)
      expect(this.view.versionNotice().text).toBe('You are viewing v0.3. Saving makes it the latest and replaces v0.15.')
      this.view.scenario.hasWriteAccess.and.returnValue(false)
      expect(this.view.versionNotice().text).toBe('You are viewing v0.3, not the latest (v0.15).')
      expect(this.view.versionNotice().latestUrl).toBe('/editor/ai-scenario/fabricator-training')
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
      expect(this.view.latestVersion).toBeNull()
      expect(this.view.versionNotice().latest).toBeNull()
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    })
  })

  it('keeps the loaded document, says so, and still knows the latest when ?version is not found', function (done) {
    fakeFetch({ [VERSION_URL]: latest })
    const hadNoty = window.noty // another spec may have left a spy here, so spyOn would refuse
    const notySpy = jasmine.createSpy('noty')
    window.noty = notySpy
    this.view = open(ORIGINAL, v0, '0.9')
    settled(this.view).then(() => {
      window.noty = hadNoty
      expect(this.view.scenario.id).toBe(ORIGINAL)
      expect(this.view.versionCheckFailed).toBe(false)
      expect(this.view.versionNotice().latest).toBe('0.15')
      expect(notySpy).toHaveBeenCalled()
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    })
  })

  it('shows the banner for an old version and none for the latest', function (done) {
    fakeFetch({ [VERSION_URL]: latest })
    this.view = open(OLD, v3)
    settled(this.view).then(() => {
      this.view.render()
      expect(this.view.$el.find('#stale-version-banner strong').text()).toContain('You are viewing v0.3')
      expect(this.view.$el.find('#stale-version-banner a').attr('href')).toBe('/editor/ai-scenario/fabricator-training')
      expect(this.view.$el.find('.outer-content').hasClass('has-version-banner')).toBe(true)
      this.view.latestVersion = v3
      this.view.updateVersionBanner()
      expect(this.view.$el.find('#stale-version-banner').length).toBe(0)
      expect(this.view.$el.find('.outer-content').hasClass('has-version-banner')).toBe(false)
      done()
    })
  })

  it('refetches the latest when Save opens, so a version saved meanwhile shows up in the banner and the modal', function (done) {
    const routes = { [VERSION_URL]: latest }
    fakeFetch(routes)
    me.set('anonymous', false)
    spyOn(me, 'isAdmin').and.returnValue(true)
    this.view = open('fabricator-training', latest)
    settled(this.view).then(() => {
      this.view.render()
      expect(this.view.$el.find('#stale-version-banner').length).toBe(0)
      routes[VERSION_URL] = Object.assign({}, latest, { _id: '6ae1000000000000000000b0', version: { major: 0, minor: 16 } })
      spyOn(this.view, 'openModalView')
      return this.view.openSaveModal()
    }).then(() => {
      const modal = this.view.openModalView.calls.mostRecent().args[0]
      expect(modal.versionNotice.latest).toBe('0.16')
      expect(modal.versionNotice.text).toBe('You are viewing v0.15. Saving makes it the latest and replaces v0.16.')
      expect(this.view.$el.find('#stale-version-banner strong').text()).toContain('replaces v0.16')
      modal.destroy()
      done()
    })
  })

  // Navigating away before /version answers: the callbacks find a destroyed view and must not touch it.
  function destroyedWhile (routes, done) {
    let release
    fakeFetch(routes, new Promise(resolve => { release = resolve }))
    const rejections = jasmine.createSpy('unhandledrejection')
    window.addEventListener('unhandledrejection', rejections)
    spyOn(console, 'error')
    const view = open(ORIGINAL, v0)
    view.destroy()
    release()
    setTimeout(() => {
      window.removeEventListener('unhandledrejection', rejections)
      expect(rejections).not.toHaveBeenCalled()
      expect(console.error).not.toHaveBeenCalled()
      expect(window.history.replaceState).not.toHaveBeenCalled()
      done()
    }, 50)
  }

  it('does nothing when the editor was destroyed before the latest version arrived', function (done) {
    destroyedWhile({ [VERSION_URL]: latest }, done)
  })

  it('does nothing when the editor was destroyed before the version fetch failed', function (done) {
    destroyedWhile({}, done)
  })
})
