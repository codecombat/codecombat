import { createLocalVue } from '@vue/test-utils'
import Vuex from 'vuex'
import modalsModule from 'app/core/store/modules/modals'

const localVue = createLocalVue()
localVue.use(Vuex)

describe('Vuex Modals Module', () => {
  let store

  beforeEach(() => {
    store = new Vuex.Store({
      modules: {
        modals: modalsModule
      }
    })
  })

  afterEach(() => {
    store.state.modals.modals = []
  })

  describe('mutations', () => {
    it('adds a modal to the state', () => {
      const modal = { name: 'testModal', priority: 1 }
      store.commit('modals/addModal', modal)
      const addedModal = store.state.modals.modals.find(m => m.name === modal.name)
      expect(addedModal.name).toEqual(modal.name)
      expect(addedModal.priority).toEqual(modal.priority)
    })

    it('removes a modal from the state', () => {
      const modal = { name: 'testModal', priority: 1 }
      store.commit('modals/addModal', modal)
      store.commit('modals/removeModal', 'testModal')
      const removedModal = store.state.modals.modals.find(m => m.name === modal.name)
      expect(removedModal).toBeUndefined()
    })
  })

  describe('getters', () => {
    it('returns the top modal', () => {
      const testModalLowerPrio = { name: 'testModalLowerPrio', priority: 0 }
      const testModalHigh = { name: 'testModalHigh', priority: 9 }
      const testModalLowPrio = { name: 'testModalLowPrio', priority: 3 }
      store.commit('modals/addModal', testModalLowerPrio)
      store.commit('modals/addModal', testModalHigh)
      store.commit('modals/addModal', testModalLowPrio)
      const topModal = store.getters['modals/getTopModal']
      expect(topModal.name).toEqual(testModalHigh.name)
    })

    it('returns null if there is no top modal', () => {
      expect(store.getters['modals/getTopModal']).toBeNull()
    })
  })
})
