CreateAccountModal = require 'views/core/CreateAccountModal'
#COPPADenyModal = require 'views/core/COPPADenyModal'
forms = require 'core/forms'
factories = require 'test/app/factories'

describe 'CreateAccountModal', ->
  
  modal = null
  
#  initModal = (options) -> ->
#    application.facebookHandler.fakeAPI()
#    application.gplusHandler.fakeAPI()
#    modal = new CreateAccountModal(options)
#    jasmine.demoModal(modal)

  describe 'click SIGN IN button', ->
    it 'switches to AuthModal', ->
      modal = new CreateAccountModal()
      modal.render()
      jasmine.demoModal(modal)
      spyOn(modal, 'openModalView')
      modal.$('.login-link').click()
      expect(modal.openModalView).toHaveBeenCalled()

  describe 'ChooseAccountTypeView', ->
    beforeEach ->
      modal = new CreateAccountModal()
      modal.render()
      jasmine.demoModal(modal)
    
    describe 'click sign up as TEACHER button', ->
      beforeEach ->
        spyOn application.router, 'navigate'
        modal.$('.teacher-path-button').click()
        
      it 'navigates the user to /teachers/signup', ->
        expect(application.router.navigate).toHaveBeenCalled()
        args = application.router.navigate.calls.argsFor(0)
        expect(args[0]).toBe('/teachers/signup')
        
    describe 'click sign up as STUDENT button', ->
      beforeEach ->
        modal.$('.student-path-button').click()

      it 'switches to SegmentCheckView and sets "path" to "student"', ->
        expect(modal.state.get('path')).toBe('student')
        expect(modal.state.get('screen')).toBe('segment-check')
        
    describe 'click sign up as INDIVIDUAL button', ->
      beforeEach ->
        modal.$('.individual-path-button').click()

      it 'switches to SegmentCheckView and sets "path" to "individual"', ->
        expect(modal.state.get('path')).toBe('individual')
        expect(modal.state.get('screen')).toBe('segment-check')
        
  describe 'SegmentCheckView', ->
    
    segmentCheckView = null
    
    describe 'STUDENT path', ->
      beforeEach ->
        modal = new CreateAccountModal()
        modal.render()
        jasmine.demoModal(modal)
        modal.$('.student-path-button').click()
        segmentCheckView = modal.customSubviews.segment_check
        spyOn(segmentCheckView, 'checkClassCodeDebounced')
        
      it 'has a classCode input', ->
        expect(modal.$('.class-code-input').length).toBe(1)
        
      it 'checks the class code when the input changes', ->
        modal.$('.class-code-input').val('test').trigger('input')
        expect(segmentCheckView.checkClassCodeDebounced).toHaveBeenCalled()
        
      describe 'fetchClassByCode()', ->
        it 'is memoized', ->
          promise1 = segmentCheckView.fetchClassByCode('testA')
          promise2 = segmentCheckView.fetchClassByCode('testA')
          promise3 = segmentCheckView.fetchClassByCode('testB')
          expect(promise1).toBe(promise2)
          expect(promise1).not.toBe(promise3)
          
      describe 'checkClassCode()', ->
        it 'shows a success message if the classCode is found', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request).toBeUndefined()
          modal.$('.class-code-input').val('test').trigger('input')
          segmentCheckView.checkClassCode()
          request = jasmine.Ajax.requests.mostRecent()
          expect(request).toBeDefined()
          request.respondWith({
            status: 200
            responseText: JSON.stringify({
              data: factories.makeClassroom({name: 'Some Classroom'}).toJSON()
              owner: factories.makeUser({name: 'Some Teacher'}).toJSON()
            })
          })
        
      describe 'on submit with class code', ->
        
        classCodeRequest = null
        
        beforeEach ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request).toBeUndefined()
          modal.$('.class-code-input').val('test').trigger('input')
          modal.$('form.segment-check').submit()
          classCodeRequest = jasmine.Ajax.requests.mostRecent()
          expect(classCodeRequest).toBeDefined()

        describe 'when the classroom IS found', ->
          beforeEach (done) ->
            classCodeRequest.respondWith({
              status: 200
              responseText: JSON.stringify({
                data: factories.makeClassroom({name: 'Some Classroom'}).toJSON()
                owner: factories.makeUser({name: 'Some Teacher'}).toJSON()
              })
            })
            _.defer done

          it 'navigates to the BasicInfoView', ->
            expect(modal.state.get('screen')).toBe('basic-info')
            
        describe 'when the classroom IS NOT found', ->
          beforeEach (done) ->
            classCodeRequest.respondWith({
              status: 404
              responseText: '{}'
            })
            segmentCheckView.once 'special-render', done
            
          it 'shows an error', ->
            expect(modal.$('[data-i18n="signup.classroom_not_found"]').length).toBe(1)


  describe 'BasicInfoView', ->

    basicInfoView = null

    beforeEach ->
      modal = new CreateAccountModal()
      modal.state.set({
        path: 'individual'
        screen: 'basic-info'
      })
      modal.render()
      jasmine.demoModal(modal)
      basicInfoView = modal.customSubviews.basic_info_view
      
    it 'checks for name conflicts when the name input changes', ->
      spyOn(basicInfoView, 'checkName')
      basicInfoView.$('#username-input').val('test').trigger('change')
      expect(basicInfoView.checkName).toHaveBeenCalled()
      
    describe 'checkEmail()', ->
      beforeEach ->
        basicInfoView.$('input[name="email"]').val('some@email.com')
        basicInfoView.checkEmail()
        
      it 'shows checking', ->
        expect(basicInfoView.$('[data-i18n="signup.checking"]').length).toBe(1)
        
      describe 'if email DOES exist', ->
        beforeEach (done) ->
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200
            responseText: JSON.stringify({exists: true})
          })
          _.defer done
        
        it 'says an account already exists and encourages to sign in', ->
          expect(basicInfoView.$('[data-i18n="signup.account_exists"]').length).toBe(1)
          expect(basicInfoView.$('.login-link[data-i18n="signup.sign_in"]').length).toBe(1)
          
      describe 'if email DOES NOT exist', ->
        beforeEach (done) ->
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200
            responseText: JSON.stringify({exists: false})
          })
          _.defer done

        it 'says email looks good', ->
          expect(basicInfoView.$('[data-i18n="signup.email_good"]').length).toBe(1)
      
    describe 'checkName()', ->
      beforeEach ->
        basicInfoView.$('input[name="name"]').val('Some Name').trigger('change')
        basicInfoView.checkName()

      it 'shows checking', ->
        expect(basicInfoView.$('[data-i18n="signup.checking"]').length).toBe(1)

      describe 'if name DOES exist', ->
        beforeEach (done) ->
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200
            responseText: JSON.stringify({conflicts: true, suggestedName: 'test123'})
          })
          _.defer done

        it 'says name is taken and suggests a different one', ->
          expect(basicInfoView.$el.text().indexOf('Try test123?') > -1).toBe(true)

      describe 'if email DOES NOT exist', ->
        beforeEach (done) ->
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200
            responseText: JSON.stringify({conflicts: false})
          })
          _.defer done

        it 'says name looks good', ->
          expect(basicInfoView.$('[data-i18n="signup.name_available"]').length).toBe(1)
          
    describe 'onSubmitForm()', ->
      it 'shows required errors for empty fields when on INDIVIDUAL path', ->
        basicInfoView.$('input').val('')
        basicInfoView.$('#basic-info-form').submit()
        expect(basicInfoView.$('.form-group.has-error').length).toBe(3)

      it 'shows required errors for empty fields when on STUDENT path', ->
        modal.state.set('path', 'student')
        modal.render()
        basicInfoView.$('#basic-info-form').submit()
        expect(basicInfoView.$('.form-group.has-error').length).toBe(5) # includes first and last name

      describe 'submit with password', ->
        beforeEach ->
          forms.objectToForm(basicInfoView.$el, {
            email: 'some@email.com'
            password: 'password'
            name: 'A Username'
          })
          basicInfoView.$('form').submit()
          
        it 'checks for email and name conflicts', ->
          emailCheck = _.find(jasmine.Ajax.requests.all(), (r) -> _.string.startsWith(r.url, '/auth/email'))
          nameCheck = _.find(jasmine.Ajax.requests.all(), (r) -> _.string.startsWith(r.url, '/auth/name'))
          expect(_.all([emailCheck, nameCheck])).toBe(true)
          
        describe 'a check does not pass', ->
          beforeEach (done) ->
            nameCheck = _.find(jasmine.Ajax.requests.all(), (r) -> _.string.startsWith(r.url, '/auth/name'))
            nameCheck.respondWith({
              status: 200
              responseText: JSON.stringify({conflicts: false})
            })
            emailCheck = _.find(jasmine.Ajax.requests.all(), (r) -> _.string.startsWith(r.url, '/auth/email'))
            emailCheck.respondWith({
              status: 200
              responseText: JSON.stringify({ exists: true })
            })
            _.defer done
            
          it 're-enables the form and shows which field failed', ->
             
        describe 'both checks do pass', ->
          beforeEach (done) ->
            nameCheck = _.find(jasmine.Ajax.requests.all(), (r) -> _.string.startsWith(r.url, '/auth/name'))
            nameCheck.respondWith({
              status: 200
              responseText: JSON.stringify({conflicts: false})
            })
            emailCheck = _.find(jasmine.Ajax.requests.all(), (r) -> _.string.startsWith(r.url, '/auth/email'))
            emailCheck.respondWith({
              status: 200
              responseText: JSON.stringify({ exists: false })
            })
            _.defer done
            
          it 'saves the user', ->
            request = jasmine.Ajax.requests.mostRecent()
            expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
            
          describe 'saving the user FAILS', ->
            beforeEach (done) ->
              request = jasmine.Ajax.requests.mostRecent()
              request.respondWith({
                status: 422
                responseText: JSON.stringify({
                  message: 'Some error happened'
                })
              })
              _.defer(done)
              
            it 'displays the server error', ->
              expect(basicInfoView.$('.alert-danger').length).toBe(1)
              
          describe 'saving the user SUCCEEDS', ->
            beforeEach (done) ->
              request = jasmine.Ajax.requests.mostRecent()
              request.respondWith({
                status: 200
                responseText: '{}'
              })
              _.defer(done)
              
            it 'signs the user up with the password', ->
              request = jasmine.Ajax.requests.mostRecent()
              expect(_.string.endsWith(request.url, 'signup-with-password')).toBe(true)
              
            describe 'signing the user up SUCCEEDS', ->
              beforeEach (done) ->
                spyOn(basicInfoView, 'finishSignup')
                request = jasmine.Ajax.requests.mostRecent()
                request.respondWith({
                  status: 200
                  responseText: '{}'
                })
                _.defer(done)
                
              it 'calls finishSignup()', ->
                expect(basicInfoView.finishSignup).toHaveBeenCalled()


