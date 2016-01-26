CocoView = require 'views/core/CocoView'
User = require 'models/User'

BlandView = class BlandView extends CocoView
  template: -> ''
  initialize: ->
    @user = new User()
    @supermodel.loadModel(@user)

describe 'CocoView', ->
  describe 'network error handling', ->
    view = null
    respond = (code, json) ->
      request = jasmine.Ajax.requests.mostRecent()
      view.render()
      request.respondWith({status: code, responseText: JSON.stringify(json or {})})
    
    beforeEach ->
      view = new BlandView()
      
      
    describe 'when the server returns 401', ->
      beforeEach ->
        me.set('anonymous', true)
        respond(401)
      
      it 'shows a login button which opens the AuthModal', ->
        button = view.$el.find('.login-btn')
        expect(button.length).toBe(3) # including the two in the links section
        spyOn(view, 'openModalView').and.callFake (modal) -> expect(modal.mode).toBe('login')
        button.click()
        expect(view.openModalView).toHaveBeenCalled()
        
      it 'shows a create account button which opens the AuthModal', ->
        button = view.$el.find('#create-account-btn')
        expect(button.length).toBe(1)
        spyOn(view, 'openModalView').and.callFake (modal) -> expect(modal.mode).toBe('signup')
        button.click()
        expect(view.openModalView).toHaveBeenCalled()

      it 'says "Login Required"', ->
        expect(view.$el.text().indexOf('Login Required')).toBeGreaterThan(-1)

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
        expect(view.$el.text().indexOf('Server Timeout')).toBeGreaterThan(-1)
      
      it 'shows a message encouraging refreshing the page or following links', ->
        expect(view.$el.text().indexOf('refresh')).toBeGreaterThan(-1)

      it '(demo)', -> jasmine.demoEl(view.$el)


    describe 'when no connection is made', ->

      beforeEach ->
        respond()

      it 'shows "Connection Failed"', ->
        expect(view.$el.text().indexOf('Connection Failed')).toBeGreaterThan(-1)

      it '(demo)', -> jasmine.demoEl(view.$el)


    describe 'when the server returns any other number >= 400', ->

      beforeEach -> respond(9001)

      it 'includes "Unknown Error" in the header', ->
        expect(view.$el.text().indexOf('Unknown Error')).toBeGreaterThan(-1)

      it 'shows a message encouraging refreshing the page or following links', ->
        expect(view.$el.text().indexOf('refresh')).toBeGreaterThan(-1)

      it '(demo)', -> jasmine.demoEl(view.$el)
        
       
            
        
      