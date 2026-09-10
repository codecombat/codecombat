/* eslint-env jasmine */
const ForkModal = require('views/editor/ForkModal')

// A fork gets a new `original`, but portrait.png in file storage is keyed by
// original, so the level editor palette showed the generic wizard for every
// forked thang. copyThangPortrait copies the parent's file across and must
// never block the fork when anything fails.
describe('ForkModal.copyThangPortrait', function () {
  const proto = ForkModal.prototype
  const parentOriginal = '59110754cc295f003eefd5df'
  const pngBytes = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10])

  function makeModal (overrides = {}) {
    return Object.assign({
      editorPath: 'thang',
      model: {
        attributes: { name: 'Silver Door', original: parentOriginal },
        get (key) { return this.attributes[key] },
      },
    }, overrides)
  }

  function makeNewModel (original = '68231ce5ff32ac1b7bcc3f95') {
    return {
      attributes: { original },
      get (key) { return this.attributes[key] },
      uploadGenericPortrait: jasmine.createSpy('uploadGenericPortrait').and.callFake(callback => callback()),
    }
  }

  function okResponse () {
    return Promise.resolve({ ok: true, status: 200, blob: () => Promise.resolve(new Blob([pngBytes], { type: 'image/png' })) })
  }

  beforeEach(function () {
    spyOn(console, 'warn')
  })

  it('fetches the parent portrait and uploads it under the new original', function (done) {
    spyOn(window, 'fetch').and.returnValue(okResponse())
    const newModel = makeNewModel()
    proto.copyThangPortrait.call(makeModal(), newModel, function () {
      expect(window.fetch).toHaveBeenCalledWith(`/file/db/thang.type/${parentOriginal}/portrait.png`)
      const args = newModel.uploadGenericPortrait.calls.mostRecent().args
      expect(args[1]).toMatch(/^data:image\/png;base64,/)
      expect(console.warn).not.toHaveBeenCalled()
      done()
    })
  })

  it('still finishes the fork when the parent has no portrait file', function (done) {
    spyOn(window, 'fetch').and.returnValue(Promise.resolve({ ok: false, status: 404 }))
    const newModel = makeNewModel()
    proto.copyThangPortrait.call(makeModal(), newModel, function () {
      expect(newModel.uploadGenericPortrait).not.toHaveBeenCalled()
      expect(console.warn).toHaveBeenCalled()
      done()
    })
  })

  it('still finishes the fork when the fetch itself rejects', function (done) {
    spyOn(window, 'fetch').and.returnValue(Promise.reject(new Error('offline')))
    const newModel = makeNewModel()
    proto.copyThangPortrait.call(makeModal(), newModel, function () {
      expect(newModel.uploadGenericPortrait).not.toHaveBeenCalled()
      expect(console.warn.calls.mostRecent().args[0]).toContain('Silver Door')
      done()
    })
  })

  it('skips the copy when the parent has no original', function (done) {
    spyOn(window, 'fetch')
    const modal = makeModal()
    modal.model.attributes.original = undefined
    proto.copyThangPortrait.call(modal, makeNewModel(), function () {
      expect(window.fetch).not.toHaveBeenCalled()
      done()
    })
  })
})
