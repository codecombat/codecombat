import { shallowMount } from '@vue/test-utils'
import AIJuniorProjectOutput from 'app/components/common/elements/AIJuniorProjectOutput.vue'
import { previewHeight } from 'app/lib/ai-junior-frame'

describe('AI Junior result sandbox', () => {
  it('runs a creation while denying access to the parent page and origin storage', (done) => {
    const receive = (event) => {
      if (event.source !== wrapper?.vm.$refs.previewFrame.contentWindow || event.data?.type !== 'sandbox-test') return
      try {
        expect(event.data.ran).toBe(true)
        expect(event.data.parentBlocked).toBe(true)
        expect(event.data.storageBlocked).toBe(true)
        expect(event.origin).toBe('null')
      } finally {
        window.removeEventListener('message', receive)
        wrapper.destroy()
        done()
      }
    }
    window.addEventListener('message', receive)
    const wrapper = shallowMount(AIJuniorProjectOutput, {
      attachTo: document.body,
      propsData: {
        project: { processingStatus: 'completed', promptResponses: [] },
        scenario: {
          output: {
            html: '<div id="creation">Ready</div>',
            css: '',
            js: `
              const result = { type: 'sandbox-test', ran: false, parentBlocked: false, storageBlocked: false };
              document.getElementById('creation').textContent = 'Playing';
              result.ran = document.getElementById('creation').textContent === 'Playing';
              try { parent.document.body; } catch (error) { result.parentBlocked = true; }
              try { localStorage.length; } catch (error) { result.storageBlocked = true; }
              parent.postMessage(result, '*');
            `,
          },
        },
        readOnly: true,
      },
    })
  })

  it('ignores messages from other frames and rejects invalid sizes', () => {
    const frame = { contentWindow: {} }
    const event = { source: {}, data: { type: 'ai-junior:size', height: 500 } }
    expect(previewHeight(event, frame, 800)).toBe(null)
    event.source = frame.contentWindow
    for (const height of [-1, '500', NaN, Infinity, null]) {
      event.data.height = height
      expect(previewHeight(event, frame, 800)).toBe(null)
    }
    event.data = { type: 'unrelated', height: 500 }
    expect(previewHeight(event, frame, 800)).toBe(null)
  })

  it('bounds a creation’s requested height to the visible viewport', () => {
    const frame = { contentWindow: {} }
    const event = { source: frame.contentWindow, data: { type: 'ai-junior:size', height: 1000000 } }
    expect(previewHeight(event, frame, 800)).toBe(680)
    event.data.height = 300
    expect(previewHeight(event, frame, 800)).toBe(324)
    event.data.height = 1
    expect(previewHeight(event, frame, 800)).toBe(240)
  })

  it('coalesces a burst of valid messages into one bounded update with the latest size', () => {
    let flush
    const timer = window.spyOn(window, 'setTimeout').and.callFake((fn, delay) => { flush = fn; expect(delay).toBe(100); return 123 })
    const setHeight = jasmine.createSpy('set height')
    const frame = { contentWindow: {}, style: {} }
    Object.defineProperty(frame.style, 'height', { set: setHeight, get: () => '' })
    const context = { $refs: { previewFrame: frame, previewWrap: {} } }
    const receive = height => AIJuniorProjectOutput.methods.onPreviewMessage.call(context, { source: frame.contentWindow, data: { type: 'ai-junior:size', height } })
    for (let height = 0; height < 500; height++) receive(height)
    expect(timer.calls.count()).toBe(1)
    expect(setHeight).not.toHaveBeenCalled()
    flush()
    expect(setHeight.calls.count()).toBe(1)
    expect(setHeight).toHaveBeenCalledWith(`${Math.min(523, Math.round(window.innerHeight * 0.85))}px`)
    receive(300)
    expect(timer.calls.count()).toBe(2)
    // A stale frame must not resize its replacement after a compare toggle.
    context.$refs.previewFrame = { contentWindow: {}, style: {} }
    flush()
    expect(setHeight.calls.count()).toBe(1)
  })

  it('cancels queued resize work when the component is destroyed', () => {
    const clear = window.spyOn(window, 'clearTimeout')
    AIJuniorProjectOutput.beforeDestroy.call({ _previewResizeTimer: 123 })
    expect(clear).toHaveBeenCalledWith(123)
  })

  it('retains the first size report from a replacement frame while a timer is pending', () => {
    let flush
    window.spyOn(window, 'setTimeout').and.callFake(fn => { flush = fn; return 123 })
    const oldFrame = { contentWindow: {}, style: {} }
    const newFrame = { contentWindow: {}, style: {} }
    const context = { $refs: { previewFrame: oldFrame, previewWrap: {} } }
    const receive = frame => AIJuniorProjectOutput.methods.onPreviewMessage.call(context, { source: frame.contentWindow, data: { type: 'ai-junior:size', height: 300 } })
    receive(oldFrame)
    context.$refs.previewFrame = newFrame
    receive(newFrame)
    flush()
    expect(oldFrame.style.height).toBeUndefined()
    expect(newFrame.style.height).toBe(`${Math.min(324, Math.round(window.innerHeight * 0.85))}px`)
  })
})
