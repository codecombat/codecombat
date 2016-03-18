CreateAccountModal = require 'views/core/CreateAccountModal'
forms = require 'core/forms'

describe 'CreateAccountModal', ->
  
  modal = null
  
  initModal = (options) ->
    application.facebookHandler.fakeAPI()
    application.gplusHandler.fakeAPI()
    modal = new CreateAccountModal(options)
    modal.render()
    modal.render = _.noop
    jasmine.demoModal(modal)
  
  afterEach ->
    modal.stopListening()
    
  describe 'constructed with showRequiredError is true', ->
    it 'shows a modal explaining to login first', ->
      initModal({showRequiredError: true})
      expect(modal.$('#required-error-alert').length).toBe(1)

  describe 'constructed with showSignupRationale is true', ->
    it 'shows a modal explaining signup rationale', ->
      initModal({showSignupRationale: true})
      expect(modal.$('#signup-rationale-alert').length).toBe(1)

  describe 'clicking the save button', ->

    beforeEach ->
      initModal()

    it 'fails if nothing is in the form, showing errors for email and password', ->
      modal.$('form').each (i, el) -> el.reset()
      modal.$('form').submit()
      expect(jasmine.Ajax.requests.all().length).toBe(0)
      expect(modal.$('.has-error').length).toBe(2)
    
    it 'fails if email is missing', ->
      modal.$('form').each (i, el) -> el.reset()
      forms.objectToForm(modal.$el, { name: 'Name', password: 'xyzzy' })
      modal.$('form').submit()
      expect(jasmine.Ajax.requests.all().length).toBe(0)
      expect(modal.$('.has-error').length).toBeTruthy()

    it 'signs up if only email and password is provided', ->
      modal.$('form').each (i, el) -> el.reset()
      forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy' })
      modal.$('form').submit()
      requests = jasmine.Ajax.requests.all()
      expect(requests.length).toBe(1)
      expect(modal.$el.has('.has-warning').length).toBeFalsy()
      expect(modal.$('#signup-button').is(':disabled')).toBe(true)
      
    describe 'and a class code is entered', ->
      
      beforeEach ->
        modal.$('form').each (i, el) -> el.reset()
        forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy', classCode: 'qwerty' })
        modal.$('form').submit()
        expect(jasmine.Ajax.requests.all().length).toBe(1)

      it 'checks for Classroom existence if a class code was entered', ->
        jasmine.demoModal(modal)
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).toBe('/db/classroom?code=qwerty')
        
      it 'has not hidden the close-modal button', ->
        expect(modal.$('#close-modal').css('display')).not.toBe('none')
        
      describe 'the Classroom exists', ->
        it 'continues with signup', ->
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({status: 200, responseText: JSON.stringify({})})
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.url).toBe('/db/user')
          expect(request.method).toBe('POST')
        
      describe 'the Classroom does not exist', ->
        it 'shows an error and clears the field', ->
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({status: 404, responseText: JSON.stringify({})})
          expect(jasmine.Ajax.requests.all().length).toBe(1)
          expect(modal.$el.has('.has-error').length).toBeTruthy()
          expect(modal.$('#class-code-input').val()).toBe('')
        
      
  describe 'clicking the gplus button', ->
    
    signupButton = null

    beforeEach ->
      initModal()
      signupButton = modal.$('#gplus-signup-btn')
      expect(signupButton.attr('disabled')).toBeFalsy()
      signupButton.click()
    
    it 'checks to see if the user already exists in our system', ->
      requests = jasmine.Ajax.requests.all()
      expect(requests.length).toBe(1)
      expect(signupButton.attr('disabled')).toBeTruthy()


    describe 'and finding the given person is already a user', ->
      beforeEach ->
        expect(modal.$('#gplus-account-exists-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 200, responseText: JSON.stringify({_id: 'existinguser'})})

      it 'shows a message saying you are connected with Google+, with a button for logging in', ->
        expect(modal.$('#gplus-account-exists-row').hasClass('hide')).toBe(false)
        loginBtn = modal.$('#gplus-login-btn')
        expect(loginBtn.attr('disabled')).toBeFalsy()
        loginBtn.click()
        expect(loginBtn.attr('disabled')).toBeTruthy()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.method).toBe('POST')
        expect(request.params).toBe('gplusID=abcd&gplusAccessToken=1234')
        expect(request.url).toBe('/auth/login-gplus')
        
      describe 'and the user finishes signup anyway with new info', ->
        beforeEach ->
          forms.objectToForm(modal.$el, { email: 'some@email.com', schoolName: 'Hogwarts' })
          modal.$('form').submit()
          
        it 'upserts the values to the new user', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234')
          expect(JSON.parse(request.params).schoolName).toBe('Hogwarts')
          

    describe 'and finding the given person is not yet a user', ->
      beforeEach ->
        expect(modal.$('#gplus-logged-in-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 404})
        
      it 'shows a message saying you are connected with Google+', ->
        expect(modal.$('#gplus-logged-in-row').hasClass('hide')).toBe(false)
        
      describe 'and the user finishes signup', ->
        beforeEach ->
          modal.$('form').submit()

        it 'creates the user with the gplus attributes', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234')
          expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
          expect(modal.$('#signup-button').is(':disabled')).toBe(true)
          
        
  describe 'clicking the facebook button', ->

    signupButton = null

    beforeEach ->
      initModal()
      signupButton = modal.$('#facebook-signup-btn')
      expect(signupButton.attr('disabled')).toBeFalsy()
      signupButton.click()

    it 'checks to see if the user already exists in our system', ->
      requests = jasmine.Ajax.requests.all()
      expect(requests.length).toBe(1)
      expect(signupButton.attr('disabled')).toBeTruthy()


    describe 'and finding the given person is already a user', ->
      beforeEach ->
        expect(modal.$('#facebook-account-exists-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 200, responseText: JSON.stringify({_id: 'existinguser'})})

      it 'shows a message saying you are connected with Facebook, with a button for logging in', ->
        expect(modal.$('#facebook-account-exists-row').hasClass('hide')).toBe(false)
        loginBtn = modal.$('#facebook-login-btn')
        expect(loginBtn.attr('disabled')).toBeFalsy()
        loginBtn.click()
        expect(loginBtn.attr('disabled')).toBeTruthy()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.method).toBe('POST')
        expect(request.params).toBe('facebookID=abcd&facebookAccessToken=1234')
        expect(request.url).toBe('/auth/login-facebook')

      describe 'and the user finishes signup anyway with new info', ->
        beforeEach ->
          forms.objectToForm(modal.$el, { email: 'some@email.com', schoolName: 'Hogwarts' })
          modal.$('form').submit()

        it 'upserts the values to the new user', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234')
          expect(JSON.parse(request.params).schoolName).toBe('Hogwarts')


    describe 'and finding the given person is not yet a user', ->
      beforeEach ->
        expect(modal.$('#facebook-logged-in-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 404})

      it 'shows a message saying you are connected with Facebook', ->
        expect(modal.$('#facebook-logged-in-row').hasClass('hide')).toBe(false)

      describe 'and the user finishes signup', ->
        beforeEach ->
          modal.$('form').submit()

        it 'creates the user with the facebook attributes', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
          expect(modal.$('#signup-button').is(':disabled')).toBe(true)
          expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234')