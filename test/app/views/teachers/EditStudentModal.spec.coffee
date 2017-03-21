EditStudentModal = require 'views/teachers/EditStudentModal'
User = require 'models/User'
factories = require 'test/app/factories'

describe 'EditStudentModal', ->

  user = null
  modal = null
  email = "test@example.com"
  newPassword = "new password"

  describe 'for a verified user', ->
    beforeEach (done) ->
      user = factories.makeUser({ email, emailVerified: true })
      classroom = factories.makeClassroom()
      modal = new EditStudentModal({ user, classroom })
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({ status: 200, responseText: JSON.stringify(user) })
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
      expect(modal.$('.send-recovery-email-btn [data-i18n]').data('i18n')).toEqual('teacher.email_sent')

  describe 'for an unverified user', ->
    beforeEach (done) ->
      user = factories.makeUser({ email , emailVerified: false })
      classroom = factories.makeClassroom()
      modal = new EditStudentModal({ user, classroom })
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({ status: 200, responseText: JSON.stringify(user) })
      jasmine.demoModal(modal)
      modal.render()
      _.defer done

    it "has a new password field", ->
      if modal.$('.new-password-input').length < 1
        fail "Expected there to be a new password input field"

    it "has a change password button", ->
      if modal.$('.change-password-btn').length < 1
        fail "Expected there to be a Change Password button"

    describe 'when you click the button', ->
      it 'sends a request', ->
        modal.$('.change-password-btn').click()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request).toBeDefined()

      xit 'updates the button', ->
        request1 = jasmine.Ajax.requests.mostRecent()
        fail "Expected a request to be sent" unless request1
        modal.$('.new-password-input').val(newPassword).change().trigger('input')
        modal.$('.change-password-btn').click()
        request2 = jasmine.Ajax.requests.mostRecent()
        expect(request1).not.toBe(request2)
        request1?.respondWith({ status: 200, responseText: JSON.stringify(user) })
        expect(modal.$('.change-password-btn [data-i18n]').data('i18n')).toEqual('teacher.changed')
