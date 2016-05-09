ConvertToTeacherAccountView = require 'views/teachers/ConvertToTeacherAccountView'
storage = require 'core/storage'
forms = require 'core/forms'

describe '/teachers/update-account', ->
  describe 'when logged out', ->
    it 'redirects to /teachers/signup', ->
      spyOn(me, 'isAnonymous').and.returnValue(true)
      spyOn(application.router, 'navigate')
      Backbone.history.loadUrl('/teachers/update-account')
      expect(application.router.navigate.calls.count()).toBe(1)
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/teachers/signup')

  describe 'when logged in', ->
    it 'displays ConvertToTeacherAccountView', ->
      spyOn(me, 'isAnonymous').and.returnValue(false)
      spyOn(me, 'isTeacher').and.returnValue(false)
      spyOn(application.router, 'routeDirectly')
      Backbone.history.loadUrl('/teachers/update-account')
      expect(application.router.routeDirectly.calls.count()).toBe(1)
      args = application.router.routeDirectly.calls.argsFor(0)
      expect(args[0]).toBe('teachers/ConvertToTeacherAccountView')


describe 'ConvertToTeacherAccountView (/teachers/update-account)', ->

  view = null

  successForm = {
    phoneNumber: '555-555-5555'
    role: 'Teacher'
    organization: 'School'
    city: 'Springfield'
    state: 'AA'
    country: 'asdf'
    numStudents: '1-10'
    educationLevel: ['Middle']
    firstName: 'Mr'
    lastName: 'Bean'
  }

  beforeEach ->
    spyOn(application.router, 'navigate')
    me.clear()
    me.set({
      _id: '1234'
      anonymous: false
      email: 'some@email.com'
      name: 'Existing User'
    })
    me._revertAttributes = {}
    view = new ConvertToTeacherAccountView()
    view.render()
    jasmine.demoEl(view.$el)

    spyOn(storage, 'load').and.returnValue({ lastName: 'Saved Changes' })
    
  afterEach (done) ->
    _.defer(done) # let everything finish loading, keep navigate spied on

  describe 'when the form is unchanged', ->
    it 'does not prevent navigating away', ->
      expect(_.result(view, 'onLeaveMessage')).toBeFalsy()

  describe 'when the form has changed but is not submitted', ->
    beforeEach ->
      view.$el.find('form').trigger('change')

    it 'prevents navigating away', ->
      expect(_.result(view, 'onLeaveMessage')).toBeTruthy()


  describe 'when the user already has a TrialRequest and is a teacher', ->
    beforeEach (done) ->
      spyOn(me, 'isTeacher').and.returnValue(true)
      _.last(view.trialRequests.fakeRequests).respondWith({
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

    # TODO: re-enable when student and teacher areas are enforced
    xit 'redirects to /teachers/courses', ->
      expect(application.router.navigate).toHaveBeenCalled()
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/teachers/courses')


  describe 'when the user has role "student"', ->
    beforeEach ->
      me.set('role', 'student')
      _.last(view.trialRequests.fakeRequests).respondWith({ status: 200, responseText: JSON.stringify('[]') })
      view.render()

    it 'shows a warning that they will convert to a teacher account', ->
      expect(view.$('#conversion-warning').length).toBe(1)

#      TODO: Figure out how to test this
#    describe 'the warning', ->
#      it 'includes a learn more link which opens a modal with more info'

    describe 'submitting the form', ->
      beforeEach ->
        form = view.$('form')
        forms.objectToForm(form, successForm, {overwriteExisting: true})
        spyOn(view, 'openModalView')
        form.submit()

      it 'requires confirmation', ->
        expect(view.trialRequest.fakeRequests.length).toBe(0)
        confirmModal = view.openModalView.calls.argsFor(0)[0]
        confirmModal.trigger 'confirm'
        request = _.last(view.trialRequest.fakeRequests)
        expect(request.url).toBe('/db/trial.request')
        expect(request.method).toBe('POST')

  describe '"Log out" link', ->
    beforeEach ->
      _.last(view.trialRequests.fakeRequests).respondWith({ status: 200, responseText: JSON.stringify('[]') })

    it 'logs out the user and redirects them to /teachers/signup', ->
      spyOn(me, 'logout')
      view.$('#logout-link').click()
      expect(me.logout).toHaveBeenCalled()

  describe 'submitting the form', ->
    beforeEach ->
      view.$el.find('#request-form').trigger('change') # to confirm navigating away isn't prevented
      _.last(view.trialRequests.fakeRequests).respondWith({ status: 200, responseText: JSON.stringify('[]') })
      form = view.$('form')
      forms.objectToForm(form, successForm, {overwriteExisting: true})
      form.submit()

    it 'does not prevent navigating away', ->
      expect(_.result(view, 'onLeaveMessage')).toBeFalsy()

    it 'creates a new TrialRequest with the information', ->
      request = _.last(view.trialRequest.fakeRequests)
      expect(request).toBeTruthy()
      expect(request.method).toBe('POST')
      attrs = JSON.parse(request.params)
      expect(attrs.properties?.firstName).toBe('Mr')
      expect(attrs.properties?.siteOrigin).toBe('convert teacher')
      expect(attrs.properties?.email).toBe('some@email.com')

    it 'redirects to /teachers/classes', ->
      request = _.last(view.trialRequest.fakeRequests)
      request.respondWith({
        status: 201
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      })
      expect(application.router.navigate).toHaveBeenCalled()
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/teachers/classes')

     it 'sets a teacher role', ->
      request = _.last(view.trialRequest.fakeRequests)
      request.respondWith({
        status: 201
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      })
      expect(me.get('role')).toBe(successForm.role.toLowerCase())

