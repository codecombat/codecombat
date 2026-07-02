const SegmentCheckView = require('views/core/CreateAccountModal/SegmentCheckView')
const BasicInfoView = require('views/core/CreateAccountModal/BasicInfoView')
const ChooseAccountTypeView = require('views/core/CreateAccountModal/ChooseAccountTypeView')
const CoppaDenyView = require('views/core/CreateAccountModal/CoppaDenyView')
const State = require('models/State')

describe('CreateAccountModal individual flow tracking', function () {
  let originalTracker

  beforeEach(function () {
    originalTracker = window.tracker
    window.tracker = {
      trackEvent: jasmine.createSpy('trackEvent'),
    }
  })

  afterEach(function () {
    window.tracker = originalTracker
  })

  it('tracks the individual age-gate next action with destination', function () {
    const signupState = new State({ path: 'individual' })
    const view = new SegmentCheckView({ signupState })

    view.trackIndividualStepNext('basic-info')

    expect(window.tracker.trackEvent).toHaveBeenCalledWith(
      'CreateAccountModal Individual Step 1 Next Clicked',
      { category: 'Individuals', destination: 'basic-info' },
    )
  })

  it('tracks the individual basic-info next action with submit state', function () {
    const signupState = new State({ path: 'individual' })
    const view = new BasicInfoView({ signupState })

    view.trackIndividualStepNext('submit-clicked')

    expect(window.tracker.trackEvent).toHaveBeenCalledWith(
      'CreateAccountModal Individual Step 2 Next Clicked',
      { category: 'Individuals', action: 'submit-clicked' },
    )
  })

  it('routes the under-13 action to the coppa-deny screen', function () {
    const signupState = new State({ path: 'individual' })
    const view = new SegmentCheckView({ signupState })
    const onNavForward = jasmine.createSpy('nav-forward')
    view.on('nav-forward', onNavForward)

    view.onClickUnder13()

    expect(onNavForward).toHaveBeenCalledWith('coppa-deny')
  })

  it('does not emit individual tracking events on a non-individual path', function () {
    const signupState = new State({ path: 'student' })
    const view = new SegmentCheckView({ signupState })

    view.trackIndividualStepNext('basic-info')

    expect(window.tracker.trackEvent).not.toHaveBeenCalled()
  })
})

describe('CreateAccountModal coppa-deny', function () {
  it('leaves a usable play CTA after the parent email is sent', function () {
    const signupState = new State({ path: 'individual' })
    const view = new CoppaDenyView({ signupState })
    view.state.set({ parentEmailSent: true }, { silent: true })
    view.render()

    const cta = view.$('.history-nav-buttons .play-without-saving-button')
    expect(cta.length).toBe(1)
    expect(cta.attr('href')).toBe('/play')
  })
})

describe('CreateAccountModal chooser sign-in', function () {
  it('emits a login event when the sign-in link is clicked', function () {
    const signupState = new State({})
    const view = new ChooseAccountTypeView({ signupState })
    const onLogin = jasmine.createSpy('login')
    view.on('login', onLogin)

    view.onClickLoginLink()

    expect(onLogin).toHaveBeenCalled()
  })
})
