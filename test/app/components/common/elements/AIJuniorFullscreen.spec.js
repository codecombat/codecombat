import { shallowMount } from '@vue/test-utils'
import AIJuniorProjectOutput from 'app/components/common/elements/AIJuniorProjectOutput.vue'

describe('AI Junior fullscreen activities', () => {
  const picture = 'data:image/svg+xml;base64,' + btoa('<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1200"><rect width="1600" height="1200" fill="purple"/></svg>')
  const render = (output, type, verify, done) => {
    const receive = event => {
      if (event.source !== wrapper?.vm.$refs.previewFrame.contentWindow || event.data?.type !== type) return
      window.removeEventListener('message', receive)
      try { verify(event.data) } finally { wrapper.destroy(); done() }
    }
    window.addEventListener('message', receive)
    const wrapper = shallowMount(AIJuniorProjectOutput, {
      attachTo: document.body,
      propsData: {
        project: { processingStatus: 'completed', promptResponses: [] },
        scenario: { output },
        readOnly: true,
      },
    })
  }

  it('keeps a tall activity readable and its final control reachable', done => {
    render({
      html: '<main><h1>A long adventure</h1><div class="art-box"><img src="' + picture + '"></div><div style="height:150vh"></div><button id="finish">Finish</button></main>',
      css: 'body { background: #fffaf0; } main { max-width: 350px; margin: auto; } .art-box { width: 80px; } .art-box img { width: 100%; }',
      js: `addEventListener('load', () => {
        document.body.classList.add('aij-fullscreen');
        requestAnimationFrame(() => {
          const top = document.querySelector('h1').getBoundingClientRect().top;
          const pictureWidth = document.querySelector('img').getBoundingClientRect().width;
          const style = getComputedStyle(document.body);
          document.querySelector('#finish').scrollIntoView({block:'end'});
          requestAnimationFrame(() => {
            const finish = document.querySelector('#finish').getBoundingClientRect();
            parent.postMessage({type:'fullscreen-activity-test', top, pictureWidth, background:style.backgroundColor, clipped:style.overflowY === 'hidden', reachable:finish.top >= 0 && finish.bottom <= innerHeight + 1}, '*');
          });
        });
      });`,
    }, 'fullscreen-activity-test', data => {
      expect(data.top).not.toBeLessThan(0)
      expect(data.pictureWidth).toBe(80)
      expect(data.background).toBe('rgb(255, 250, 240)')
      expect(data.clipped).toBe(false)
      expect(data.reachable).toBe(true)
    }, done)
  })

  it('still fits a standalone picture within the fullscreen viewport', done => {
    render({
      html: '<img src="' + picture + '">',
      css: '',
      js: `addEventListener('load', () => {
        document.body.classList.add('aij-fullscreen');
        requestAnimationFrame(() => {
          const box = document.querySelector('img').getBoundingClientRect();
          parent.postMessage({type:'fullscreen-picture-test', fits:box.width <= innerWidth && box.height <= innerHeight, ratio:box.width / box.height}, '*');
        });
      });`,
    }, 'fullscreen-picture-test', data => {
      expect(data.fits).toBe(true)
      expect(data.ratio).toBeCloseTo(4 / 3, 2)
    }, done)
  })
})
