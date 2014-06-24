AuthModalView = require 'views/modal/auth_modal'
RecoverModalView = require 'views/modal/recover_modal'

describe 'AuthModalView', ->
  it 'opens the recover modal when you click the recover link', ->
    m = new AuthModalView()
    m.render()
    spyOn(m, 'openModalView')
    m.$el.find('#link-to-recover').click()
    expect(m.openModalView.calls.count()).toEqual(1)
    args = m.openModalView.calls.argsFor(0)
    expect(args[0] instanceof RecoverModalView).toBeTruthy()