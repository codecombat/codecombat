StudentLoginModal = require 'views/courses/StudentLogInModal'
RecoverModal = require 'views/core/RecoverModal'
auth = require 'core/auth'

describe 'StudentLoginModal', ->
  
  modal = null
  
  beforeEach ->
    modal = new StudentLoginModal()
    modal.render()

  afterEach ->
    modal.stopListening()

  it 'displays an error when you submit an empty login form', ->
    spyOn(auth, 'loginUser').and.callFake (data, callback) ->
      callback { status: 401, responseText: "Unauthorized" }
    modal.$el.find('#log-in-btn').click()
    expect(modal.$el.html()).toContain('Wrong username or password. Try again!')
    
    jasmine.demoModal(modal)
