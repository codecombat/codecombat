EditStudentModal = require 'views/teachers/EditStudentModal'
User = require 'models/User'
factories = require 'test/app/factories'

describe 'ActivateLicensesModal', ->

  user = null
  modal = null
  email = "test@example.com"
  newPassword = "new password"

  describe 'for a verified user', ->
    beforeEach (done) ->
      user = factories.makeUser({ email, emailVerified: true })
      modal = new EditStudentModal({ user })
      jasmine.demoModal(modal)
      modal.render()
      _.defer done

    it 'has a button to send a password reset email', ->
      if modal.$('.send-recovery-email-btn').length < 1
        fail "Expected there to be a Send Recovery Email button"

    it 'sends the verification email request', ->
      modal.$('.send-recovery-email-btn').click()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.params).toEqual("email=#{encodeURIComponent(email)}")

    it 'updates the button after the request is sent', ->
      modal.$('.send-recovery-email-btn').click()
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({ status: 200, responseText: "{}" })
      expect(modal.$('.send-recovery-email-btn').text()).toEqual('Email sent')

  describe 'for an unverified user', ->
    beforeEach (done) ->
      user = factories.makeUser({ email , emailVerified: false })
      modal = new EditStudentModal({ user })
      jasmine.demoModal(modal)
      modal.render()
      _.defer done

    it "has a new password field", ->
      modal.render()
      if modal.$('.new-password-input').length < 1
        fail "Expected there to be a new password input field"

    it "has a change password button", ->
      modal.render()
      if modal.$('.change-password-btn').length < 1
        fail "Expected there to be a Change Password button"

    describe 'when you click the button', ->
      it 'sends a request', ->
        modal.$('.change-password-btn').click()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request).toBeDefined()

      it 'updates the button', ->
        modal.$('.new-password-input').text(newPassword).change()
        modal.$('.change-password-btn').click()
        request = jasmine.Ajax.requests.mostRecent()
        fail "Expected a request to be sent" unless request
        request?.respondWith({ status: 200, responseText: JSON.stringify(user) })
        expect(modal.$('.change-password-btn').text()).toEqual('Changed')
