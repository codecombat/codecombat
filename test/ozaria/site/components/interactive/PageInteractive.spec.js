/* eslint-env jasmine */
import { shallowMount } from '@vue/test-utils'

import factories from 'test/app/factories'

import pageInteractive from 'ozaria/site/components/interactive/PageInteractive/index'
import draggableOrderingComponent from 'ozaria/site/components/interactive/PageInteractive/draggableOrdering/index'
import insertCodeComponent from 'ozaria/site/components/interactive/PageInteractive/insertCode'
import draggableStatementCompletionComponent from 'ozaria/site/components/interactive/PageInteractive/draggableStatementCompletion/index'

const interactive = {
  interactiveType: 'draggable-ordering',
  promptText: 'Interactive prompt text',
  _id: 'interactiveId1',

  // Have all data options available chosen by type.
  draggableStatementCompletionData: {
    elements: [
      {
        textStyleCode: true,
        text: 'Something',
        elementId: '5d12b22025196e3473b88b8e'
      }
    ],
    labels: [
      {
        text: 'label 1'
      }
    ]
  },
  insertCodeData: {
    starterCode: 'some code\nline2\nline3\nline4',
    lineToReplace: 2
  },
  draggableOrderingData: {
    elements: [
      {
        text: 'Something',
        elementId: '5d12b22025196e3473b88b8e'
      }
    ],
    labels: [
      {
        text: 'label 1'
      }
    ]
  }
}

const store = new Vuex.Store({
  modules: {
    interactives: {
      namespaced: true,

      mutations: {
        toggleInteractiveLoading () { },

        toggleInteractiveSessionLoading () { },

        addInteractive () { },

        addInteractiveSession () { }
      },

      getters: {
        currentInteractiveDataLoading () {
          return false
        },

        currentInteractive () {
          return interactive
        },

        currentInteractiveSession () {
          return {}
        }
      },

      actions: {
        async loadInteractive () { },

        async loadInteractiveSession () { }
      }
    }
  }
})

const createComponent = (values = {}) => {
  return shallowMount(pageInteractive, {
    propsData: values,
    store
  })
}

describe('Interactive Page', () => {
  beforeEach((done) => {
    // TODO remove after Ozaria launch
    me.set(factories.makeUser({ permissions: ['admin'] }).attributes)
    _.defer(done)
  })

  describe('Default functionality', () => {
    let pageInteractiveWrapper

    it('renders a vue instance', () => {
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id })
      expect(pageInteractiveWrapper.isVueInstance()).toBe(true)
    })

    it('emits `completed` event on completion of child component', () => {
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id })
      const childComponent = pageInteractiveWrapper.find(draggableOrderingComponent)
      childComponent.vm.$emit('completed')
      expect(pageInteractiveWrapper.emitted().completed).toBeTruthy()
    })
  })
  describe('renders draggable-ordering component for interactive type draggable-ordering', () => {
    let pageInteractiveWrapper
    beforeEach((done) => {
      interactive.interactiveType = 'draggable-ordering'
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id })
      _.defer(done)
    })
    it('renders correct component', () => {
      expect(pageInteractiveWrapper.contains(draggableOrderingComponent)).toBe(true)
      expect(pageInteractiveWrapper.contains(insertCodeComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(draggableStatementCompletionComponent)).toBe(false)
    })
  })

  describe('renders insert-code component for interactive type insert-code', () => {
    let pageInteractiveWrapper
    beforeEach((done) => {
      interactive.interactiveType = 'insert-code'
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id })
      _.defer(done)
    })
    it('renders correct component', () => {
      expect(pageInteractiveWrapper.contains(draggableOrderingComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(insertCodeComponent)).toBe(true)
      expect(pageInteractiveWrapper.contains(draggableStatementCompletionComponent)).toBe(false)
    })
  })

  describe('renders draggable-statement-completion component for interactive type draggable-statement-completion', () => {
    let pageInteractiveWrapper
    beforeEach((done) => {
      interactive.interactiveType = 'draggable-statement-completion'
      pageInteractiveWrapper = createComponent({ interactiveIdOrSlug: interactive._id })
      _.defer(done)
    })
    it('renders correct component', () => {
      expect(pageInteractiveWrapper.contains(draggableOrderingComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(insertCodeComponent)).toBe(false)
      expect(pageInteractiveWrapper.contains(draggableStatementCompletionComponent)).toBe(true)
    })
  })
})
