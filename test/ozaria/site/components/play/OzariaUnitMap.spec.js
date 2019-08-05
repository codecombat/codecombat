/* eslint-env jasmine */
import { mount } from '@vue/test-utils'
import ozariaUnitMap from 'ozaria/site/components/play/PageUnitMap'
import factories from 'test/app/factories'
import Levels from 'collections/Levels'
import CourseInstance from 'collections/CourseInstances'
import Course from 'collections/Courses'
import api from 'core/api'
import store from 'core/store'

const levels = new Levels(_.times(4, () => factories.makeLevel()))
// set position, nextLevels, and first property
for (let [index, level] of levels.models.entries()) {
  level.set('position', { x: (index + 1) * 10, y: 20 })
  let nextLevel = []
  if (index + 1 < levels.models.length) {
    nextLevel = {
      levelOriginal: levels.models[index + 1].get('original')
    }
  }
  level.set('nextLevels', nextLevel)
  if (index === 0) {
    level.set('first', true)
  }
}

const campaign = factories.makeCampaignObject({ type: 'course' }, { levels: levels.models })

const courses = new Course([factories.makeCourse()])
const classroom = factories.makeClassroom({}, { levels: [levels], courses: courses })
const courseInstance = new CourseInstance([factories.makeCourseInstance({}, { course: courses.models[0], classroom: classroom })]).models[0].toJSON()

const sessions = []

let unitMapHomeWrapper = {}
let unitMapClassroomWrapper = {}

const createComponent = (values = {}) => {
  return mount(ozariaUnitMap, {
    propsData: values,
    store
  })
}

describe('Ozaria Unit Map Page for Classroom users', () => {
  beforeEach((done) => {
    spyOn(api.users, 'getLevelSessions').and.returnValue(Promise.resolve(sessions))
    spyOn(api.campaigns, 'get').and.returnValue(Promise.resolve(campaign))
    spyOn(api.courseInstances, 'get').and.returnValue(Promise.resolve(courseInstance))
    spyOn(api.classrooms, 'get').and.returnValue(Promise.resolve(classroom.toJSON()))
    spyOn(api.classrooms, 'getCourseLevels').and.callFake(function () {
      const levelsArray = []
      for (const l of levels.models) {
        levelsArray.push(l.toJSON())
      }
      return Promise.resolve(levelsArray)
    })
    me.set(factories.makeUser({ permissions: ['admin'], role: 'student' }).attributes)
    unitMapClassroomWrapper = createComponent({ campaign: campaign._id, courseInstanceId: courseInstance._id })
    _.defer(done)
  })

  it('renders a vue instance', () => {
    expect(unitMapClassroomWrapper.isVueInstance()).toBe(true)
  })

  it('shows the level dots for the classroom levels', () => {
    expect(unitMapClassroomWrapper.find('.level-dot').exists()).toBe(true)
    expect(unitMapClassroomWrapper.findAll('.level-dot').length).toBe(classroom.get('courses')[0].levels.length)
  })

  it('shows first level as unlocked and others as locked', () => {
    const levelDots = unitMapClassroomWrapper.findAll('.level-dot-image')
    for (let i = 0; i < levelDots.length; i++) {
      if (i === 0) {
        expect(levelDots.at(i).classes()).toContain('next')
        expect(levelDots.at(i).classes()).not.toContain('locked')
      } else {
        expect(levelDots.at(i).classes()).not.toContain('next')
        expect(levelDots.at(i).classes()).toContain('locked')
      }
    }
  })

  it('Chrome Layout has correct link in the store', () => {
    expect(unitMapClassroomWrapper.vm.$store.getters['layoutChrome/getMapUrl']).toEqual(`/ozaria/play/${campaign._id}?course-instance=${courseInstance._id}`)
  })
})

describe('Ozaria Unit Map Page for Home users', () => {
  beforeEach((done) => {
    spyOn(api.users, 'getLevelSessions').and.returnValue(Promise.resolve(sessions))
    spyOn(api.campaigns, 'get').and.returnValue(Promise.resolve(campaign))
    me.set(factories.makeUser({ permissions: ['admin'] }).attributes)
    unitMapHomeWrapper = createComponent({ campaign: campaign._id })
    _.defer(done)
  })

  it('renders a vue instance', () => {
    expect(unitMapHomeWrapper.isVueInstance()).toBe(true)
  })

  it('shows the level dots for the campaign levels', () => {
    expect(unitMapHomeWrapper.find('.level-dot').exists()).toBe(true)
    expect(unitMapHomeWrapper.findAll('.level-dot').length).toBe(Object.keys(campaign.levels).length)
  })

  it('shows first level as unlocked and others as locked', () => {
    const levelDots = unitMapHomeWrapper.findAll('.level-dot-image')
    for (let i = 0; i < levelDots.length; i++) {
      if (i === 0) {
        expect(levelDots.at(i).classes()).toContain('next')
        expect(levelDots.at(i).classes()).not.toContain('locked')
      } else {
        expect(levelDots.at(i).classes()).not.toContain('next')
        expect(levelDots.at(i).classes()).toContain('locked')
      }
    }
  })
})
