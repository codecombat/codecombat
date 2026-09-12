/* eslint-env jasmine */
const ThangType = require('models/ThangType')

describe('ThangType.uploadGenericPortrait', function () {
  const dataURL = 'data:image/png;base64,AAAA'
  let thangType, callback

  beforeEach(function () {
    spyOn(console, 'warn')
    thangType = new ThangType({ name: 'Beach Rock', original: '69f354bcbbc20557f9619c3a' })
    callback = jasmine.createSpy('callback')
  })

  it('posts the png under the original id and calls back on success', function () {
    thangType.uploadGenericPortrait(callback, dataURL)
    const request = jasmine.Ajax.requests.mostRecent()
    expect(request.url).toBe('/file')
    expect(request.method).toBe('POST')
    expect(decodeURIComponent(request.params)).toContain('path=db/thang.type/69f354bcbbc20557f9619c3a')
    request.respondWith({ status: 200, responseText: '{}' })
    expect(callback).toHaveBeenCalled()
    expect(console.warn).not.toHaveBeenCalled()
  })

  it('warns and still calls back when the upload is rejected', function () {
    thangType.uploadGenericPortrait(callback, dataURL)
    jasmine.Ajax.requests.mostRecent().respondWith({ status: 403, responseText: '{}' })
    expect(callback).toHaveBeenCalled()
    expect(console.warn.calls.mostRecent().args[0]).toContain('Beach Rock')
  })

  it('calls back without a request when there is no data URL', function () {
    const before = jasmine.Ajax.requests.count()
    thangType.uploadGenericPortrait(callback, '/file/db/thang.type/abc/portrait.png')
    expect(jasmine.Ajax.requests.count()).toBe(before)
    expect(callback).toHaveBeenCalled()
  })
})
