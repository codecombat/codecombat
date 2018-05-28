GLOBAL._ = require 'lodash'

User = require '../../../server/models/User'
utils = require '../utils'
mongoose = require 'mongoose'

describe 'User', ->

  it 'uses the schema defaults to fill in email preferences', (done) ->
    user = new User(email: 'some@email.com')
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('anyNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('recruitNotes')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('archmageNews')).toBeFalsy()
    done()

  it 'uses old subs if they\'re around', (done) ->
    user = new User(email: 'some@email.com')
    user.set 'emailSubscriptions', ['tester']
    expect(user.isEmailSubscriptionEnabled('adventurerNews')).toBeTruthy()
    expect(user.isEmailSubscriptionEnabled('generalNews')).toBeFalsy()
    done()

  it 'maintains the old subs list if it\'s around', (done) ->
    user = new User(email: 'some@email.com')
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

  describe 'cancelPayPalSubscription', ->
    describe 'when subscribed via payPal', ->
      beforeEach utils.wrap ->
        @user = yield utils.initUser({username: 'test1', payPal: {billingAgreementID: 'abc123', subscribeDate: new Date('2017-01-04')}})
      it 'user unsubscribed with remaining time captured with stripe.free', utils.wrap ->
        beforeCancelDate = new Date()
        yield @user.cancelPayPalSubscription()
        cancelDate = @user.get('payPal').cancelDate
        cancelDate.setUTCDate(cancelDate.getUTCDate() - 1)
        expect(cancelDate).not.toBeGreaterThan(beforeCancelDate)
        cancelDate.setUTCDate(cancelDate.getUTCDate() + 2)
        expect(cancelDate).toBeGreaterThan(beforeCancelDate)
        expect(new Date(@user.get('stripe').free)).toBeGreaterThan(new Date())
    describe 'when not subscribed via payPal', ->
      beforeEach utils.wrap ->
        @user = yield utils.initUser({username: 'test1'})
      it 'user unchanged on cancel', utils.wrap ->
        beforeUser = JSON.stringify(@user)
        yield @user.cancelPayPalSubscription()
        expect(beforeUser).toEqual(JSON.stringify(@user))

  describe '.updateServiceSettings()', ->
    it 'uses emails to determine what to send to MailChimp', utils.wrap (done) ->
      email = 'tester@gmail.com'
      user = new User({emailSubscriptions: ['announcement'], @email, emailLower: email})
      spyOn(user, 'updateMailChimp').and.returnValue(Promise.resolve())
      yield user.updateServiceSettings()
      expect(user.updateMailChimp).toHaveBeenCalled()
      done()

    it 'updates stripe email iff email changes on save', utils.wrap (done) ->
      stripeApi = require('../../../server/lib/stripe_utils').api
      spyOn(stripeApi.customers, 'update')
      user = new User({email: 'first@email.com'})
      yield user.save()

      user = yield User.findById(user.id)
      user.set({email: 'second@email.com'})
      yield user.save()

      user = yield User.findById(user.id)
      user.set({stripe: {customerID: '1234'}})
      yield user.save()
      expect(stripeApi.customers.update.calls.count()).toBe(0)

      user = yield User.findById(user.id)
      user.set({email: 'third@email.com'})
      yield user.save()
      expect(stripeApi.customers.update.calls.count()).toBe(1)

      user = yield User.findById(user.id)
      user.set({email: 'first@email.com'})
      yield user.save()
      expect(stripeApi.customers.update.calls.count()).toBe(2)

      user = yield User.findById(user.id)
      yield user.save()
      expect(stripeApi.customers.update.calls.count()).toBe(2)
      done()

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


  describe '.updateMailChimp()', ->
    beforeEach utils.wrap (done) ->
      yield utils.clearModels([User])
      done()

    mailChimp = require '../../../server/lib/mail-chimp'

    it 'propagates user notification and name settings to MailChimp', utils.wrap (done) ->
      user = yield utils.initUser({
        emailVerified: true
        firstName: 'First'
        lastName: 'Last'
        emails: {
          diplomatNews: { enabled: true }
          generalNews: { enabled: true }
        }
      })
      spyOn(mailChimp.api, 'put').and.returnValue(Promise.resolve())
      yield user.updateMailChimp()
      expect(mailChimp.api.put.calls.count()).toBe(1)
      args = mailChimp.api.put.calls.argsFor(0)
      expect(args[0]).toMatch("^/lists/[0-9a-f]+/members/[0-9a-f]+$")
      expect(args[1]?.email_address).toBe(user.get('email'))
      diplomatInterest = _.find(mailChimp.interests, (interest) -> interest.property is 'diplomatNews')
      announcementsInterest = _.find(mailChimp.interests, (interest) -> interest.property is 'generalNews')
      for [key, value] in _.pairs(args[1].interests)
        if key in [diplomatInterest.mailChimpId, announcementsInterest.mailChimpId]
          expect(value).toBe(true)
        else
          expect(value).toBeFalsy()
      expect(args[1]?.status).toBe('subscribed')
      expect(args[1]?.merge_fields['FNAME']).toBe('First')
      expect(args[1]?.merge_fields['LNAME']).toBe('Last')
      user = yield User.findById(user.id)
      expect(user.get('mailChimp').email).toBe(user.get('email'))
      done()

    describe 'when user email is validated on MailChimp but not CodeCombat', ->

      it 'still updates their settings on MailChimp', utils.wrap (done) ->
        email = 'some@email.com'
        user = yield utils.initUser({
          email
          emailVerified: false
          emails: {
            diplomatNews: { enabled: true }
          }
          mailChimp: { email }
        })
        user = yield User.findById(user.id)
        spyOn(mailChimp.api, 'get').and.returnValue(Promise.resolve({ status: 'subscribed' }))
        spyOn(mailChimp.api, 'put').and.returnValue(Promise.resolve())
        yield user.updateMailChimp()
        expect(mailChimp.api.get.calls.count()).toBe(1)
        expect(mailChimp.api.put.calls.count()).toBe(1)
        args = mailChimp.api.put.calls.argsFor(0)
        expect(args[1]?.status).toBe('subscribed')
        done()

    describe 'when the user\'s email changes', ->

      it 'unsubscribes the old entry, and does not subscribe the new email until validated', utils.wrap (done) ->
        oldEmail = 'old@email.com'
        newEmail = 'new@email.com'
        user = yield utils.initUser({
          email: newEmail
          emailVerified: false
          emails: {
            diplomatNews: { enabled: true }
          }
          mailChimp: { email: oldEmail }
        })
        spyOn(mailChimp.api, 'put').and.returnValue(Promise.resolve())
        yield user.updateMailChimp()
        expect(mailChimp.api.put.calls.count()).toBe(1)
        args = mailChimp.api.put.calls.argsFor(0)
        expect(args[1]?.status).toBe('unsubscribed')
        expect(args[0]).toBe(mailChimp.makeSubscriberUrl(oldEmail))
        done()

    describe 'when the user is not subscribed on MailChimp and is not subscribed to any interests on CodeCombat', ->

      it 'does nothing', utils.wrap (done) ->
        user = yield utils.initUser({
          emailVerified: true
          emails: {
            generalNews: { enabled: false }
          }
        })
        spyOn(mailChimp.api, 'get')
        spyOn(mailChimp.api, 'put')
        yield user.updateMailChimp()
        expect(mailChimp.api.get.calls.count()).toBe(0)
        expect(mailChimp.api.put.calls.count()).toBe(0)
        done()

    describe 'when the user is on MailChimp but not validated there nor on CodeCombat', ->

      it 'updates with status set to unsubscribed', utils.wrap (done) ->
        spyOn(User.schema.methods, 'updateMailChimp').and.callThrough()
        email = 'some@email.com'
        user = yield utils.initUser({
          email
          emailVerified: false
          emails: {
            diplomatNews: { enabled: true }
          }
          mailChimp: { email }
        })
        yield new Promise((resolve) -> setTimeout(resolve, 10)) # hack to get initial updateMailChimp call flushed out
        spyOn(mailChimp.api, 'get').and.returnValue(Promise.resolve({ status: 'unsubscribed' }))
        spyOn(mailChimp.api, 'put').and.returnValue(Promise.resolve())
        yield user.updateMailChimp()
        expect(mailChimp.api.get.calls.count()).toBe(1)
        expect(mailChimp.api.put.calls.count()).toBe(1)
        args = mailChimp.api.put.calls.argsFor(0)
        expect(args[1]?.status).toBe('unsubscribed')
        done()

  describe 'inEU', ->
    it 'true if in EU country', utils.wrap ->
      u = yield utils.initUser({country: 'germany'})
      expect(u.inEU()).toEqual(true)
    it 'false if not in EU country', utils.wrap ->
      u = yield utils.initUser({country: 'mexico'})
      expect(u.inEU()).toEqual(false)
    it 'true if not defined', utils.wrap ->
      u = yield utils.initUser()
      expect(u.get('country')).toBeUndefined()
      expect(u.inEU()).toEqual(true)
