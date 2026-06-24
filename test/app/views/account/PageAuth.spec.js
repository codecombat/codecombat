import { shallowMount } from '@vue/test-utils'
import PageAuth from 'views/account/PageAuth'
const { me } = require('core/auth')

const makeWrapper = ({ mode = 'signup', screen = 'birthday', query = {} } = {}) => {
  const push = jasmine.createSpy('push').and.returnValue(Promise.resolve())
  const wrapper = shallowMount(PageAuth, {
    propsData: { mode, screen },
    mocks: {
      $route: { path: '/signup', query },
      $router: { push },
    },
    stubs: {
      AuthWelcomeScreen: true,
      AuthChooserScreen: true,
      AuthEducatorSignInScreen: true,
      AuthEducatorCreateAccountScreen: true,
      AuthEducatorClassReadyScreen: true,
      AuthParentCreateAccountScreen: true,
      AuthParentAddChildScreen: true,
      AuthParentSuccessScreen: true,
      AuthEUConfirmationScreen: true,
      AuthClassCodeScreen: true,
      AuthClassUsernameScreen: true,
      AuthClassSuccessScreen: true,
      AuthBirthdayScreen: true,
      AuthSoloCreateAccountScreen: true,
      AuthCoppaScreen: true,
      AuthLoginScreen: true,
    },
  })
  return { wrapper, push }
}

describe('PageAuth regulatory flows', () => {
  afterEach(() => {
    document.body.classList.remove('auth-route-standalone')
  })

  it('routes of-age class signup through EU confirmation before username creation', () => {
    const { wrapper, push } = makeWrapper({ screen: 'birthday', query: { pathKind: 'class' } })
    spyOn(me, 'inEU').and.returnValue(true)

    wrapper.vm.handleBirthdayContinue({
      month: '1',
      day: '1',
      year: String(new Date().getFullYear() - 20),
    })

    expect(push).toHaveBeenCalledWith({
      path: '/signup',
      query: { screen: 'eu-confirmation', pathKind: 'class', nextScreen: 'class-username' },
    })
  })

  it('routes below-threshold class signup to COPPA using per-country ageOfConsent', () => {
    const { wrapper, push } = makeWrapper({ screen: 'birthday', query: { pathKind: 'class' } })
    spyOn(me, 'inEU').and.returnValue(false)
    me.set('country', 'germany')

    wrapper.vm.handleBirthdayContinue({
      month: '1',
      day: '1',
      year: String(new Date().getFullYear() - 15),
    })

    expect(push).toHaveBeenCalledWith({
      path: '/signup',
      query: { screen: 'coppa', pathKind: 'class' },
    })
  })

  it('records EU consent and advances to the requested next screen', () => {
    const { wrapper, push } = makeWrapper({ screen: 'eu-confirmation', query: { pathKind: 'educator', nextScreen: 'educator-create' } })

    wrapper.vm.submitEUConfirmation()

    expect(wrapper.vm.euConsentGranted.educator).toBe(true)
    expect(push).toHaveBeenCalledWith({
      path: '/signup',
      query: { screen: 'educator-create' },
    })
  })

  it('disables marketing emails for EU users after consented signup', () => {
    const { wrapper } = makeWrapper({ screen: 'create-account' })
    spyOn(me, 'inEU').and.returnValue(true)
    me.set('emails', {})

    wrapper.vm.applyEUMarketingOptOut()

    expect(me.get('emails').generalNews.enabled).toBe(false)
    expect(me.get('unsubscribedFromMarketingEmails')).toBe(true)
  })
})
