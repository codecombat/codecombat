const SegmentCheckView = require('views/core/CreateAccountModal/SegmentCheckView')
const CoppaDenyView = require('views/core/CreateAccountModal/CoppaDenyView')
const State = require('models/State')
const contact = require('core/contact')

describe('CreateAccountModal COPPA parent email flow', function () {
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

  it('routes under-13 individuals to the parent email handoff', function () {
    const birthday = new Date()
    birthday.setFullYear(birthday.getFullYear() - 10)

    const signupState = new State({
      path: 'individual',
      birthday,
    })
    const view = new SegmentCheckView({ signupState })
    jasmine.spyOn(view, 'trigger')

    view.onSubmitSegmentCheck({ preventDefault () {} })

    expect(view.trigger).toHaveBeenCalledWith('nav-forward', 'coppa-deny')
    expect(window.tracker.trackEvent).toHaveBeenCalledWith(
      'CreateAccountModal Individual SegmentCheckView Parent Email Required',
      { category: 'Individuals' },
    )
  })

  it('marks parent email as sent after successful handoff', function (done) {
    const signupState = new State({ path: 'individual' })
    const view = new CoppaDenyView({ signupState })
    jasmine.spyOn(contact, 'sendParentSignupInstructions').and.returnValue(Promise.resolve())

    view.state.set({ parentEmail: 'parent@example.com' })
    view.onClickSendParentEmailButton({ preventDefault () {} })

    Promise.resolve().then(() => {
      expect(contact.sendParentSignupInstructions).toHaveBeenCalledWith('parent@example.com')
      expect(view.state.get('parentEmailSent')).toBe(true)
      expect(view.state.get('parentEmailSending')).toBe(false)
      expect(window.tracker.trackEvent).toHaveBeenCalledWith(
        'CreateAccountModal Individual Parent Email Send Clicked',
        { category: 'Individuals' },
      )
      done()
    })
  })

  it('rejects invalid parent emails before sending', function () {
    const signupState = new State({ path: 'individual' })
    const view = new CoppaDenyView({ signupState })
    jasmine.spyOn(contact, 'sendParentSignupInstructions')

    view.state.set({ parentEmail: 'not-an-email' })
    view.onClickSendParentEmailButton({ preventDefault () {} })

    expect(contact.sendParentSignupInstructions).not.toHaveBeenCalled()
    expect(view.state.get('error')).toBe(true)
    expect(view.state.get('parentEmailSent')).toBe(false)
  })
})
