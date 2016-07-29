User = require 'models/User'

describe 'UserModel', ->
  it 'experience functions are correct', ->
    expect(User.expForLevel(User.levelFromExp 0)).toBe 0
    expect(User.levelFromExp User.expForLevel 1).toBe 1
    expect(User.levelFromExp User.expForLevel 10).toBe 10
    expect(User.expForLevel 1).toBe 0
    expect(User.expForLevel 2).toBeGreaterThan User.expForLevel 1

  it 'level is calculated correctly', ->
    me.clear()
    me.set 'points', 0
    expect(me.level()).toBe 1

    me.set 'points', 50
    expect(me.level()).toBe User.levelFromExp 50

  describe 'user emails', ->
    it 'has anyNotes, generalNews and recruitNotes enabled by default', ->
      u = new User()
      expect(u.get('emails')).toBeUndefined()
      defaultEmails = u.get('emails', true)
      expect(defaultEmails.anyNotes.enabled).toBe(true)
      expect(defaultEmails.generalNews.enabled).toBe(true)
      expect(defaultEmails.recruitNotes.enabled).toBe(true)
    
    it 'maintains defaults of other emails when one is explicitly set', ->
      u = new User()
      u.setEmailSubscription('recruitNotes', false)
      defaultEmails = u.get('emails', true)
      expect(defaultEmails.anyNotes?.enabled).toBe(true)
      expect(defaultEmails.generalNews?.enabled).toBe(true)
      expect(defaultEmails.recruitNotes.enabled).toBe(false)
      
    it 'does not populate raw data for other emails when one is explicitly set', ->
      u = new User()
      u.setEmailSubscription('recruitNotes', false)
      u.buildAttributesWithDefaults()
      emails = u.get('emails')
      expect(emails.anyNotes).toBeUndefined()
      expect(emails.generalNews).toBeUndefined()
