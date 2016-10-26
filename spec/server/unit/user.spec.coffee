GLOBAL._ = require 'lodash'

User = require '../../../server/models/User'
utils = require '../utils'
mongoose = require 'mongoose'

describe 'User', ->

  it 'uses the schema defaults to fill in email preferences', (done) ->
    user = new User()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('anyNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('recruitNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('archmageNews')).toBeFalsy()
    done()
  
  it 'uses old subs if they\'re around', (done) ->
    user = new User()
    user.set 'emailSubscriptions', ['tester']
    expect(user.isEmailSubscriptionEnabled('adventurerNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeFalsy()
    done()

  it 'maintains the old subs list if it\'s around', (done) ->
    user = new User()
    user.set 'emailSubscriptions', ['tester']
    user.setEmailSubscription('artisanNews', true)
    expect(JSON.stringify(user.get('emailSubscriptions'))).toBe(JSON.stringify(['tester', 'level_creator']))
    done()
    
  it 'does not allow anonymous to be set to true if there is a login method', utils.wrap (done) ->
    user = new User({passwordHash: '1234', anonymous: true})
    user = yield user.save()
    expect(user.get('anonymous')).toBe(false)
    done()

  it 'prevents duplicate oAuthIdentities', utils.wrap (done) ->
    provider1 = new mongoose.Types.ObjectId()
    provider2 = new mongoose.Types.ObjectId()
    identity1 = { provider: provider1, id: 'abcd' }
    identity2 = { provider: provider2, id: 'abcd' }
    identity3 = { provider: provider1, id: '1234' }

    # These three should live in harmony
    users = []
    users.push yield utils.initUser({ oAuthIdentities: [identity1] })
    users.push yield utils.initUser({ oAuthIdentities: [identity2] })
    users.push yield utils.initUser({ oAuthIdentities: [identity3] })

    e = null
    try
      users.push yield utils.initUser({ oAuthIdentities: [identity1] })
    catch e

    expect(e).not.toBe(null)
    done()

  describe '.updateServiceSettings()', ->
    makeMC = (callback) ->

    it 'uses emails to determine what to send to MailChimp', (done) ->
      spyOn(mc.lists, 'subscribe').and.callFake (params) ->
        expect(JSON.stringify(params.merge_vars.groupings[0].groups)).toBe(JSON.stringify(['Announcements']))
        done()

      user = new User({emailSubscriptions: ['announcement'], email: 'tester@gmail.com'})
      User.updateServiceSettings(user)

  describe '.isAdmin()', ->
    it 'returns true if user has "admin" permission', (done) ->
      adminUser = new User()
      adminUser.set('permissions', ['whatever', 'admin', 'user'])
      expect(adminUser.isAdmin()).toBeTruthy()
      done()

    it 'returns false if user has no permissions', (done) ->
      myUser = new User()
      myUser.set('permissions', [])
      expect(myUser.isAdmin()).toBeFalsy()
      done()
  
    it 'returns false if user has other permissions', (done) ->
      classicUser = new User()
      classicUser.set('permissions', ['user'])
      expect(classicUser.isAdmin()).toBeFalsy()
      done()
  
  describe '.verificationCode(timestamp)', ->
    it 'returns a timestamp and a hash', (done) ->
      user = new User()
      now = new Date()
      code = user.verificationCode(now.getTime())
      expect(code).toMatch(/[0-9]{13}:[0-9a-f]{64}/)
      [timestamp, hash] = code.split(':')
      expect(new Date(parseInt(timestamp))).toEqual(now)
      done()
      
  describe '.incrementStatAsync()', ->
    it 'records nested stats', utils.wrap (done) ->
      user = yield utils.initUser()
      yield User.incrementStatAsync user.id, 'stats.testNumber'
      yield User.incrementStatAsync user.id, 'stats.concepts.basic', {inc: 10}
      user = yield User.findById(user.id)
      expect(user.get('stats.testNumber')).toBe(1)
      expect(user.get('stats.concepts.basic')).toBe(10)
      done()
      
  describe 'subscription virtual', ->
    it 'has active and ends properties', ->
      moment = require 'moment'
      stripeEnd = moment().add(12, 'months').toISOString().substring(0,10)
      user1 = new User({stripe: {free:stripeEnd}})
      expectedEnd = "#{stripeEnd}T00:00:00.000Z"
      expect(user1.get('subscription').active).toBe(true)
      expect(user1.get('subscription').ends).toBe(expectedEnd)
      expect(user1.toObject({virtuals: true}).subscription.ends).toBe(expectedEnd)
      
      user2 = new User()
      expect(user2.get('subscription').active).toBe(false)
      
      user3 = new User({stripe: {free: true}})
      expect(user3.get('subscription').active).toBe(true)
      expect(user3.get('subscription').ends).toBeUndefined()
    
  describe '.prepaidIncludesCourse(courseID)', ->
    describe 'when the prepaid is a legacy full license', ->
      it 'returns true', ->
        user = new User({ coursePrepaidID: 'prepaid_1' })
        expect(user.prepaidIncludesCourse('course_1')).toBe(true)

    describe 'when the prepaid is a full license', ->
      it 'returns true', ->
        user = new User({ coursePrepaid: { _id: 'prepaid_1' } })
        expect(user.prepaidIncludesCourse('course_1')).toBe(true)
    
    describe 'when the prepaid is a starter license', ->
      beforeEach ->
        @user = new User({ coursePrepaid: { _id: 'prepaid_1', includedCourseIDs: ['course_1'] } })

      describe 'that does include the course', ->
        it 'returns true', ->
          expect(@user.prepaidIncludesCourse('course_1')).toBe(true)
          
      describe "that doesn't include the course", ->
        it 'returns false', ->
          expect(@user.prepaidIncludesCourse('course_2')).toBe(false)
    
    describe 'when the user has no prepaid', ->
      it 'returns false', ->
        @user = new User({ coursePrepaid: undefined })
        expect(@user.prepaidIncludesCourse('course_2')).toBe(false)
        
