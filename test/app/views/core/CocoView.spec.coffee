CocoView = require 'views/core/CocoView'
User = require 'models/User'
CreateAccountModal = require 'views/core/CreateAccountModal'
AuthModal = require 'views/core/AuthModal'

BlandView = class BlandView extends CocoView
  template: ->
    return if @specialMessage then '<div id="content">custom message</div>' else '<div id="content">normal message</div>'
    
  initialize: ->
    @user1 = new User({_id: _.uniqueId()})
    @supermodel.loadModel(@user1)
    @user2 = new User({_id: _.uniqueId()})
    @supermodel.loadModel(@user2)

  onResourceLoadFailed: (e) ->
    resource = e.resource
    if resource.jqxhr.status is 400 and resource.model is @user1
      @specialMessage = true
      @render()
    else
      super(arguments...)
    

describe 'CocoView', ->
  describe 'network error handling', ->
    view = null
    respond = (code, index=0) ->
      view.render()
      requests = jasmine.Ajax.requests.all()
      requests[index].respondWith({status: code, responseText: JSON.stringify({})})
    
    beforeEach ->
      view = new BlandView()
      
    
    describe 'when the view overrides onResourceLoadFailed', ->
      beforeEach ->
        view.render()
        expect(view.$('#content').hasClass('hidden')).toBe(true)
        respond(400)
        
      it 'can show a custom message for a given error and model', ->
        expect(view.$('#content').hasClass('hidden')).toBe(false)
        expect(view.$('#content').text()).toBe('custom message')
        respond(200, 1)
        expect(view.$('#content').hasClass('hidden')).toBe(false)
        expect(view.$('#content').text()).toBe('custom message')

      it '(demo)', -> jasmine.demoEl(view.$el)
      
      
    describe 'when the server returns 401', ->
      beforeEach ->
        me.set('anonymous', true)
        respond(401)
      
      it 'shows a login button which opens the AuthModal', ->
        button = view.$el.find('.login-btn')
        expect(button.length).toBe(3) # including the two in the links section
        spyOn(view, 'openModalView').and.callFake (modal) -> 
          expect(modal instanceof AuthModal).toBe(true)
          modal.stopListening()
        button.click()
        expect(view.openModalView).toHaveBeenCalled()
        
      it 'shows a create account button which opens the CreateAccountModal', ->
        button = view.$el.find('#create-account-btn')
        expect(button.length).toBe(1)
        spyOn(view, 'openModalView').and.callFake (modal) ->
          expect(modal instanceof CreateAccountModal).toBe(true)
          modal.stopListening()
        button.click()
        expect(view.openModalView).toHaveBeenCalled()

      it 'says "Login Required"', ->
        expect(view.$('[data-i18n="loading_error.login_required"]').length).toBeTruthy()

      it '(demo)', -> jasmine.demoEl(view.$el)
      


    describe 'when the server returns 402', ->

      beforeEach -> respond(402)

      it 'does nothing, because it is up to the view to handle payment next steps'

    
    describe 'when the server returns 403', ->

      beforeEach ->
        me.set('anonymous', false)
        respond(403)
      
      it 'includes a logout button which logs out the account', ->
        button = view.$el.find('#logout-btn')
        expect(button.length).toBe(1)
        button.click()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.url).toBe('/auth/logout')

      it '(demo)', -> jasmine.demoEl(view.$el)

        
    describe 'when the server returns 404', ->

      beforeEach -> respond(404)

      it 'includes one of the 404 images', ->
        img = view.$el.find('#not-found-img')
        expect(img.length).toBe(1)

      it '(demo)', -> jasmine.demoEl(view.$el)


    describe 'when the server returns 408', ->

      beforeEach -> respond(408)
      
      it 'includes "Server Timeout" in the header', ->
        expect(view.$('[data-i18n="loading_error.timeout"]').length).toBeTruthy()
      
      it 'shows a message encouraging refreshing the page or following links', ->
        expect(view.$('[data-i18n="loading_error.general_desc"]').length).toBeTruthy()

      it '(demo)', -> jasmine.demoEl(view.$el)


    describe 'when no connection is made', ->

      beforeEach ->
        respond()

      it 'shows "Connection Failed"', ->
        expect(view.$('[data-i18n="loading_error.connection_failure"]').length).toBeTruthy()

      it '(demo)', -> jasmine.demoEl(view.$el)


    describe 'when the server returns any other number >= 400', ->

      beforeEach -> respond(9001)

      it 'includes "Unknown Error" in the header', ->
        expect(view.$('[data-i18n="loading_error.unknown"]').length).toBeTruthy()

      it 'shows a message encouraging refreshing the page or following links', ->
        expect(view.$('[data-i18n="loading_error.general_desc"]').length).toBeTruthy()

      it '(demo)', -> jasmine.demoEl(view.$el)
        
       
            
        
      