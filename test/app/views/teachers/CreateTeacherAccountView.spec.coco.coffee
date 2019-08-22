CreateTeacherAccountView = require 'views/teachers/CreateTeacherAccountView'
forms = require 'core/forms'

describe '/teachers/signup', ->

  describe 'when logged out', ->

    it 'displays CreateTeacherAccountView', ->
      spyOn(me, 'isAnonymous').and.returnValue(true)
      spyOn(application.router, 'routeDirectly')
      Backbone.history.loadUrl('/teachers/signup')
      expect(application.router.routeDirectly.calls.count()).toBe(1)
      args = application.router.routeDirectly.calls.argsFor(0)
      expect(args[0]).toBe('teachers/CreateTeacherAccountView')

  describe 'when logged in', ->

    it 'redirects to /teachers/update-account', ->
      spyOn(me, 'isAnonymous').and.returnValue(false)
      spyOn(application.router, 'navigate')
      Backbone.history.loadUrl('/teachers/signup')
      expect(application.router.navigate.calls.count()).toBe(1)
      args = application.router.navigate.calls.argsFor(0)
      expect(args[0]).toBe('/teachers/update-account')

describe 'CreateTeacherAccountView', ->

  view = null

  successForm = {
    name: 'New Name'
    phoneNumber: '555-555-5555'
    role: 'Teacher'
    organization: 'School'
    district: 'District'
    city: 'Springfield'
    state: 'AA'
    country: 'asdf'
    numStudents: '1-10'
    numStudentsTotal: '1-500'
    educationLevel: ['Middle']
    email: 'some@email.com'
    firstName: 'Mr'
    lastName: 'Bean'
    password1: 'letmein'
    password2: 'letmein'
  }

  beforeEach (done) ->
    me.clear()
    me.set('_id', '1234')
    me._revertAttributes = {}
    spyOn(me, 'isAnonymous').and.returnValue(true)
    view = new CreateTeacherAccountView()
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

  describe 'when the form is unchanged', ->
    it 'does not prevent navigating away', ->
      expect(_.result(view, 'onLeaveMessage')).toBeFalsy()

  describe 'when the form has changed but is not submitted', ->
    beforeEach ->
      view.$el.find('form').trigger('change')

    it 'prevents navigating away', ->
      expect(_.result(view, 'onLeaveMessage')).toBeTruthy()

  describe '"Log in" link', ->

    it 'opens the log in modal', ->
      spyOn(view, 'openModalView')
      view.$('.alert .login-link').click()
      expect(view.openModalView.calls.count()).toBe(1)
      AuthModal = require 'views/core/AuthModal'
      expect(view.openModalView.calls.argsFor(0)[0] instanceof AuthModal).toBe(true)

  if !window.features.chinaUx
    describe 'clicking the Facebook button', ->

      beforeEach ->
        application.facebookHandler.fakeAPI()
        view.$('#facebook-signup-btn').click()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234')
        expect(request.method).toBe('GET')

      describe 'when an associated user already exists', ->
        beforeEach ->
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({
            status: 200
            responseText: JSON.stringify({_id: 'abcd'})
          })

        it 'logs them in and redirects them to the ConvertToTeacherAccountView', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.url).toBe('/auth/login-facebook')

      describe 'when the user connects with Facebook and there isn\'t already an associated account', ->
        beforeEach ->
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({ status: 404, responseText: '{}' })

        it 'disables and fills in the email, first name, last name and password fields', ->
          for field in ['email', 'firstName', 'lastName', 'password1', 'password2']
            expect(view.$("input[name='#{field}']").attr('disabled')).toBeTruthy()

        it 'hides the social login buttons and shows a success message', ->
          expect(view.$('#facebook-logged-in-row').hasClass('hide')).toBe(false)
          expect(view.$('#social-network-signups').hasClass('hide')).toBe(true)

        describe 'and the user finishes filling in the form and submits', ->

          beforeEach ->
            form = view.$('form')
            forms.objectToForm(form, successForm)
            form.submit()

          it 'creates a user associated with the Facebook account', (done) ->
            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toBe('/db/trial.request')
            request.respondWith({
              status: 201
              responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
            })
            view.once 'update-settings', =>
              request = jasmine.Ajax.requests.mostRecent()
              expect(request.url).toBe("/db/user/1234")
              body = JSON.parse(request.params)
              expect(body.firstName).toBe('Mr')
              expect(body.lastName).toBe('Bean')
              request.respondWith({
                status: 200
                responseText: '{}'
              })
              view.once 'signup', =>
                request = jasmine.Ajax.requests.mostRecent()
                expect(request.url).toBe("/db/user/1234/signup-with-facebook")
                expected = {"name":"New Name","email":"some@email.com","facebookID":"abcd","facebookAccessToken":"1234"}
                actual = JSON.parse(request.params)
                expect(_.isEqual(expected, actual)).toBe(true)
                done()

  if !window.features.chinaUx
    describe 'clicking the G+ button', ->

      beforeEach ->
        application.gplusHandler.fakeAPI()
        view.$('#gplus-signup-btn').click()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234')
        expect(request.method).toBe('GET')

      describe 'when an associated user already exists', ->
        beforeEach ->
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({
            status: 200
            responseText: JSON.stringify({_id: 'abcd'})
          })

        it 'logs them in and redirects them to the ConvertToTeacherAccountView', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.url).toBe('/auth/login-gplus')

      describe 'when the user connects with G+ and there isn\'t already an associated account', ->
        beforeEach ->
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({ status: 404, responseText: '{}' })

        it 'disables and fills in the email, first name, last name and password fields', ->
          for field in ['email', 'firstName', 'lastName', 'password1', 'password2']
            expect(view.$("input[name='#{field}']").attr('disabled')).toBeTruthy()

        it 'hides the social login buttons and shows a success message', ->
          expect(view.$('#gplus-logged-in-row').hasClass('hide')).toBe(false)
          expect(view.$('#social-network-signups').hasClass('hide')).toBe(true)

        describe 'and the user finishes filling in the form and submits', ->

          beforeEach ->
            form = view.$('form')
            forms.objectToForm(form, successForm)
            form.submit()

          it 'creates a user associated with the GPlus account', (done) ->
            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toBe('/db/trial.request')
            request.respondWith({
              status: 201
              responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
            })
            view.once 'update-settings', =>
              request = jasmine.Ajax.requests.mostRecent()
              expect(request.url).toBe("/db/user/1234")
              body = JSON.parse(request.params)
              expect(body.firstName).toBe('Mr')
              expect(body.lastName).toBe('Bean')
              request.respondWith({
                status: 200
                responseText: '{}'
              })
              view.once 'signup', =>
                request = jasmine.Ajax.requests.mostRecent()
                expect(request.url).toBe("/db/user/1234/signup-with-gplus")
                expected = {"name":"New Name","email":"some@email.com","gplusID":"abcd","gplusAccessToken":"1234"}
                actual = JSON.parse(request.params)
                expect(_.isEqual(expected, actual)).toBe(true)
                done()

  describe 'submitting the form successfully', ->

    beforeEach ->
      view.$el.find('#request-form').trigger('change') # to confirm navigating away isn't prevented
      form = view.$('form')
      forms.objectToForm(form, successForm)
      form.submit()

    it 'does not prevent navigating away', ->
      expect(_.result(view, 'onLeaveMessage')).toBeFalsy()

    it 'submits a trial request, which does not include "account" settings', ->
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/trial.request')
      expect(request.method).toBe('POST')
      attrs = JSON.parse(request.params)
      expect(attrs.password1).toBeUndefined()
      expect(attrs.password2).toBeUndefined()
      expect(attrs.name).toBeUndefined()
      expect(attrs.properties?.siteOrigin).toBe('create teacher')
      expect(attrs.properties?.organization).toEqual('School')
      expect(attrs.properties?.district).toEqual('District')

    describe 'after saving the new trial request', ->
      beforeEach (done) ->
        view.once 'update-settings', done
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({
          status: 201
          responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
        })

      it 'updates user and signs up with password', (done) ->
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).toBe('/db/user/1234')
        expect(request.method).toBe('PUT')
        attrs = JSON.parse(request.params)
        for attr in ['role', 'firstName', 'lastName']
          expect(attrs[attr]).toBeDefined()
        request.respondWith({ status: 201, responseText: '{}' })
        view.once 'signup', =>
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.url).toBe('/db/user/1234/signup-with-password')
          body = JSON.parse(request.params)
          for attr in ['email', 'password', 'name']
            expect(body[attr]).toBeDefined()
          done()

      describe 'after saving the new user', ->

        beforeEach (done) ->
          spyOn(application.router, 'navigate')
          spyOn(application.router, 'reload')
          request = jasmine.Ajax.requests.mostRecent()
          request.respondWith({
            status: 201
            responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
          })
          expect(request.url).toBe('/db/user/1234')
          view.once 'signup', =>
            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toBe('/db/user/1234/signup-with-password')
            request.respondWith({ status: 201, responseText: '{}' })
            view.once 'on-trial-request-submit-complete', done

        it 'redirects to "/teachers/courses"', ->
          expect(application.router.navigate).toHaveBeenCalled()
          expect(application.router.reload).toHaveBeenCalled()


  describe 'submitting the form with an email for an existing account', ->

    beforeEach ->
      form = view.$('form')
      forms.objectToForm(form, successForm)
      form.submit()
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({ status: 409, responseText: '{}' })

    it 'displays an error with a log in link', ->
      expect(view.$('#email-form-group').hasClass('has-error')).toBe(true)
      spyOn(view, 'openModalView')
      view.$('#email-form-group .login-link').click()
      expect(view.openModalView).toHaveBeenCalled()

  describe 'submitting the form without school', ->
    beforeEach ->
      view.$el.find('#request-form').trigger('change') # to confirm navigating away isn't prevented
      form = view.$('form')
      formData = _.omit(successForm, ['organization'])
      forms.objectToForm(form, formData)
      form.submit()

    it 'submits a trial request, which does not include school setting', ->
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/trial.request')
      expect(request.method).toBe('POST')
      attrs = JSON.parse(request.params)
      expect(attrs.properties?.organization).toBeUndefined()
      expect(attrs.properties?.district).toEqual('District')

  describe 'submitting the form without district', ->
    beforeEach ->
      view.$el.find('#request-form').trigger('change') # to confirm navigating away isn't prevented
      form = view.$('form')
      formData = _.omit(successForm, ['district'])
      forms.objectToForm(form, formData)
      form.submit()

    it 'displays a validation error on district and not school', ->
      expect(view.$('#organization-control').closest('.form-group').hasClass('has-error')).toEqual(false)
      expect(view.$('#district-control').closest('.form-group').hasClass('has-error')).toEqual(true)

  describe 'submitting the form district set to n/a', ->
    beforeEach ->
      view.$el.find('#request-form').trigger('change') # to confirm navigating away isn't prevented
      form = view.$('form')
      formData = _.omit(successForm, ['organization'])
      formData.district = 'N/A'
      forms.objectToForm(form, formData)
      form.submit()

    it 'submits a trial request, which does not include district setting', ->
      expect(view.$('#organization-control').closest('.form-group').hasClass('has-error')).toEqual(false)
      expect(view.$('#district-control').closest('.form-group').hasClass('has-error')).toEqual(false)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.url).toBe('/db/trial.request')
      expect(request.method).toBe('POST')
      attrs = JSON.parse(request.params)
      expect(attrs.properties?.district).toBeUndefined()
