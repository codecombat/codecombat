/* eslint-env jasmine */
import { mount } from '@vue/test-utils'
import pageInteractive from 'ozaria/site/components/interactive/PageInteractive/index'
import factories from 'test/app/factories'
import * as interactiveApi from 'ozaria/site/api/interactive'
import draggableOrderingComponent from 'ozaria/site/components/interactive/PageInteractive/draggableOrdering/index'
import inserCodeComponent from 'ozaria/site/components/interactive/PageInteractive/insertCode'
import draggableStatementCompletionComponent from 'ozaria/site/components/interactive/PageInteractive/draggableStatementCompletion'

const createComponent = (values = {}) => {
  return mount(pageInteractive, {
    propsData: values
  })
}

const interactive = {
  interactiveType: 'draggable-ordering',
  promptText: 'Interactive prompt text',
  _id: 'interactiveId1'
}

const introLevel = {
  _id: 'intro-level-id'
} // Dummy intro level object

let pageInteractiveWrapper

describe('Interactive Page', () => {
  beforeEach((done) => {
    spyOn(interactiveApi, 'getInteractive').and.returnValue(Promise.resolve(interactive))
    spyOn(interactiveApi, 'getSession').and.returnValue(Promise.resolve({}))
    me.set(factories.makeUser({ permissions: ['admin'] }).attributes)
    pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id, introLevelId: introLevel._id })
    _.defer(done)
  })
  it('renders a vue instance', () => {
    expect(pageInteractiveWrapper.isVueInstance()).toBe(true)
  })

  it('emits `completed` event on completion of child component', () => {
    const childComponent = pageInteractiveWrapper.find(draggableOrderingComponent)
    childComponent.vm.$emit('completed')
    expect(pageInteractiveWrapper.emitted().completed).toBeTruthy()
  })

  describe('renders draggable-ordering component for interactive type draggable-ordering', () => {
    beforeEach((done) => {
      interactive.interactiveType = 'draggable-ordering'
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id, introLevelId: introLevel._id })
      _.defer(done)
    })
    it('renders correct component', () => {
      expect(pageInteractiveWrapper.contains(draggableOrderingComponent)).toBe(true)
      expect(pageInteractiveWrapper.contains(inserCodeComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(draggableStatementCompletionComponent)).toBe(false)
    })
  })

  describe('renders insert-code component for interactive type insert-code', () => {
    beforeEach((done) => {
      interactive.interactiveType = 'insert-code'
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id, introLevelId: introLevel._id })
      _.defer(done)
    })
    it('renders correct component', () => {
      expect(pageInteractiveWrapper.contains(draggableOrderingComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(inserCodeComponent)).toBe(true)
      expect(pageInteractiveWrapper.contains(draggableStatementCompletionComponent)).toBe(false)
    })
  })

  describe('renders draggable-statement-completion component for interactive type draggable-statement-completion', () => {
    beforeEach((done) => {
      interactive.interactiveType = 'draggable-statement-completion'
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id, introLevelId: introLevel._id })
      _.defer(done)
    })
    it('renders correct component', () => {
      expect(pageInteractiveWrapper.contains(draggableOrderingComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(inserCodeComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(draggableStatementCompletionComponent)).toBe(true)
    })
  })
})
