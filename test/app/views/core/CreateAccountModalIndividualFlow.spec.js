const SegmentCheckView = require('views/core/CreateAccountModal/SegmentCheckView')
const BasicInfoView = require('views/core/CreateAccountModal/BasicInfoView')
const ChooseAccountTypeView = require('views/core/CreateAccountModal/ChooseAccountTypeView')
const CoppaDenyView = require('views/core/CreateAccountModal/CoppaDenyView')
const EUConfirmationView = require('views/core/CreateAccountModal/EUConfirmationView')
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

  it('emits the uniform next event from each individual step with a step slug', function () {
    const signupState = new State({ path: 'individual' })

    new SegmentCheckView({ signupState }).trackIndividualStepNext('coppa-deny')
    new CoppaDenyView({ signupState }).trackIndividualStepNext('send-parent-email')
    new EUConfirmationView({ signupState }).trackIndividualStepNext('continue')

    expect(window.tracker.trackEvent).toHaveBeenCalledWith(
      'CreateAccountModal Individual Next Clicked',
      { category: 'Individuals', step: 'segment-check', label: 'coppa-deny' },
    )
    expect(window.tracker.trackEvent).toHaveBeenCalledWith(
      'CreateAccountModal Individual Next Clicked',
      { category: 'Individuals', step: 'coppa-deny', label: 'send-parent-email' },
    )
    expect(window.tracker.trackEvent).toHaveBeenCalledWith(
      'CreateAccountModal Individual Next Clicked',
      { category: 'Individuals', step: 'eu-confirmation', label: 'continue' },
    )
  })

  it('does not emit the uniform next event on a non-individual path', function () {
    const signupState = new State({ path: 'student' })

    new EUConfirmationView({ signupState }).trackIndividualStepNext('continue')

    expect(window.tracker.trackEvent).not.toHaveBeenCalled()
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
  it('emits a single login event when the sign-in link is clicked', function () {
    const signupState = new State({})
    const view = new ChooseAccountTypeView({ signupState })
    const onLogin = jasmine.createSpy('login')
    view.on('login', onLogin)
    view.render()

    view.$('.login-link').trigger('click')

    expect(onLogin).toHaveBeenCalledTimes(1)
  })
})
