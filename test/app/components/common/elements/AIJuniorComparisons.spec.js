import { shallowMount } from '@vue/test-utils'
import AIJuniorProjectOutput from 'app/components/common/elements/AIJuniorProjectOutput.vue'
import ImageCompareSlider from 'app/components/common/elements/ImageCompareSlider.vue'
const runAsync = fn => done => { fn().then(() => done(), error => done.fail(error)) }

describe('AI Junior comparison presentation', () => {
  let wrapper
  const picture = '<img src="<%= artwork %>">'
  function create (output) {
    wrapper = shallowMount(AIJuniorProjectOutput, {
      propsData: {
        readOnly: true,
        project: { processingStatus: 'completed', inputValues: { sketch: '/drawing.png' }, promptResponses: [{ promptId: 'artwork', image: '/creation.png' }] },
        scenario: { inputs: [{ id: 'sketch', type: 'image-field' }], prompts: [{ id: 'artwork', files: ['sketch'] }], output },
      },
    })
    return wrapper.vm
  }
  afterEach(() => wrapper.destroy())

  it('uses a slider for a bare image without repeating the original', () => {
    const view = create({ html: picture, css: ' ', js: '\n' })
    expect(view.creationComparison.drawingId).toBe('sketch')
    expect(view.originals).toEqual([])
  })

  for (const asset of ['css', 'js']) {
    it(`retains the iframe when the picture has authored ${asset}`, () => {
      const content = asset === 'css' ? 'img { border: 1px solid blue; }' : 'window.artworkReady = true;'
      const view = create({ html: picture, [asset]: content })
      expect(view.creationComparison).toBe(null)
      expect(wrapper.find('iframe').exists()).toBe(true)
      expect(view.compiledOutput).toContain(content)
    })
  }

  it('hides the duplicated crop only while preview comparisons are visible', runAsync(async () => {
    const view = create({ html: `<div>${picture}</div>` })
    expect(view.originals.length).toBe(1)
    await wrapper.setData({ showCompare: true })
    expect(view.originals).toEqual([])
    await wrapper.setData({ showCompare: false })
    expect(view.originals.length).toBe(1)
  }))

  it('keeps the full worksheet visible alongside a comparison', runAsync(async () => {
    const view = create({ html: picture })
    await wrapper.setProps({ project: { ...view.project, uploadedWorksheet: 'sheet.png' } })
    expect(view.originals[0].id).toBe('worksheet')
  }))

  it('gives the full-size link a descriptive accessible name', () => {
    wrapper = shallowMount(ImageCompareSlider, { propsData: { original: '/drawing.png', generated: '/creation.png' } })
    expect(wrapper.find('a.compare-fullsize').attributes('aria-label')).toBe('Open full size')
  })
})
