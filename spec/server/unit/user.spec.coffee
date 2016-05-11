GLOBAL._ = require 'lodash'

User = require '../../../server/models/User'

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
