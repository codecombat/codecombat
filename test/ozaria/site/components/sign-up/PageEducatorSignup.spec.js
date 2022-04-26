/* eslint-env jasmine */
import { mount, createLocalVue } from '@vue/test-utils'
import Vuex from 'vuex'
import VueScrollTo from 'vue-scrollto'
import PageEducatorSignup from 'ozaria/site/components/sign-up/PageEducatorSignup/index'
import PageStartSignup from 'ozaria/site/components/sign-up/PageEducatorSignup/PageStartSignup'
import PageBasicInfo from 'ozaria/site/components/sign-up/PageEducatorSignup/PageBasicInfo'
import store from 'core/store'

const isChinaServer = window.features.china

const createComponent = (values = {}) => {
  const localVue = createLocalVue()
  localVue.use(Vuex)
  localVue.use(VueScrollTo)
  return mount(PageEducatorSignup, {
    store,
    localVue
  })
}

let pageEducatorSignupWrapper

const firstExpectedComponent = isChinaServer ? PageBasicInfo : PageStartSignup

describe('Educator sign up page', () => {
  beforeEach((done) => {
    pageEducatorSignupWrapper = createComponent()
    _.defer(done)
  })

  it('renders a vue instance and the first expected component is visible', () => {
    expect(pageEducatorSignupWrapper.isVueInstance()).toBe(true)
    expect(pageEducatorSignupWrapper.contains(firstExpectedComponent)).toBe(true)
    pageEducatorSignupWrapper.destroy()
  })

  if (!isChinaServer) {
    it('scrolls to the basic info form when sign-up is clicked', async (done) => {
      expect(pageEducatorSignupWrapper.contains(PageBasicInfo)).toBe(false)
      await pageEducatorSignupWrapper.find('.email-sign-up').find('a').trigger('click')
      expect(pageEducatorSignupWrapper.contains(PageBasicInfo)).toBe(true)
      pageEducatorSignupWrapper.destroy()
      done()
    })
  }

  // Not adding a test for scrollbale UX, because it would need each input in the form
  // to be filled out to scroll to the next form - That seems to be too specific for a unit test,
  // and should be covered in an integration test.
})
