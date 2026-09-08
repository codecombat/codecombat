// The client Jasmine runner needs an explicit done callback for promises.
import { shallowMount } from '@vue/test-utils'
import AIJuniorCaptureView from 'app/views/ai-junior/AIJuniorCaptureView.vue'
import * as scenariosApi from 'app/core/api/ai-junior-scenarios'
import { DocumentScanner } from 'app/lib/doc-capture/capture'
const runAsync = fn => done => { fn().then(() => done(), error => done.fail(error)) }

const FIRST = '6600a6c23a9490c3f23997af'
const SECOND = '6600a6c23a9490c3f23997b0'
const STUDENT = '111111111111111111111111'

describe('AI Junior worksheet batch identity', () => {
  let wrapper
  beforeEach(() => {
    window.spyOn(scenariosApi, 'getAIJuniorScenario').and.callFake(({ scenarioHandle }) => Promise.resolve({
      _id: scenarioHandle, inputs: [{ id: scenarioHandle, type: 'image-field' }],
    }))
    wrapper = shallowMount({
      ...AIJuniorCaptureView,
      created () {},
      mounted () {},
      computed: { ...AIJuniorCaptureView.computed, hasAccess: () => true, cameraSupported: () => false },
    })
    window.spyOn(wrapper.vm, 'loadOwnerName').and.returnValue(Promise.resolve())
    wrapper.vm.scanner = {
      tracker: { reset: () => {} }, clearStill: () => {}, exitManualMode: () => {}, stop: () => {},
    }
  })
  afterEach(() => wrapper.destroy())

  it('reads a fresh scenario and student after submitting each sheet', runAsync(async () => {
    const view = wrapper.vm
    await view.onQRFound({ scenarioHandle: FIRST, userId: STUDENT, isPrefix: false })
    expect(view.ownerId).toBe(STUDENT)
    expect(view.scanner.regions[0].id).toBe(FIRST)
    view.stillLoaded = true
    view.stage = 'review'
    view.nextSheet()
    expect(view.awaitingQR).toBe(true)
    expect(view.qrUserId).toBe(null)
    expect(view.scanner.wantQR).toBe(true)
    expect(view.scanner.regions).toEqual([])
    expect(view.scanner.lastQRText).toBe(null)
    expect(view.stillLoaded).toBe(false)
    await view.onQRFound({ scenarioHandle: SECOND, userId: null, isPrefix: false })
    expect(view.activeScenarioHandle).toBe(SECOND)
    expect(view.ownerId).toBe(me.id)
    expect(view.scanner.regions[0].id).toBe(SECOND)
  }))

  it('does not reuse the route’s first student for the rest of a stack', runAsync(async () => {
    await wrapper.setProps({ scenarioHandle: FIRST, forUserId: STUDENT })
    wrapper.vm.scenario = { _id: FIRST }
    expect(wrapper.vm.ownerId).toBe(STUDENT)
    wrapper.vm.nextSheet()
    expect(wrapper.vm.activeScenarioHandle).toBe(null)
    expect(wrapper.vm.ownerId).toBe(me.id)
    expect(wrapper.vm.awaitingQR).toBe(true)
  }))

  it('ignores an activity request that finishes after moving on to a new sheet', runAsync(async () => {
    let finish
    scenariosApi.getAIJuniorScenario.and.returnValue(new Promise(resolve => { finish = resolve }))
    const pending = wrapper.vm.onQRFound({ scenarioHandle: FIRST, userId: STUDENT, isPrefix: false })
    wrapper.vm.nextSheet()
    finish({ _id: FIRST })
    await pending
    expect(wrapper.vm.scenario).toBe(null)
    expect(wrapper.vm.qrUserId).toBe(null)
    expect(wrapper.vm.qrSearching).toBe(false)
  }))

  it('refuses ambiguous legacy timestamp prefixes', runAsync(async () => {
    window.spyOn(scenariosApi, 'getAIJuniorScenarios').and.returnValue(Promise.resolve([{ _id: FIRST }, { _id: SECOND }]))
    await wrapper.vm.onQRFound({ scenarioHandle: '6600a6', userId: STUDENT, isPrefix: true })
    expect(wrapper.vm.scenario).toBe(null)
    expect(wrapper.vm.loadError).toContain('ambiguous')
    expect(scenariosApi.getAIJuniorScenario).not.toHaveBeenCalled()
  }))

  it('keeps manual capture as the default', () => {
    expect(wrapper.vm.autoCaptureWanted).toBe(false)
  })
})

describe('AI Junior camera cleanup', () => {
  it('stops a stream whose permission request finishes after leaving the scanner', runAsync(async () => {
    let finish
    window.spyOn(navigator.mediaDevices, 'getUserMedia').and.returnValue(new Promise(resolve => { finish = resolve }))
    const stop = jasmine.createSpy('stop')
    const scanner = new DocumentScanner({ video: {} })
    const pending = scanner.start()
    scanner.stop()
    finish({ getTracks: () => [{ stop }] })
    expect(await pending).toBe(null)
    expect(stop).toHaveBeenCalled()
    expect(scanner.stream).toBe(null)
  }))
})
