import { shallowMount } from '@vue/test-utils'
import AIJuniorWorksheet from 'app/components/common/elements/AIJuniorWorksheet.vue'
import AIJuniorClassPrintView from 'app/views/ai-junior/AIJuniorClassPrintView.vue'
import * as scenariosApi from 'app/core/api/ai-junior-scenarios'
import QRCode from 'qrcode'
const runAsync = fn => done => { fn().then(() => done(), error => done.fail(error)) }
const FIRST = '6600a6c23a9490c3f23997af'
const SECOND = '6600a6c23a9490c3f23997b0'

describe('AI Junior worksheet code requests', () => {
  it('coalesces simultaneous class lookups and checks again on the next print', runAsync(async () => {
    let respond
    window.spyOn(window, 'fetch').and.callFake(() => new Promise(resolve => { respond = resolve }))
    const first = scenariosApi.resolveAIJuniorWorksheetCode(FIRST)
    expect(scenariosApi.resolveAIJuniorWorksheetCode(FIRST)).toBe(first)
    expect(window.fetch.calls.count()).toBe(1)
    respond(new window.Response(JSON.stringify({ scenarioId: FIRST, code: 'c63bd7549611' }), { headers: { 'Content-Type': 'application/json' } }))
    expect((await first).code).toBe('c63bd7549611')
    const next = scenariosApi.resolveAIJuniorWorksheetCode(FIRST)
    expect(window.fetch.calls.count()).toBe(2)
    respond(new window.Response('{}', { headers: { 'Content-Type': 'application/json' } }))
    await next
  }))

  it('aborts a stalled lookup so printing can use its full-ID fallback', runAsync(async () => {
    jasmine.clock().install()
    try {
      let signal
      window.spyOn(window, 'fetch').and.callFake((url, options) => new Promise((resolve, reject) => {
        signal = options.signal
        signal.addEventListener('abort', () => reject(new Error('aborted')))
      }))
      const pending = scenariosApi.resolveAIJuniorWorksheetCode(FIRST).catch(error => error)
      jasmine.clock().tick(5001)
      expect(signal.aborted).toBe(true)
      expect((await pending).message).toBe('aborted')
    } finally { jasmine.clock().uninstall() }
  }))
})

describe('AI Junior worksheet QR preparation', () => {
  let sheet
  beforeEach(() => {
    sheet = { scenarioSlug: 'activity', scenario: { _id: FIRST }, qrCodeUrl: 'old', $emit: jasmine.createSpy('emit') }
    window.spyOn(scenariosApi, 'resolveAIJuniorWorksheetCode').and.returnValue(Promise.resolve({ scenarioId: FIRST, code: 'c63bd7549611' }))
    window.spyOn(QRCode, 'toDataURL').and.callFake(url => Promise.resolve(url))
  })

  it('announces readiness only after rendering the compact code', runAsync(async () => {
    const pending = AIJuniorWorksheet.options.methods.generateQRCode.call(sheet)
    expect(sheet.qrCodeUrl).toBe('')
    expect(sheet.$emit).toHaveBeenCalledWith('qr-ready', false)
    await pending
    expect(sheet.qrCodeUrl).toContain('/S/C63BD7549611')
    expect(sheet.$emit).toHaveBeenCalledWith('qr-ready', true)
  }))

  it('falls back to the exact ID if a server lookup fails', runAsync(async () => {
    scenariosApi.resolveAIJuniorWorksheetCode.and.returnValue(Promise.reject(new Error('offline')))
    await AIJuniorWorksheet.options.methods.generateQRCode.call(sheet)
    expect(sheet.qrCodeUrl).toContain('/S/' + FIRST.toUpperCase())
    expect(sheet.$emit).toHaveBeenCalledWith('qr-ready', true)
  }))

  it('refuses a compact response for another worksheet', runAsync(async () => {
    scenariosApi.resolveAIJuniorWorksheetCode.and.returnValue(Promise.resolve({ scenarioId: SECOND, code: 'abcdefabcdef' }))
    await AIJuniorWorksheet.options.methods.generateQRCode.call(sheet)
    expect(sheet.qrCodeUrl).toContain('/S/' + FIRST.toUpperCase())
  }))

  it('does not replace a newer sheet with a late QR response', runAsync(async () => {
    let finishFirst
    scenariosApi.resolveAIJuniorWorksheetCode.and.returnValue(new Promise(resolve => { finishFirst = resolve }))
    const first = AIJuniorWorksheet.options.methods.generateQRCode.call(sheet)
    sheet.scenario = { _id: SECOND }
    scenariosApi.resolveAIJuniorWorksheetCode.and.returnValue(Promise.resolve({ scenarioId: SECOND, code: 'abcdefabcdef' }))
    await AIJuniorWorksheet.options.methods.generateQRCode.call(sheet)
    finishFirst({ scenarioId: FIRST, code: 'c63bd7549611' })
    await first
    expect(sheet.qrCodeUrl).toContain('/S/ABCDEFABCDEF')
  }))
})

describe('AI Junior class print readiness', () => {
  it('waits for every student QR and disables printing again when a sheet changes', runAsync(async () => {
    const wrapper = shallowMount({
      ...AIJuniorClassPrintView,
      created () {},
      computed: { ...AIJuniorClassPrintView.computed, scenarioHandle: () => FIRST, classroomId: () => 'class' },
      data: () => ({ loading: false, scenario: { _id: FIRST }, classroom: { name: 'Class' }, members: [{ _id: 'one' }, { _id: 'two' }], readyQRs: {} }),
    })
    try {
      window.spyOn(window, 'print')
      const sheets = wrapper.findAllComponents(AIJuniorWorksheet)
      expect(wrapper.find('button').element.disabled).toBe(true)
      sheets.at(0).vm.$emit('qr-ready', true)
      await wrapper.vm.$nextTick()
      expect(wrapper.find('button').element.disabled).toBe(true)
      wrapper.vm.printAll()
      expect(window.print).not.toHaveBeenCalled()
      sheets.at(1).vm.$emit('qr-ready', true)
      await wrapper.vm.$nextTick()
      expect(wrapper.find('button').element.disabled).toBe(false)
      wrapper.vm.printAll()
      expect(window.print).toHaveBeenCalled()
      sheets.at(0).vm.$emit('qr-ready', false)
      await wrapper.vm.$nextTick()
      expect(wrapper.find('button').element.disabled).toBe(true)
    } finally { wrapper.destroy() }
  }))
})
