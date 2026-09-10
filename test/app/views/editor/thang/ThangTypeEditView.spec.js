/* eslint-env jasmine */
const ThangTypeEditView = require('views/editor/thang/ThangTypeEditView')

// These specs exercise the multi-file Animate upload orchestration
// (processAnimateFiles) in isolation, stubbing the per-file read/parse so we
// don't need a real Worker, FileReader, or a fully rendered editor view.
describe('ThangTypeEditView Animate upload', function () {
  const proto = ThangTypeEditView.prototype
  let view, notySpy

  // Build a fake `this` with just the collaborators processAnimateFiles touches.
  // By default every file reads to non-empty text and parses to a raw fragment
  // keyed by the file name, so merges are observable.
  function makeView (overrides = {}) {
    const v = {
      thangType: { attributes: {} },
      showLoading: jasmine.createSpy('showLoading'),
      hideLoading: jasmine.createSpy('hideLoading'),
      updateProgress: jasmine.createSpy('updateProgress'),
      fileLoaded: jasmine.createSpy('fileLoaded'),
      readFileAsText (file) { return Promise.resolve(`source:${file.name}`) },
      parseAnimateSource (source) { return Promise.resolve(JSON.stringify({ [source]: { ok: true } })) },
    }
    return Object.assign(v, overrides)
  }

  function file (name, type = 'application/javascript') {
    return { name, type }
  }

  function run (v, files) {
    return proto.processAnimateFiles.call(v, files)
  }

  beforeEach(function () {
    notySpy = jasmine.createSpy('noty')
    window.noty = notySpy
    view = makeView()
  })

  it('merges every valid file into thangType.raw and calls fileLoaded once', function (done) {
    run(view, [file('a.js'), file('b.js')]).then(function () {
      expect(view.thangType.attributes.raw['source:a.js']).toEqual({ ok: true })
      expect(view.thangType.attributes.raw['source:b.js']).toEqual({ ok: true })
      expect(view.fileLoaded.calls.count()).toBe(1)
      expect(view.hideLoading).toHaveBeenCalled()
      expect(notySpy.calls.mostRecent().args[0].type).toBe('success')
      done()
    }).catch(done.fail)
  })

  it('accepts uppercase .js extensions even when the MIME type is empty', function (done) {
    run(view, [file('CAP.JS', '')]).then(function () {
      expect(view.thangType.attributes.raw['source:CAP.JS']).toEqual({ ok: true })
      expect(notySpy.calls.mostRecent().args[0].type).toBe('success')
      done()
    }).catch(done.fail)
  })

  it('skips files that are not .js and continues with the rest', function (done) {
    run(view, [file('bad.txt', 'text/plain'), file('good.js')]).then(function () {
      expect(view.thangType.attributes.raw['source:good.js']).toEqual({ ok: true })
      expect(view.thangType.attributes.raw['source:bad.txt']).toBeUndefined()
      const arg = notySpy.calls.mostRecent().args[0]
      expect(arg.type).toBe('warning')
      expect(arg.text).toContain('bad.txt')
      expect(arg.text).toContain('only accepts files ending with')
      done()
    }).catch(done.fail)
  })

  it('skips empty files with a reason', function (done) {
    view = makeView({ readFileAsText (f) { return Promise.resolve(f.name === 'empty.js' ? '   ' : `source:${f.name}`) } })
    run(view, [file('empty.js'), file('good.js')]).then(function () {
      expect(view.thangType.attributes.raw['source:good.js']).toEqual({ ok: true })
      expect(Object.keys(view.thangType.attributes.raw)).not.toContain('source:empty.js')
      const arg = notySpy.calls.mostRecent().args[0]
      expect(arg.type).toBe('warning')
      expect(arg.text).toContain('file is empty')
      done()
    }).catch(done.fail)
  })

  it('skips files whose parse rejects and keeps going', function (done) {
    view = makeView({
      parseAnimateSource (source) {
        return source === 'source:broken.js'
          ? Promise.reject(new Error('boom'))
          : Promise.resolve(JSON.stringify({ [source]: { ok: true } }))
      },
    })
    run(view, [file('broken.js'), file('good.js')]).then(function () {
      expect(view.thangType.attributes.raw['source:good.js']).toEqual({ ok: true })
      const arg = notySpy.calls.mostRecent().args[0]
      expect(arg.type).toBe('warning')
      expect(arg.text).toContain('broken.js')
      expect(arg.text).toContain('boom')
      done()
    }).catch(done.fail)
  })

  it('reports an error and never calls fileLoaded when all files fail', function (done) {
    run(view, [file('bad.txt', 'text/plain')]).then(function () {
      expect(view.fileLoaded).not.toHaveBeenCalled()
      expect(view.thangType.attributes.raw).toBeUndefined()
      expect(notySpy.calls.mostRecent().args[0].type).toBe('error')
      expect(view.hideLoading).toHaveBeenCalled()
      done()
    }).catch(done.fail)
  })
})

