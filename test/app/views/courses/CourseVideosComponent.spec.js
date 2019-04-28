import { shallowMount } from '@vue/test-utils'
import videosComponent from 'views/courses/CourseVideosComponent'
import locale from 'locale/locale'
import { registerSnapshots, expectxml } from 'jasmine-snapshot'
import snapshot from './CourseVideosComponent.snapshot'

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
const expectedSnapshots = {
  'Client Course Videos Component it matches the snapshot 1': snapshot
}

const wrapper = createComponent({ courseName: courseName })

describe('Course Videos Component', () => {
  beforeEach(() => {
    registerSnapshots(expectedSnapshots, 'CourseVideosComponent snapshots')
  })

  it('renders a vue instance', () => {
    expect(wrapper.isVueInstance()).toBe(true)
  })

  it('it matches the snapshot', () => {
    expectxml(wrapper.html()).toMatchSnapshot()
  })

  it('shows the course name', () => {
    expect(wrapper.find('.course-name').text()).toEqual(courseName)
  })

  it('shows the videos and concept text', () => {
    expect(wrapper.find('#videos-content').exists()).toBe(true)
    expect(wrapper.findAll('.video').exists()).toBe(true)
    expect(wrapper.findAll('.video').length).toBe(3)
    expect(wrapper.findAll('.concept-text').exists()).toBe(true)
    expect(wrapper.findAll('.concept-text').length).toBe(3)
  })
})
