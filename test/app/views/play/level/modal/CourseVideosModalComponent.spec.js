import { shallowMount } from '@vue/test-utils'
import videosModalComponent from 'views/play/level/modal/CourseVideosModalComponent'
import locale from 'locale/locale'
import CourseInstance from 'collections/CourseInstances'
import Course from 'collections/Courses'
import Levels from 'collections/Levels'
import factories from 'test/app/factories'
import utils from 'core/utils'
import api from 'core/api'

const createComponent = (values = {}) => {
  return shallowMount(videosModalComponent, {
    propsData: values,
    mocks: {
      $t: (text) => {
        if (text.includes('.')) {
          const res = text.split(".")
          return locale.en.translation[res[0]][res[1]];
        }
        else {
          return locale.en.translation[text]; }
        }
    }
  })
}

// create levels that have the video details
const levelTestData = Object.keys(utils.videoLevels || {}).map((l) => factories.makeLevel({original: l}))
const levels = new Levels(levelTestData)
const courses = new Course([factories.makeCourse()])
const classroom = factories.makeClassroom({}, {levels: [levels], courses: courses})
const courseInstance = new CourseInstance([factories.makeCourseInstance({}, { course: courses.models[0], classroom: classroom })])

// complete session for the first level with a video
const session = [{
  level: levelTestData[0].toJSON(),
  state: {
    complete: true
  }
}]

var wrapper;

describe('Course Videos Modal Component', () => {
  beforeEach((done) => {
    spyOn(window, 'fetch').and.callFake (() => {
      throw "This shouldn't be called!"
    })
    spyOn(api.courseInstances, 'get').and.returnValue(Promise.resolve(courseInstance.models[0].toJSON()));
    spyOn(api.classrooms, 'get').and.returnValue(Promise.resolve(classroom.toJSON()));
    spyOn(api.courseInstances, 'getSessions').and.returnValue(Promise.resolve(session));
    wrapper = createComponent({courseInstanceID: courseInstance.models[0].id, courseID: courses.models[0].id})
    _.defer(done)
  })

  it('renders a vue instance', () => {
    expect(wrapper.isVueInstance()).toBe(true)
  });

  it('shows the video thumbnails and text', () => {
    expect(wrapper.find('#videos-content').exists()).toBe(true)
    expect(wrapper.find('.videos-row').exists()).toBe(true)
    expect(wrapper.find('.video-image').exists()).toBe(true)
    expect(wrapper.findAll('.video-image').length).toBe(3)
    expect(wrapper.find('.video-title').exists()).toBe(true)
    expect(wrapper.findAll('.video-title').length).toBe(3)
    expect(wrapper.find('.video-desc').exists()).toBe(true)
    expect(wrapper.findAll('.video-desc').length).toBe(3)
    expect(wrapper.find('.video-status').exists()).toBe(true)
    expect(wrapper.findAll('.video-status').length).toBe(3)
  })

  it('shows 1 video as unlocked and other 2 as locked', () => {
    expect(wrapper.findAll('.locked').exists()).toBe(true)
    expect(wrapper.findAll('.locked').length).toBe(2)
    expect(wrapper.findAll('.unlocked').exists()).toBe(true)
    expect(wrapper.findAll('.unlocked').length).toBe(1)
  })

  it('sets the iframe video src when clicked on an unlocked thumbnail', () => {
    spyOn($.fn, 'init').and.callFake((el) => {
      return [wrapper.find(el).element]
    })
    expect(wrapper.find('.video-frame').attributes().src).toBeUndefined()
    wrapper.findAll('.video-image').at(0).trigger('click')
    expect(wrapper.find('.video-frame').attributes().src).toBeDefined()
  })

  it('doesnt do anything when clicked on a locked thumbnail', () => {
    expect(wrapper.find('.video-frame').attributes().src).toBeUndefined()
    wrapper.findAll('.video-image').at(1).trigger('click')
    expect(wrapper.find('.video-frame').attributes().src).toBeUndefined()
  })
})
