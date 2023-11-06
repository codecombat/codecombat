/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoView = require('views/core/CocoView');
const User = require('models/User');
const CreateAccountModal = require('views/core/CreateAccountModal');
const AuthModal = require('views/core/AuthModal');

var BlandView = (BlandView = class BlandView extends CocoView {
  template() {
    if (this.specialMessage) { return '<div id="content">custom message</div>'; } else { return '<div id="content">normal message</div>'; }
  }

  constructor () {
    super()
    this.user1 = new User({_id: _.uniqueId()});
    this.supermodel.loadModel(this.user1);
    this.user2 = new User({ _id: _.uniqueId() })
    this.supermodel.loadModel(this.user2)
  }

  onResourceLoadFailed(e) {
    const {
      resource
    } = e;
    if ((resource.jqxhr.status === 400) && (resource.model === this.user1)) {
      this.specialMessage = true;
      return this.render();
    } else {
      return super.onResourceLoadFailed(...arguments);
    }
  }
});


describe('CocoView', () => describe('network error handling', function() {
  let view = null;
  const respond = function(code, index) {
    if (index == null) { index = 0; }
    view.render();
    const requests = jasmine.Ajax.requests.all();
    return requests[index].respondWith({status: code, responseText: JSON.stringify({})});
  };

  beforeEach(() => view = new BlandView());


  describe('when the view overrides onResourceLoadFailed', function() {
    beforeEach(function() {
      view.render();
      expect(view.$('#content').hasClass('hidden')).toBe(true);
      return respond(400);
    });

    it('can show a custom message for a given error and model', function() {
      expect(view.$('#content').hasClass('hidden')).toBe(false);
      expect(view.$('#content').text()).toBe('custom message');
      respond(200, 1);
      expect(view.$('#content').hasClass('hidden')).toBe(false);
      return expect(view.$('#content').text()).toBe('custom message');
    });

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });


  describe('when the server returns 401', function() {
    beforeEach(function() {
      me.set('anonymous', true);
      return respond(401);
    });

    it('shows a login button which opens the AuthModal', function() {
      const button = view.$el.find('.login-btn');
      expect(button.length).toBe(1);
      spyOn(view, 'openModalView').and.callFake(function(modal) {
        expect(modal instanceof AuthModal).toBe(true);
        return modal.stopListening();
      });
      button.click();
      return expect(view.openModalView).toHaveBeenCalled();
    });

    it('shows a create account button which opens the CreateAccountModal', function() {
      const button = view.$el.find('#create-account-btn');
      expect(button.length).toBe(1);
      spyOn(view, 'openModalView').and.callFake(function(modal) {
        expect(modal instanceof CreateAccountModal).toBe(true);
        return modal.stopListening();
      });
      button.click();
      return expect(view.openModalView).toHaveBeenCalled();
    });

    it('says "Login Required"', () => expect(view.$('[data-i18n="loading_error.login_required"]').length).toBeTruthy());

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });



  describe('when the server returns 402', function() {

    beforeEach(() => respond(402));

    return it('does nothing, because it is up to the view to handle payment next steps');
  });


  describe('when the server returns 403', function() {

    beforeEach(function() {
      me.set('anonymous', false);
      return respond(403);
    });

    it('includes a logout button which logs out the account', function() {
      const button = view.$el.find('#logout-btn');
      expect(button.length).toBe(1);
      button.click();
      const request = jasmine.Ajax.requests.mostRecent();
      return expect(request.url).toBe('/auth/logout');
    });

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });


  describe('when the server returns 404', function() {

    beforeEach(() => respond(404));

    it('includes one of the 404 images', function() {
      const img = view.$el.find('#not-found-img');
      return expect(img.length).toBe(1);
    });

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });


  describe('when the server returns 408', function() {

    beforeEach(() => respond(408));

    it('includes "Server Timeout" in the header', () => expect(view.$('[data-i18n="loading_error.timeout"]').length).toBeTruthy());

    it('shows a message encouraging refreshing the page or following links', () => expect(view.$('[data-i18n="loading_error.general_desc"]').length).toBeTruthy());

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });


  describe('when no connection is made', function() {

    beforeEach(() => respond());

    it('shows "Connection Failed"', () => expect(view.$('[data-i18n="loading_error.connection_failure"]').length).toBeTruthy());

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });


  return describe('when the server returns any other number >= 400', function() {

    beforeEach(() => respond(9001));

    it('includes "Unknown Error" in the header', () => expect(view.$('[data-i18n="loading_error.unknown"]').length).toBeTruthy());

    it('shows a message encouraging refreshing the page or following links', () => expect(view.$('[data-i18n="loading_error.general_desc"]').length).toBeTruthy());

    return it('(demo)', () => jasmine.demoEl(view.$el));
  });
}));
