require '../common'
utils = require '../utils'
mail = require '../../../server/routes/mail'
sendwithus = require '../../../server/sendwithus'
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
    u = new User()
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
    u = new User({generalNews: {enabled: true}, archmageNews: {enabled: true}, anyNotes: {enabled: true}})
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

    spyOn(sendwithus.api, 'send').and.callFake (options, cb) ->
      expect(options.recipient.address).toBe(user.get('email'))
      cb()
      done()

    mail.sendNextStepsEmail(user, new Date, 5)
  .pend('Breaks other tests — must be run alone')
