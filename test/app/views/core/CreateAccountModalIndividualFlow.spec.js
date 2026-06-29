const SegmentCheckView = require('views/core/CreateAccountModal/SegmentCheckView')
const BasicInfoView = require('views/core/CreateAccountModal/BasicInfoView')
const ChooseAccountTypeView = require('views/core/CreateAccountModal/ChooseAccountTypeView')
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
