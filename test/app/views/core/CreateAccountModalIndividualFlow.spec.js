const ChooseAccountTypeView = require('views/core/CreateAccountModal/ChooseAccountTypeView')
const State = require('models/State')

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
