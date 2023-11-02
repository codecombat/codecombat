IsraelSignupView = require('views/account/IsraelSignupView')
utils = require 'core/utils'

describe 'IsraelSignupView', ->
  describe 'initialize()', ->
    it 'sets state.fatalError to "signed-in" if the user is not anonymous', ->
      spyOn(me, 'isAnonymous').and.returnValue(false)
      view = new IsraelSignupView()
      expect(view.state.get('fatalError')).toBe('signed-in')
      
    it 'sets state.fatalError to "missing-input" if the proper query parameters are not provided', ->
      queryVariables = null
      spyOn(me, 'isAnonymous').and.returnValue(true)
      spyOn(utils, 'getQueryVariables').and.callFake(-> queryVariables)

      # no inputs
      queryVariables = {}
      expect(new IsraelSignupView().state.get('fatalError')).toBe('missing-input')
      
      # id and email but email is not valid
      queryVariables = { email: 'notanemail', israelId: '...' }
      expect(new IsraelSignupView().state.get('fatalError')).toBe('invalid-email')

      # valid inputs
      queryVariables = { email: 'test@email.com', israelId: '...' }
      expect(new IsraelSignupView().state.get('fatalError')).toBe(null)
      
# TODO: Add more test cases when this view is more finalized
