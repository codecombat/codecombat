const SegmentCheckView = require('views/core/CreateAccountModal/SegmentCheckView')
const BasicInfoView = require('views/core/CreateAccountModal/BasicInfoView')
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
