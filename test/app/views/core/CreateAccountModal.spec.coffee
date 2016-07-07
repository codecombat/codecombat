CreateAccountModal = require 'views/core/CreateAccountModal'
Classroom = require 'models/Classroom'
#COPPADenyModal = require 'views/core/COPPADenyModal'
forms = require 'core/forms'
factories = require 'test/app/factories'

# TODO: Figure out why these tests break Travis. Suspect it has to do with the
# asynchronous, Promise system. On the browser, these work, but in Travis, they
# sometimes fail, so it's some sort of race condition.

responses = {
  signupSuccess: { status: 200, responseText: JSON.stringify({ email: 'some@email.com' })}
}

xdescribe 'CreateAccountModal', ->
  
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
        expect(modal.signupState.get('path')).toBe('student')
        expect(modal.signupState.get('screen')).toBe('segment-check')
        
    describe 'click sign up as INDIVIDUAL button', ->
      beforeEach ->
        modal.$('.individual-path-button').click()

      it 'switches to SegmentCheckView and sets "path" to "individual"', ->
        expect(modal.signupState.get('path')).toBe('individual')
        expect(modal.signupState.get('screen')).toBe('segment-check')
        
  describe 'SegmentCheckView', ->
    
    segmentCheckView = null
    
    describe 'INDIVIDUAL path', ->
      beforeEach ->
        modal = new CreateAccountModal()
        modal.render()
        jasmine.demoModal(modal)
        modal.$('.individual-path-button').click()
        segmentCheckView = modal.subviews.segment_check_view

      it 'has a birthdate form', ->
        expect(modal.$('.birthday-form-group').length).toBe(1)
    
    describe 'STUDENT path', ->
      beforeEach ->
        modal = new CreateAccountModal()
        modal.render()
        jasmine.demoModal(modal)
        modal.$('.student-path-button').click()
        segmentCheckView = modal.subviews.segment_check_view
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
            expect(modal.signupState.get('screen')).toBe('basic-info')
            
        describe 'when the classroom IS NOT found', ->
          beforeEach (done) ->
            classCodeRequest.respondWith({
              status: 404
              responseText: '{}'
            })
            segmentCheckView.once 'special-render', done
            
          it 'shows an error', ->
            expect(modal.$('[data-i18n="signup.classroom_not_found"]').length).toBe(1)
            
  describe 'CoppaDenyView', ->
    
    coppaDenyView = null

    beforeEach ->
      modal = new CreateAccountModal()
      modal.signupState.set({
        path: 'individual'
        screen: 'coppa-deny'
      })
      modal.render()
      jasmine.demoModal(modal)
      coppaDenyView = modal.subviews.coppa_deny_view
      
    it 'shows an input for a parent\'s email address to sign up their child', ->
      expect(modal.$('#parent-email-input').length).toBe(1)
      

  describe 'BasicInfoView', ->

    basicInfoView = null

    beforeEach ->
      modal = new CreateAccountModal()
      modal.signupState.set({
        path: 'individual'
        screen: 'basic-info'
      })
      modal.render()
      jasmine.demoModal(modal)
      basicInfoView = modal.subviews.basic_info_view
      
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

      # does not work in travis since en.coffee is not included. TODO: Figure out workaround
#      describe 'if name DOES exist', ->
#        beforeEach (done) ->
#          jasmine.Ajax.requests.mostRecent().respondWith({
#            status: 200
#            responseText: JSON.stringify({conflicts: true, suggestedName: 'test123'})
#          })
#          _.defer done
#
#        it 'says name is taken and suggests a different one', ->
#          expect(basicInfoView.$el.text().indexOf('test123') > -1).toBe(true)

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
        modal.signupState.set('path', 'student')
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
              
            describe 'after signup STUDENT', ->
              beforeEach (done) ->
                basicInfoView.signupState.set({
                  path: 'student'
                  classCode: 'ABC'
                  classroom: new Classroom()
                })
                request = jasmine.Ajax.requests.mostRecent()
                request.respondWith(responses.signupSuccess)
                _.defer(done)
              
              it 'joins the classroom', ->
                request = jasmine.Ajax.requests.mostRecent()
                expect(request.url).toBe('/db/classroom/~/members')
              
            describe 'signing the user up SUCCEEDS', ->
              beforeEach (done) ->
                spyOn(basicInfoView, 'finishSignup')
                request = jasmine.Ajax.requests.mostRecent()
                request.respondWith(responses.signupSuccess)
                _.defer(done)
                
              it 'calls finishSignup()', ->
                expect(basicInfoView.finishSignup).toHaveBeenCalled()

  describe 'ConfirmationView', ->
    confirmationView = null
    
    beforeEach ->
      modal = new CreateAccountModal()
      modal.signupState.set('screen', 'confirmation')
      modal.render()
      jasmine.demoModal(modal)
      confirmationView = modal.subviews.confirmation_view
      
    it '(for demo testing)', ->
      me.set('name', 'A Sweet New Username')
      me.set('email', 'some@email.com')
      confirmationView.signupState.set('ssoUsed', 'gplus')

  describe 'SingleSignOnConfirmView', ->
    singleSignOnConfirmView = null

    beforeEach ->
      modal = new CreateAccountModal()
      modal.signupState.set({
        screen: 'sso-confirm'
        email: 'some@email.com'
      })
      modal.render()
      jasmine.demoModal(modal)
      singleSignOnConfirmView = modal.subviews.single_sign_on_confirm_view

    it '(for demo testing)', ->
      me.set('name', 'A Sweet New Username')
      me.set('email', 'some@email.com')
      singleSignOnConfirmView.signupState.set('ssoUsed', 'facebook')

  describe 'CoppaDenyView', ->
    coppaDenyView = null

    beforeEach ->
      modal = new CreateAccountModal()
      modal.signupState.set({
        screen: 'coppa-deny'
      })
      modal.render()
      jasmine.demoModal(modal)
      coppaDenyView = modal.subviews.coppa_deny_view

    it '(for demo testing)', ->
