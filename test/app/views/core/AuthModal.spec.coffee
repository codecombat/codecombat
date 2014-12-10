AuthModal = require 'views/core/AuthModal'
RecoverModal = require 'views/core/RecoverModal'

describe 'AuthModal', ->
  it 'opens the recover modal when you click the recover link', ->
    m = new AuthModal({mode: 'login'})
    m.render()
    spyOn(m, 'openModalView')
    m.$el.find('#link-to-recover').click()
    expect(m.openModalView.calls.count()).toEqual(1)
    args = m.openModalView.calls.argsFor(0)
    expect(args[0] instanceof RecoverModal).toBeTruthy()