// The level editor palette reads the static portrait.png that a save uploads.
// These specs cover the source selection for that upload: it must come from the
// loaded model (sprite sheets built, raster raw images loaded), and a missing
// image must be reported instead of silently skipped.
describe('ThangTypeEditView portrait upload on save', function () {
  const proto = ThangTypeEditView.prototype
  const dataURL = 'data:image/png;base64,AAAA'

  function makeView (overrides = {}) {
    const v = {
      thangType: {
        attributes: { name: 'Beach Rock' },
        get (key) { return this.attributes[key] },
        getPortraitSource: jasmine.createSpy('getPortraitSource').and.returnValue(dataURL),
      },
      getLankOptions () { return { resolutionFactor: 4 } },
      getPortraitSourceForUpload: proto.getPortraitSourceForUpload,
      currentLank: null,
    }
    return Object.assign(v, overrides)
  }

  function makeNewThangType () {
    return { uploadGenericPortrait: jasmine.createSpy('uploadGenericPortrait') }
  }

  beforeEach(function () {
    spyOn(console, 'warn')
  })

  it('renders the portrait from the loaded model with the editor lank options', function () {
    const view = makeView()
    const newThangType = makeNewThangType()
    const callback = jasmine.createSpy('callback')
    proto.uploadPortrait.call(view, newThangType, callback)
    expect(view.thangType.getPortraitSource).toHaveBeenCalledWith({ resolutionFactor: 4 })
    expect(newThangType.uploadGenericPortrait).toHaveBeenCalledWith(callback, dataURL)
    expect(callback).not.toHaveBeenCalled()
    expect(console.warn).not.toHaveBeenCalled()
  })

  it('warns and continues the save when no portrait could be rendered', function () {
    const view = makeView()
    view.thangType.getPortraitSource.and.returnValue(undefined)
    const newThangType = makeNewThangType()
    const callback = jasmine.createSpy('callback')
    proto.uploadPortrait.call(view, newThangType, callback)
    expect(newThangType.uploadGenericPortrait).not.toHaveBeenCalled()
    expect(callback).toHaveBeenCalled()
    expect(console.warn.calls.mostRecent().args[0]).toContain('Beach Rock')
  })

  it('does not upload a plain URL as a portrait', function () {
    const view = makeView()
    view.thangType.getPortraitSource.and.returnValue('/file/db/thang.type/abc/portrait.png')
    const newThangType = makeNewThangType()
    const callback = jasmine.createSpy('callback')
    proto.uploadPortrait.call(view, newThangType, callback)
    expect(newThangType.uploadGenericPortrait).not.toHaveBeenCalled()
    expect(callback).toHaveBeenCalled()
  })

  it('warns and continues for a raster thang whose sprite sheet is not on screen', function () {
    const view = makeView()
    view.thangType.attributes.raster = 'db/thang.type/abc/rock.png'
    const newThangType = makeNewThangType()
    const callback = jasmine.createSpy('callback')
    proto.uploadPortrait.call(view, newThangType, callback)
    expect(view.thangType.getPortraitSource).not.toHaveBeenCalled()
    expect(newThangType.uploadGenericPortrait).not.toHaveBeenCalled()
    expect(callback).toHaveBeenCalled()
  })
})
