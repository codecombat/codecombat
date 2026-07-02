/* eslint-disable no-undef */
const userUtils = require('../../../app/lib/user-utils')

describe('userUtils activity status', function () {
  describe('reconcileActivity', function () {
    const local = { first: 100, last: 200, count: 1 }
    const remoteRaw = { first: new Date(100), last: new Date(500), count: 3 }

    it('uses remote on cache miss', function () {
      const reconciled = userUtils.reconcileActivity(null, remoteRaw)
      expect(reconciled.count).toBe(3)
      expect(reconciled.last).toBe(500)
    })

    it('keeps local when remote is missing', function () {
      expect(userUtils.reconcileActivity(local, null)).toEqual(local)
    })

    it('prefers remote when count is higher', function () {
      const reconciled = userUtils.reconcileActivity(local, remoteRaw)
      expect(reconciled.count).toBe(3)
      expect(reconciled.last).toBe(500)
    })

    it('keeps optimistic local when ahead of remote', function () {
      const aheadLocal = { first: 100, last: 400, count: 2 }
      const staleRemote = { first: new Date(100), last: new Date(300), count: 1 }
      expect(userUtils.reconcileActivity(aheadLocal, staleRemote)).toEqual(aheadLocal)
    })
  })
})
