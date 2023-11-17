/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const AuthModal = require('views/core/AuthModal');
const RecoverModal = require('views/core/RecoverModal');

describe('AuthModal', function() {
  
  let modal = null;
  
  beforeEach(function() {
    if (!window.features.chinaUx) {
      application.facebookHandler.fakeAPI();
      application.gplusHandler.fakeAPI();
    }
    modal = new AuthModal();
    return modal.render();
  });

  afterEach(() => modal.stopListening());

  it('opens the recover modal when you click the recover link', function() {
    spyOn(modal, 'openModalView');
    modal.$el.find('#link-to-recover').click();
    expect(modal.openModalView.calls.count()).toEqual(1);
    const args = modal.openModalView.calls.argsFor(0);
    return expect(args[0] instanceof RecoverModal).toBeTruthy();
  });

  return it('(demo)', () => jasmine.demoModal(modal));
});