#  describe 'constructed with showRequiredError is true', ->
#    beforeEach initModal({showRequiredError: true})
#    it 'shows a modal explaining to login first', ->
#      expect(modal.$('#required-error-alert').length).toBe(1)
#
#  describe 'constructed with showSignupRationale is true', ->
#    beforeEach initModal({showSignupRationale: true})
#    it 'shows a modal explaining signup rationale', ->
#      expect(modal.$('#signup-rationale-alert').length).toBe(1)
#
#  describe 'clicking the save button', ->
#
#    beforeEach initModal()
#
#    it 'fails if nothing is in the form, showing errors for email, birthday, and password', ->
#      modal.$('form').each (i, el) -> el.reset()
#      modal.$('form').submit()
#      expect(jasmine.Ajax.requests.all().length).toBe(0)
#      expect(modal.$('.has-error').length).toBe(3)
#    
#    it 'fails if email is missing', ->
#      modal.$('form').each (i, el) -> el.reset()
#      forms.objectToForm(modal.$el, { name: 'Name', password: 'xyzzy', birthdayDay: 24, birthdayMonth: 7, birthdayYear: 1988 })
#      modal.$('form').submit()
#      expect(jasmine.Ajax.requests.all().length).toBe(0)
#      expect(modal.$('.has-error').length).toBeTruthy()
#
#    it 'fails if birthday is missing', ->
#      modal.$('form').each (i, el) -> el.reset()
#      forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy' })
#      modal.$('form').submit()
#      expect(jasmine.Ajax.requests.all().length).toBe(0)
#      expect(modal.$('.has-error').length).toBe(1)
#
#    it 'fails if user is too young', ->
#      modal.$('form').each (i, el) -> el.reset()
#      forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy', birthdayDay: 24, birthdayMonth: 7, birthdayYear: (new Date().getFullYear() - 10) })
#      modalOpened = false
#      spyOn(modal, 'openModalView').and.callFake (modal) -> 
#        modalOpened = true
#        expect(modal instanceof COPPADenyModal).toBe(true)
#
#      modal.$('form').submit()
#      expect(jasmine.Ajax.requests.all().length).toBe(0)
#      expect(modalOpened).toBeTruthy()
#
#    it 'signs up if only email, birthday, and password is provided', ->
#      modal.$('form').each (i, el) -> el.reset()
#      forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy', birthdayDay: 24, birthdayMonth: 7, birthdayYear: 1988 })
#      modal.$('form').submit()
#      requests = jasmine.Ajax.requests.all()
#      expect(requests.length).toBe(1)
#      expect(modal.$el.has('.has-warning').length).toBeFalsy()
#      expect(modal.$('#signup-button').is(':disabled')).toBe(true)
#      
#    describe 'and a class code is entered', ->
#      
#      beforeEach ->
#        modal.$('form').each (i, el) -> el.reset()
#        forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy', classCode: 'qwerty' })
#        modal.$('form').submit()
#        expect(jasmine.Ajax.requests.all().length).toBe(1)
#
#      it 'checks for Classroom existence if a class code was entered', ->
#        jasmine.demoModal(modal)
#        request = jasmine.Ajax.requests.mostRecent()
#        expect(request.url).toBe('/db/classroom?code=qwerty')
#        
#      it 'has not hidden the close-modal button', ->
#        expect(modal.$('#close-modal').css('display')).not.toBe('none')
#        
#      describe 'the Classroom exists', ->
#        it 'continues with signup', ->
#          request = jasmine.Ajax.requests.mostRecent()
#          request.respondWith({status: 200, responseText: JSON.stringify({})})
#          request = jasmine.Ajax.requests.mostRecent()
#          expect(request.url).toBe('/db/user')
#          expect(request.method).toBe('POST')
#        
#      describe 'the Classroom does not exist', ->
#        it 'shows an error and clears the field', ->
#          request = jasmine.Ajax.requests.mostRecent()
#          request.respondWith({status: 404, responseText: JSON.stringify({})})
#          expect(jasmine.Ajax.requests.all().length).toBe(1)
#          expect(modal.$el.has('.has-error').length).toBeTruthy()
#          expect(modal.$('#class-code-input').val()).toBe('')
#        
#      
#  describe 'clicking the gplus button', ->
#    
#    signupButton = null
#
#    beforeEach initModal()
# 
#    beforeEach ->
#      forms.objectToForm(modal.$el, { birthdayDay: 24, birthdayMonth: 7, birthdayYear: 1988 })
#      signupButton = modal.$('#gplus-signup-btn')
#      expect(signupButton.attr('disabled')).toBeFalsy()
#      signupButton.click()
#    
#    it 'checks to see if the user already exists in our system', ->
#      requests = jasmine.Ajax.requests.all()
#      expect(requests.length).toBe(1)
#      expect(signupButton.attr('disabled')).toBeTruthy()
#
#
#    describe 'and finding the given person is already a user', ->
#      beforeEach ->
#        expect(modal.$('#gplus-account-exists-row').hasClass('hide')).toBe(true)
#        request = jasmine.Ajax.requests.mostRecent()
#        request.respondWith({status: 200, responseText: JSON.stringify({_id: 'existinguser'})})
#
#      it 'shows a message saying you are connected with Google+, with a button for logging in', ->
#        expect(modal.$('#gplus-account-exists-row').hasClass('hide')).toBe(false)
#        loginBtn = modal.$('#gplus-login-btn')
#        expect(loginBtn.attr('disabled')).toBeFalsy()
#        loginBtn.click()
#        expect(loginBtn.attr('disabled')).toBeTruthy()
#        request = jasmine.Ajax.requests.mostRecent()
#        expect(request.method).toBe('POST')
#        expect(request.params).toBe('gplusID=abcd&gplusAccessToken=1234')
#        expect(request.url).toBe('/auth/login-gplus')
#        
#      describe 'and the user finishes signup anyway with new info', ->
#        beforeEach ->
#          forms.objectToForm(modal.$el, { email: 'some@email.com', birthdayDay: 24, birthdayMonth: 7, birthdayYear: 1988 })
#          modal.$('form').submit()
#          
#        it 'upserts the values to the new user', ->
#          request = jasmine.Ajax.requests.mostRecent()
#          expect(request.method).toBe('PUT')
#          expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234')
#          
#
#    describe 'and finding the given person is not yet a user', ->
#      beforeEach ->
#        expect(modal.$('#gplus-logged-in-row').hasClass('hide')).toBe(true)
#        request = jasmine.Ajax.requests.mostRecent()
#        request.respondWith({status: 404})
#        
#      it 'shows a message saying you are connected with Google+', ->
#        expect(modal.$('#gplus-logged-in-row').hasClass('hide')).toBe(false)
#        
#      describe 'and the user finishes signup', ->
#        beforeEach ->
#          modal.$('form').submit()
#
#        it 'creates the user with the gplus attributes', ->
#          request = jasmine.Ajax.requests.mostRecent()
#          expect(request.method).toBe('PUT')
#          expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234')
#          expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
#          expect(modal.$('#signup-button').is(':disabled')).toBe(true)
#          
#        
#  describe 'clicking the facebook button', ->
#
#    signupButton = null
#
#    beforeEach initModal()
#    
#    beforeEach ->
#      forms.objectToForm(modal.$el, { birthdayDay: 24, birthdayMonth: 7, birthdayYear: 1988 })
#      signupButton = modal.$('#facebook-signup-btn')
#      expect(signupButton.attr('disabled')).toBeFalsy()
#      signupButton.click()
#
#    it 'checks to see if the user already exists in our system', ->
#      requests = jasmine.Ajax.requests.all()
#      expect(requests.length).toBe(1)
#      expect(signupButton.attr('disabled')).toBeTruthy()
#
#
#    describe 'and finding the given person is already a user', ->
#      beforeEach ->
#        expect(modal.$('#facebook-account-exists-row').hasClass('hide')).toBe(true)
#        request = jasmine.Ajax.requests.mostRecent()
#        request.respondWith({status: 200, responseText: JSON.stringify({_id: 'existinguser'})})
#
#      it 'shows a message saying you are connected with Facebook, with a button for logging in', ->
#        expect(modal.$('#facebook-account-exists-row').hasClass('hide')).toBe(false)
#        loginBtn = modal.$('#facebook-login-btn')
#        expect(loginBtn.attr('disabled')).toBeFalsy()
#        loginBtn.click()
#        expect(loginBtn.attr('disabled')).toBeTruthy()
#        request = jasmine.Ajax.requests.mostRecent()
#        expect(request.method).toBe('POST')
#        expect(request.params).toBe('facebookID=abcd&facebookAccessToken=1234')
#        expect(request.url).toBe('/auth/login-facebook')
#
#      describe 'and the user finishes signup anyway with new info', ->
#        beforeEach ->
#          forms.objectToForm(modal.$el, { email: 'some@email.com', birthdayDay: 24, birthdayMonth: 7, birthdayYear: 1988 })
#          modal.$('form').submit()
#
#        it 'upserts the values to the new user', ->
#          request = jasmine.Ajax.requests.mostRecent()
#          expect(request.method).toBe('PUT')
#          expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234')
#
#
#    describe 'and finding the given person is not yet a user', ->
#      beforeEach ->
#        expect(modal.$('#facebook-logged-in-row').hasClass('hide')).toBe(true)
#        request = jasmine.Ajax.requests.mostRecent()
#        request.respondWith({status: 404})
#
#      it 'shows a message saying you are connected with Facebook', ->
#        expect(modal.$('#facebook-logged-in-row').hasClass('hide')).toBe(false)
#
#      describe 'and the user finishes signup', ->
#        beforeEach ->
#          modal.$('form').submit()
#
#        it 'creates the user with the facebook attributes', ->
#          request = jasmine.Ajax.requests.mostRecent()
#          expect(request.method).toBe('PUT')
#          expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
#          expect(modal.$('#signup-button').is(':disabled')).toBe(true)
#          expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234')
