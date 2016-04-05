RequestQuoteView = require 'views/teachers/RequestQuoteView'
storage = require 'core/storage'
forms = require 'core/forms'

describe 'RequestQuoteView', ->
  
  view = null
  
  successFormValues = {
    firstName: 'A'
    lastName: 'B'
    email: 'C@D.com'
    phoneNumber: '555-555-5555'
    role: 'Teacher'
    organization: 'School'
    city: 'Springfield'
    state: 'AA'
    country: 'asdf'
    numStudents: '1-10'
    educationLevel: ['Middle']
  }
  
  isSubmitRequest = (r) -> _.string.startsWith(r.url, '/db/trial.request') and r.method is 'POST'
    
  describe 'when user is anonymous and has an existing trial request', ->
    beforeEach (done) ->
      me.clear()
      me.set('_id', '1234')
      me._revertAttributes = {}
      spyOn(me, 'isAnonymous').and.returnValue(true)
      view = new RequestQuoteView()
      view.render()
      jasmine.demoEl(view.$el)

      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({
        status: 200
        responseText: JSON.stringify([{
          _id: '1'
          properties: {
            firstName: 'First'
            lastName: 'Last'
          }
        }])
      })
      _.defer done # Let SuperModel finish
  
    it 'shows request received', ->
      expect(view.$('#request-form').hasClass('hide')).toBe(true)
      expect(view.$('#form-submit-success').hasClass('hide')).toBe(false)
    
  
  describe 'when user is signed in and has an existing trial request', ->
    beforeEach (done) ->
      me.clear()
      me.set('_id', '1234')
      me._revertAttributes = {}
      spyOn(me, 'isAnonymous').and.returnValue(false)
      view = new RequestQuoteView()
      view.render()
      jasmine.demoEl(view.$el)
  
      spyOn(storage, 'load').and.returnValue({ lastName: 'Saved Changes' })
  
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({
        status: 200
        responseText: JSON.stringify([{
          _id: '1'
          properties: {
            firstName: 'First'
            lastName: 'Last'
          }
        }])
      })
      _.defer done # Let SuperModel finish

    it 'shows form with data from the most recent request', ->
      expect(view.$('input[name="firstName"]').val()).toBe('First')
    
    it 'prioritizes showing local, unsaved changes', ->
      expect(view.$('input[name="lastName"]').val()).toBe('Saved Changes')
      
    describe 'when the form changes', ->
      
      it 'stores local, unsaved changes', ->
        spyOn(storage, 'save')
        view.$('input[name="firstName"]').val('Just Changed').change()
        expect(storage.save).toHaveBeenCalled()
        args = storage.save.calls.argsFor(0)
        expect(args[1].firstName).toBe('Just Changed')
      
  describe 'when a user is anonymous and does NOT have an existing trial request', ->
    beforeEach (done) ->
      me.clear()
      me.set('_id', '1234')
      me._revertAttributes = {}
      spyOn(me, 'isAnonymous').and.returnValue(true)
      view = new RequestQuoteView()
      view.render()
      jasmine.demoEl(view.$el)

      spyOn(storage, 'load').and.returnValue({ lastName: 'Saved Changes' })

      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({
        status: 200
        responseText: '[]'
      })
      _.defer done # Let SuperModel finish

    describe 'on successful form submit', ->
      beforeEach ->
        forms.objectToForm(view.$el, successFormValues)
        view.$('#request-form').submit()
        @submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest))
        @submitRequest.respondWith({
          status: 201
          responseText: JSON.stringify(_.extend({_id: 'a'}, successFormValues))
        })

      it 'creates a new trial request', ->
        expect(@submitRequest).toBeTruthy()
        expect(@submitRequest.method).toBe('POST')

      it 'sets the user\'s role to the one they chose', ->
        request = _.last(jasmine.Ajax.requests.filter((r) -> _.string.startsWith(r.url, '/db/user')))
        expect(request).toBeTruthy()
        expect(request.method).toBe('PUT')
        expect(JSON.parse(request.params).role).toBe('teacher')
      
      it 'shows a signup form', ->
        expect(view.$('#form-submit-success').hasClass('hide')).toBe(false)
        expect(view.$('#request-form').hasClass('hide')).toBe(true)
        
      describe 'signup form', ->
        beforeEach ->
          application.facebookHandler.fakeAPI()
          application.gplusHandler.fakeAPI()
          
        it 'fills the username field with the given first and last names', ->
          expect(view.$('input[name="name"]').val()).toBe('A B')
        
        it 'includes a facebook button which will sign them in immediately', ->
          view.$('#facebook-signup-btn').click()
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234')
          
        it 'includes a gplus button which will sign them in immediately', ->
          view.$('#gplus-signup-btn').click()
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234')
          
        it 'can sign them up with username and password', ->
          form = view.$('#signup-form')
          forms.objectToForm(form, {
            password1: 'asdf'
            password2: 'asdf'
            name: 'some name'
          })
          form.submit()
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(request.url).toBe('/db/user/1234')
      
    describe 'when an anonymous user tries to submit a request with an existing user\'s email', ->
  
      beforeEach ->
        forms.objectToForm(view.$el, successFormValues)
        view.$('#request-form').submit()
        @submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest))
        @submitRequest.respondWith({
          status: 409
          responseText: '{}'
        })
  
      it 'shows an error that the email already exists', ->
        expect(view.$('#email-form-group').hasClass('has-error')).toBe(true)
        expect(view.$('#email-form-group .error-help-block').length).toBe(1)
      
  describe 'when user is signed in and has role "student"', ->
    beforeEach (done) ->
      me.set('role', 'student')
      me.set('name', 'Some User')
      spyOn(me, 'isAnonymous').and.returnValue(false)
      view = new RequestQuoteView()
      view.render()
      jasmine.demoEl(view.$el)

      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({ status: 200, responseText: '[]'})
      _.defer done # Let SuperModel finish
    
    it 'shows a conversion warning', ->
      expect(view.$('#conversion-warning').length).toBe(1)
      
    it 'requires confirmation to submit the form', ->
      form = view.$('#request-form')
      forms.objectToForm(form, successFormValues)
      spyOn(view, 'openModalView')
      form.submit()
      expect(view.openModalView).toHaveBeenCalled()
      
      submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest))
      expect(submitRequest).toBeFalsy()
      confirmModal = view.openModalView.calls.argsFor(0)[0]
      confirmModal.trigger 'confirm'
      submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest))
      expect(submitRequest).toBeTruthy()
      
      