ConvertToTeacherAccountView = require 'views/teachers/ConvertToTeacherAccountView'
storage = require 'core/storage'
forms = require 'core/forms'

describe '/teachers/convert', ->
  describe 'when logged out', ->
    it 'redirects to /teachers/signup', ->
      spyOn(me, 'isAnonymous').and.returnValue(true)
      spyOn(application.router, 'navigate')
      Backbone.history.loadUrl('/teachers/convert')
      expect(application.router.navigate.calls.count()).toBe(1)
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/teachers/signup')

  describe 'when logged in', ->
    it 'displays ConvertToTeacherAccountView', ->
      spyOn(me, 'isAnonymous').and.returnValue(false)
      spyOn(me, 'isTeacher').and.returnValue(false)
      spyOn(application.router, 'routeDirectly')
      Backbone.history.loadUrl('/teachers/convert')
      expect(application.router.routeDirectly.calls.count()).toBe(1)
      args = application.router.routeDirectly.calls.argsFor(0)
      expect(args[0]).toBe('teachers/ConvertToTeacherAccountView')


describe 'ConvertToTeacherAccountView (/teachers/convert)', ->

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

  
  describe 'when the user already has a TrialRequest and is a teacher', ->
    beforeEach (done) ->
      spyOn(application.router, 'navigate')
      spyOn(me, 'isTeacher').and.returnValue(true)
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

    it 'redirects to /courses/teachers', ->
      expect(application.router.navigate).toHaveBeenCalled()
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/courses/teachers')


  describe 'when the user has role "student"', ->
    beforeEach ->
      me.set('role', 'student')
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
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).not.toBe('/db/trial.request')
        expect(request.method).not.toBe('POST')
        confirmModal = view.openModalView.calls.argsFor(0)[0]
        confirmModal.trigger 'confirm'
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).toBe('/db/trial.request')
        expect(request.method).toBe('POST')

  describe '"Log out" link', ->

    it 'logs out the user and redirects them to /teachers/signup', ->
      spyOn(me, 'logout')
      view.$('#logout-link').click()
      expect(me.logout).toHaveBeenCalled()

  describe 'submitting the form', ->
    beforeEach ->
      form = view.$('form')
      forms.objectToForm(form, successForm, {overwriteExisting: true})
      form.submit()

    it 'creates a new TrialRequest with the information', ->
      request = _.last(jasmine.Ajax.requests.filter((r) -> _.string.startsWith(r.url, '/db/trial.request')))
      expect(request).toBeTruthy()
      expect(request.method).toBe('POST')
      attrs = JSON.parse(request.params)
      expect(attrs.properties?.firstName).toBe('Mr')

    it 'redirects to /courses/teachers', ->
      spyOn(application.router, 'navigate')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({
        status: 201
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      })
      expect(application.router.navigate).toHaveBeenCalled()
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/courses/teachers')

     it 'sets a teacher role', ->
      spyOn(application.router, 'navigate')
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({
        status: 201
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      })
      expect(me.get('role')).toBe(successForm.role.toLowerCase())

