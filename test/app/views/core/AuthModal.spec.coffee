AuthModal = require 'views/core/AuthModal'
RecoverModal = require 'views/core/RecoverModal'

describe 'AuthModal', ->
  
  modal = null
  
  beforeEach ->
    application.facebookHandler.fakeAPI()
    application.gplusHandler.fakeAPI()
    modal = new AuthModal()
    modal.render()

  afterEach ->
    modal.stopListening()

  it 'opens the recover modal when you click the recover link', ->
    spyOn(modal, 'openModalView')
    modal.$el.find('#link-to-recover').click()
    expect(modal.openModalView.calls.count()).toEqual(1)
    args = modal.openModalView.calls.argsFor(0)
    expect(args[0] instanceof RecoverModal).toBeTruthy()

  it '(demo)', ->
    jasmine.demoModal(modal)
