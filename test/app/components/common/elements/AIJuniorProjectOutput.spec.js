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
})
