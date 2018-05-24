require '../common'
utils = require '../utils'
mail = require '../../../server/routes/mail'
sendgrid = require '../../../server/sendgrid'
User = require '../../../server/models/User'
request = require '../request'
LevelSession = require '../../../server/models/LevelSession'

testPost =
  data:
    email: 'scott@codecombat.com'
    id: '12345678'
    merges:
      INTERESTS: 'Announcements, Adventurers, Archmages, Scribes, Diplomats, Ambassadors, Artisans'
      FNAME: 'Scott'
      LNAME: 'Erickson'

describe 'handleProfileUpdate', ->
  it 'updates emails from the data passed in', (done) ->
    u = new User(email: testPost.data.email)
    mail.handleProfileUpdate(u, testPost)
    expect(u.isEmailSubscriptionEnabled('generalNews')).toBeTruthy()
    expect(u.isEmailSubscriptionEnabled('adventurerNews')).toBeTruthy()
    expect(u.isEmailSubscriptionEnabled('archmageNews')).toBeTruthy()
    expect(u.isEmailSubscriptionEnabled('scribeNews')).toBeTruthy()
    expect(u.isEmailSubscriptionEnabled('diplomatNews')).toBeTruthy()
    expect(u.isEmailSubscriptionEnabled('ambassadorNews')).toBeTruthy()
    expect(u.isEmailSubscriptionEnabled('artisanNews')).toBeTruthy()
    done()

describe 'handleUnsubscribe', ->
  it 'turns off all news and notifications', (done) ->
    u = new User({generalNews: {enabled: true}, archmageNews: {enabled: true}, anyNotes: {enabled: true}, email: testPost.data.email})
    mail.handleUnsubscribe(u)
    expect(u.isEmailSubscriptionEnabled('generalNews')).toBeFalsy()
    expect(u.isEmailSubscriptionEnabled('adventurerNews')).toBeFalsy()
    expect(u.isEmailSubscriptionEnabled('archmageNews')).toBeFalsy()
    expect(u.isEmailSubscriptionEnabled('scribeNews')).toBeFalsy()
    expect(u.isEmailSubscriptionEnabled('diplomatNews')).toBeFalsy()
    expect(u.isEmailSubscriptionEnabled('ambassadorNews')).toBeFalsy()
    expect(u.isEmailSubscriptionEnabled('artisanNews')).toBeFalsy()
    done()

# This can be re-enabled on demand to test it, but for some async reason this
# crashes jasmine soon afterward.
describe 'sendNextStepsEmail', ->
  xit 'Sends the email', utils.wrap (done) ->
    user = yield utils.initUser({generalNews: {enabled: true}, anyNotes: {enabled: true}})
    expect(user.id).toBeDefined()
    yield new LevelSession({
      creator: user.id
      permissions: simplePermissions
      level: original: 'dungeon-arena'
      state: complete: true
    }).save()
    yield new LevelSession({
      creator: user.id
      permissions: simplePermissions
      level: original: 'dungeon-arena-2'
      state: complete: true
    }).save()

    spyOn(sendgrid.api, 'send').and.callFake (options, cb) ->
      expect(options.to.email).toBe(user.get('email'))
      cb()
      done()

    mail.sendNextStepsEmail(user, new Date, 5)
  .pend('Breaks other tests — must be run alone')

describe 'POST /mail/webhook', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User])
    @email = 'some@email.com'
    @leid = 'german song?'
    @user = yield utils.initUser({
      @email
      emailVerified: true
      emails: {
        generalNews: { enabled: false }
        diplomatNews: { enabled: true }
      }
    })
    yield new Promise((resolve) -> setTimeout(resolve, 100))
    yield @user.update({$set: { mailChimp: { @leid, @email }}}) # hacky way to get around triggering post save
    user = yield User.findById(@user.id)
    @url = utils.getURL('/mail/webhook')
    done()

  describe 'when getting messages of type "profile"', ->
    json = {
      type: 'profile'
      data: {
        web_id: @leid
        merges: {
          INTERESTS: 'Announcements, Adventurers, Artisans, Archmages'
          LNAME: 'Smith'
          FNAME: 'John'
        }
      }
    }

    beforeEach ->
      json.data.email = @email

    it 'updates the user with new profile data', utils.wrap (done) ->
      [res, body] = yield request.postAsync({ @url, json })
      user = yield User.findById(@user.id)
      expect(user.get('emails.diplomatNews.enabled')).toBe(false)
      expect(user.get('emails.generalNews.enabled')).toBe(true)
      expect(user.get('emails.artisanNews.enabled')).toBe(true)
      expect(user.get('emails.archmageNews.enabled')).toBe(true)
      done()

    it 'does not work if the user on our side is unverified', utils.wrap (done) ->
      yield @user.update({ $set: { emailVerified: false }})
      [res, body] = yield request.postAsync({ @url, json })
      user = yield User.findById(@user.id)
      expect(user.get('emails.diplomatNews.enabled')).toBe(true)
      expect(user.get('emails.generalNews.enabled')).toBe(false)
      done()

  describe 'when getting messages of type "unsubscribe"', ->
    it 'disables all subscriptions and unsets mailchimp info from the user', utils.wrap (done) ->
      json = {
        type: 'unsubscribe'
        data: {
          web_id: @leid
          @email
        }
      }
      [res, body] = yield request.postAsync({ @url, json })
      user = yield User.findById(@user.id)
      expect(user.get('emails.diplomatNews.enabled')).toBe(false)
      expect(user.get('mailChimp')).toBeFalsy()
      done()

  describe 'when getting messages of type "upemail"', ->
    it 'disables all subscriptions and unsets mailchimp info from the user', utils.wrap (done) ->
      json = {
        type: 'upemail'
        data: {
          old_email: @email
          new_email: 'some-new@email.com'
        }
      }
      [res, body] = yield request.postAsync({ @url, json })
      user = yield User.findById(@user.id)
      expect(user.get('emails.diplomatNews.enabled')).toBe(false)
      expect(user.get('mailChimp')).toBeFalsy()
      done()
