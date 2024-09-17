/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const User = require('models/User')

describe('UserModel', function () {
  it('experience functions are correct', function () {
    expect(User.expForLevel(User.levelFromExp(0))).toBe(0)
    expect(User.levelFromExp(User.expForLevel(1))).toBe(1)
    expect(User.levelFromExp(User.expForLevel(10))).toBe(10)
    expect(User.expForLevel(1)).toBe(0)
    return expect(User.expForLevel(2)).toBeGreaterThan(User.expForLevel(1))
  })

  it('level is calculated correctly', function () {
    me.clear()
    me.set('points', 0)
    expect(me.level()).toBe(1)

    me.set('points', 50)
    return expect(me.level()).toBe(User.levelFromExp(50))
  })

  describe('user emails', function () {
    it('has anyNotes, generalNews and recruitNotes enabled by default', function () {
      const u = new User()
      expect(u.get('emails')).toBeUndefined()
      const defaultEmails = u.get('emails', true)
      expect(defaultEmails.anyNotes.enabled).toBe(true)
      expect(defaultEmails.generalNews.enabled).toBe(true)
      return expect(defaultEmails.recruitNotes.enabled).toBe(true)
    })

    it('maintains defaults of other emails when one is explicitly set', function () {
      const u = new User()
      u.setEmailSubscription('recruitNotes', false)
      const defaultEmails = u.get('emails', true)
      expect(defaultEmails.anyNotes != null ? defaultEmails.anyNotes.enabled : undefined).toBe(true)
      expect(defaultEmails.generalNews != null ? defaultEmails.generalNews.enabled : undefined).toBe(true)
      return expect(defaultEmails.recruitNotes.enabled).toBe(false)
    })

    return it('does not populate raw data for other emails when one is explicitly set', function () {
      const u = new User()
      u.setEmailSubscription('recruitNotes', false)
      u.buildAttributesWithDefaults()
      const emails = u.get('emails')
      expect(emails.anyNotes).toBeUndefined()
      return expect(emails.generalNews).toBeUndefined()
    })
  })

  describe('validate', function () {
    it('returns undefined if the user is valid', () => expect(new User().validate()).toBeUndefined())

    it('returns an array of errors if the user is invalid', function () {
      const res = new User({ invalidProp: '...' }).validate()
      return expect(_.isArray(res)).toBe(true)
    })

    return it('returns undefined if the user is invalid but has no new validation errors since when last marked to revert', function () {
      const user = new User({ invalidProp: '...' })
      user.markToRevert()
      user.set('name', 'this is fine')
      expect(user.validate()).toBeUndefined()
      user.set('newInvalidProp', '...')
      return expect(_.isArray(user.validate())).toBe(true)
    })
  })

  describe('inEU', function () {
    it('true if in EU country', function () {
      const u = new User({ country: 'germany' })
      return expect(u.inEU()).toEqual(true)
    })
    it('false if not in EU country', function () {
      const u = new User({ country: 'mexico' })
      return expect(u.inEU()).toEqual(false)
    })
    return it('true if not defined', function () {
      const u = new User()
      expect(u.get('country')).toBeUndefined()
      return expect(u.inEU()).toEqual(true)
    })
  })

  describe('shouldSeePromotion', function () {
    let user

    beforeEach(function () {
      user = new User()
    })

    it('returns true if no key is provided', function () {
      expect(user.shouldSeePromotion()).toBe(true)
    })

    it('returns false if promotion has been seen', function () {
      user.set('seenPromotions', { promoKey: new Date().toISOString() })
      expect(user.shouldSeePromotion('promoKey')).toBe(false)
    })

    it('returns true if latest promotion was seen more than a week ago', function () {
      const eightDaysAgo = new Date()
      eightDaysAgo.setDate(eightDaysAgo.getDate() - 8)

      user.set('seenPromotions', { otherPromoKey: eightDaysAgo.toISOString() })
      expect(user.shouldSeePromotion('promoKey')).toBe(true)
    })

    it('returns false if latest promotion was seen less than a week ago', function () {
      const sixDaysAgo = new Date()
      sixDaysAgo.setDate(sixDaysAgo.getDate() - 6)
      const eightDaysAgo = new Date()
      eightDaysAgo.setDate(eightDaysAgo.getDate() - 8)

      user.set('seenPromotions', {
        otherPromoKey: sixDaysAgo.toISOString(),
        otherPromoKey2: eightDaysAgo.toISOString()
      })
      expect(user.shouldSeePromotion('promoKey')).toBe(false)
    })
  })
})
