/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const IsraelSignupView = require('views/account/IsraelSignupView');
const utils = require('core/utils');

describe('IsraelSignupView', () => describe('initialize()', function() {
  it('sets state.fatalError to "signed-in" if the user is not anonymous', function() {
    spyOn(me, 'isAnonymous').and.returnValue(false);
    const view = new IsraelSignupView();
    return expect(view.state.get('fatalError')).toBe('signed-in');
  });
    
  return it('sets state.fatalError to "missing-input" if the proper query parameters are not provided', function() {
    let queryVariables = null;
    spyOn(me, 'isAnonymous').and.returnValue(true);
    spyOn(utils, 'getQueryVariables').and.callFake(() => queryVariables);

    // no inputs
    queryVariables = {};
    expect(new IsraelSignupView().state.get('fatalError')).toBe('missing-input');
    
    // id and email but email is not valid
    queryVariables = { email: 'notanemail', israelId: '...' };
    expect(new IsraelSignupView().state.get('fatalError')).toBe('invalid-email');

    // valid inputs
    queryVariables = { email: 'test@email.com', israelId: '...' };
    return expect(new IsraelSignupView().state.get('fatalError')).toBe(null);
  });
}));
      
// TODO: Add more test cases when this view is more finalized
