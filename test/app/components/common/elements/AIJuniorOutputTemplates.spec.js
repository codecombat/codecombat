import { shallowMount } from '@vue/test-utils'
import AIJuniorProjectOutput from 'app/components/common/elements/AIJuniorProjectOutput.vue'

// These strings are scenario source, evaluated later inside the iframe.
/* eslint-disable no-template-curly-in-string */

describe('AI Junior output templates', () => {
  const mount = (output, inputValues = {}) => shallowMount(AIJuniorProjectOutput, {
    propsData: {
      project: { processingStatus: 'completed', promptResponses: [], inputValues },
      scenario: { output },
      readOnly: true,
    },
  })

  it('preserves runtime expressions even when worksheet fields have the same names', () => {
    const js = 'let chapter = 0; const label = () => `Page ${chapter + 1} of 4`;'
    const wrapper = mount({ html: '<p><%= title %></p>', css: '', js }, { title: 'An adventure', chapter: 99 })
    expect(wrapper.vm.compiledOutput).toContain('<p>An adventure</p>')
    expect(wrapper.vm.compiledOutput).toContain(js)
    wrapper.destroy()
  })

  it('keeps nested literals, selectors and object expressions for the creation to evaluate', () => {
    const js = 'const label = tool => `${({ water: `Water ${count}` })[tool]}`; document.querySelector(`[data-tool="${tool}"]`);'
    const wrapper = mount({ html: '<div>Habitat</div>', css: '', js })
    expect(wrapper.vm.compiledOutput).toContain(js)
    wrapper.destroy()
  })

  it('still fills, escapes and defaults explicit worksheet placeholders in all output parts', () => {
    const wrapper = mount({
      html: '<p><%- title %>|<%= optional %>|${price}</p>',
      css: 'p { color: <%= color %>; }',
      js: 'const startingScore = <%= points %>; const label = () => `${startingScore}`;',
    }, { title: '<b>Hi</b>', color: 'purple', points: 3 })
    const html = wrapper.vm.compiledOutput
    expect(html).toContain('<p>&lt;b&gt;Hi&lt;/b&gt;||${price}</p>')
    expect(html).toContain('p { color: purple; }')
    expect(html).toContain('const startingScore = 3; const label = () => `${startingScore}`;')
    wrapper.destroy()
  })

  it('turns story pages, follows both branches and restarts inside the rendered iframe', (done) => {
    const receive = event => {
      if (event.source !== wrapper?.vm.$refs.previewFrame.contentWindow || event.data?.type !== 'template-pages-test') return
      window.removeEventListener('message', receive)
      try {
        expect(event.data.pages).toEqual(['Page 1: opening', 'Page 2: choose', 'Page 3: endingA', 'Page 1: opening', 'Page 2: choose', 'Page 3: endingB'])
      } finally {
        wrapper.destroy()
        done()
      }
    }
    window.addEventListener('message', receive)
    const wrapper = mount({
      html: '<p id="page"></p><button id="next">Next</button><button id="restart">Restart</button>',
      css: '',
      js: [
        'let chapter = 0; let choice = "A"; const pages = [];',
        'function show() { const key = chapter === 0 ? "opening" : chapter === 1 ? "choose" : `ending${choice}`; document.getElementById("page").textContent = `Page ${chapter + 1}: ${key}`; pages.push(document.getElementById("page").textContent); }',
        'document.getElementById("next").onclick = () => { chapter++; show(); };',
        'document.getElementById("restart").onclick = () => { chapter = 0; choice = "B"; show(); };',
        'show();',
        'for (const id of ["next", "next", "restart", "next", "next"]) document.getElementById(id).click();',
        'parent.postMessage({type: "template-pages-test", pages}, "*");',
      ].join('\n'),
    })
    document.body.appendChild(wrapper.element)
  })
})
