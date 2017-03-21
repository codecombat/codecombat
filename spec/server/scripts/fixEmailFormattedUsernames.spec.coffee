# Don't need to run this regularly, only running script once.

#utils = require '../utils'
#User = require '../../../server/models/User'
#request = require '../request'
#sendwithus = require '../../../server/sendwithus'
#fixEmailFormattedUsernames = require '../../../scripts/node/fixEmailFormattedUsernames'
#
#describe '/scripts/node/fixEmailFormattedUsernames', ->
#  
#  beforeEach utils.wrap (done) ->
#    yield utils.clearModels([User])
#    console.log('spy on send async')
#    spyOn(sendwithus.api, 'sendAsync').and.callThrough()
#    done()
#    
#  afterEach ->
#    expect(sendwithus.api.sendAsync).toHaveBeenCalled()
#    
#  describe "when a user has no email set", ->
#    beforeEach utils.wrap (done) ->
#      @user = new User({name: 'an@email.com', points:100})
#      @user.allowEmailNames = true
#      yield @user.save()
#      done()
#
#    it 'moves the email-formatted username to be the user\'s email', utils.wrap (done) ->
#      yield fixEmailFormattedUsernames.run()
#      user = yield User.findById(@user.id)
#      expect(user.get('email')).toBe('an@email.com')
#      expect(user.get('name')).toBeUndefined()
#      expect(user.get('points')).toBe(100) # make sure properties aren't removed
#      done()
#      
#
#    describe "when another user exists with that email", ->
#      beforeEach utils.wrap (done) ->
#        @otherUser = new User({email: 'an@email.com'})
#        yield @otherUser.save()
#        done()
#      
#      it "slugifies the target user's username", utils.wrap (done) ->
#        yield fixEmailFormattedUsernames.run()
#        user = yield User.findById(@user.id)
#        expect(user.get('email')).toBeUndefined()
#        expect(user.get('name')).toBe('anemailcom')
#        done()
#
#  describe "when a user has the same email and username", ->
#    beforeEach utils.wrap (done) ->
#      @user = new User({name: 'an@email.com', email: 'an@email.com'})
#      @user.allowEmailNames = true
#      yield @user.save()
#      done()
#      
#    it "removes the user's username", utils.wrap (done) ->
#      yield fixEmailFormattedUsernames.run()
#      user = yield User.findById(@user.id)
#      expect(user.get('email')).toBe('an@email.com')
#      expect(user.get('name')).toBeUndefined()
#      done()
#
#  describe "when the user has an email that isn't formatted like an email", ->
#    beforeEach utils.wrap (done) ->
#      @user = new User({name: 'an@email.com', email: 'a name'})
#      @user.allowEmailNames = true
#      yield @user.save()
#      done()
#      
#    it "swaps the two", utils.wrap (done) ->
#      yield fixEmailFormattedUsernames.run()
#      user = yield User.findById(@user.id)
#      expect(user.get('email')).toBe('an@email.com')
#      expect(user.get('name')).toBe('a name')
#      done()
#
#    describe "when another user already has the email-formatted name as an email", ->
#      beforeEach utils.wrap (done) ->
#        @otherUser = new User({email: 'an@email.com'})
#        yield @otherUser.save()
#        done()
#
#      it "slugifies the target user's username", utils.wrap (done) ->
#        yield fixEmailFormattedUsernames.run()
#        user = yield User.findById(@user.id)
#        expect(user.get('email')).toBe('a name')
#        expect(user.get('name')).toBe('anemailcom')
#        done()
#        
#    describe "when another user already has the non-email-formatted email as a username", ->
#      beforeEach utils.wrap (done) ->
#        @otherUser = new User({name: 'a name'})
#        yield @otherUser.save()
#        done()
#
#      it "slugifies the target user's username", utils.wrap (done) ->
#        yield fixEmailFormattedUsernames.run()
#        user = yield User.findById(@user.id)
#        expect(user.get('email')).toBe('a name')
#        expect(user.get('name')).toBe('anemailcom')
#        done()
#
#  describe "when the user has a different but well formatted email set", ->
#    beforeEach utils.wrap (done) ->
#      @user = new User({name: 'an@email.com', email: 'another@email.com'})
#      @user.allowEmailNames = true
#      yield @user.save()
#      done()
#
#    it "removes the target user's username", utils.wrap (done) ->
#      yield fixEmailFormattedUsernames.run()
#      user = yield User.findById(@user.id)
#      expect(user.get('email')).toBe('another@email.com')
#      expect(user.get('name')).toBeUndefined()
#      done()
