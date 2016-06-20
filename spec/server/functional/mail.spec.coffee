require '../common'
mail = require '../../../server/routes/mail'
User = require '../../../server/models/User'
request = require '../request'

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
