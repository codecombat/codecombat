import { shallowMount, createLocalVue } from '@vue/test-utils'
import VueMeta from 'vue-meta'

import playLevelVideoComponent from 'views/play/level/PlayLevelVideoComponent'
import locale from 'locale/locale'
import utils from 'core/utils'

const createComponent = (values = {}) => {
  const vue = createLocalVue()
  vue.use(VueMeta)

  return shallowMount(playLevelVideoComponent, {
    localVue: vue,

    propsData: values,
    mocks: {
      $t: (text) => {
        if (text.includes('.')) {
          const res = text.split(".")
          return locale.en.translation[res[0]][res[1]];
        }
        else {
          return locale.en.translation[text];
        }
      }
    }
  })
}

const props = {
  // a level id with the video details
  levelOriginalID: Object.keys(utils.videoLevels || {})[0] || '54173c90844506ae0195a0b4',
  levelSlug: 'test-level-slug',
  courseInstanceID: 'test-course-instance-id',
  courseID: 'test-course-id'
}

const wrapper = createComponent(props);

describe('Play Level Video View', () => {

  it('renders a vue instance', () => {
    expect(wrapper.isVueInstance()).toBe(true)
  });

  it('shows the video title and video', () => {
    expect(wrapper.find('.video-title').exists()).toBe(true)
    expect(wrapper.find('.video-title').text()).toContain(utils.videoLevels[props.levelOriginalID].title)
    expect(wrapper.find('.video').exists()).toBe(true)
  })

  it('shows skip button and hides Next Level Button', () => {
    expect(wrapper.find('.buttons-row').exists()).toBe(true)
    expect(wrapper.find('#skip-btn').exists()).toBe(true)
    expect(wrapper.find('#next-level-btn').exists()).toBe(true)
    expect(wrapper.find('#next-level-btn').isVisible()).toBe(false)
  })
})
