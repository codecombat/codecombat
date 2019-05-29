import { shallowMount } from '@vue/test-utils'
import videosComponent from 'views/courses/CourseVideosComponent'
import locale from 'locale/locale'
import factories from 'test/app/factories'

const createComponent = (values = {}) => {
  return shallowMount(videosComponent, {
    propsData: values,
    mocks: {
      $t: (text) => {
        if (text.includes('.')) {
          const res = text.split('.')
          return locale.en.translation[res[0]][res[1]]
        } else {
          return locale.en.translation[text]
        }
      }

    }
  })
}
const courseName = 'Introduction to Computer Science'
const wrapper = createComponent({ courseName: courseName })

describe('Course Videos Component', () => {
  it('renders a vue instance', () => {
    expect(wrapper.isVueInstance()).toBe(true)
  })

  it('shows the course name', () => {
    expect(wrapper.find('.course-name').text()).toEqual(courseName)
  })

  it('shows the videos and concept text', () => {
    expect(wrapper.find('#videos-content').exists()).toBe(true)
    expect(wrapper.findAll('.concept-text').exists()).toBe(true)
    expect(wrapper.findAll('.concept-text').length).toBe(3)
    const me = factories.makeUser({})
    if (me.showChinaVideo()) {
      expect(wrapper.findAll('video').exists()).toBe(true)
      expect(wrapper.findAll('video').length).toBe(3)
    } else {
      expect(wrapper.findAll('.video').exists()).toBe(true)
      expect(wrapper.findAll('.video').length).toBe(3)
    }
  })
})
