User = require '../../../server/models/User'
request = require '../request'
utils = require '../utils'
Promise = require 'bluebird'

UserHandler = require '../../../server/handlers/user_handler'

describe 'UserHandler', ->
  describe '.recalculateStats(statName, done)', ->
    it 'recalculates amount of submitted and accepted patches', utils.wrap (done) ->
      creator = yield utils.initAdmin()
      yield utils.loginUser(creator)
      article = yield utils.makeArticle()

      user = yield utils.initUser()
      yield utils.loginUser(user)
      json = {
        commitMessage: 'Accept this patch!'
        delta: {name: ['test']}
        target: {id: article.id, collection: 'article'}
      }
      url = utils.getURL('/db/patch')
      [res, body] = yield request.postAsync { url, json }
      patchID = body._id
      expect(res.statusCode).toBe(201)

      yield utils.loginUser(creator)
      url = utils.getURL("/db/patch/#{patchID}/status")
      [res, body] = yield request.putAsync {url, json: {status: 'accepted'}}
      expect(res.statusCode).toBe(200)

      user = yield User.findById(user.id)
      expect(user.get 'stats.patchesSubmitted').toBe 1
      statsBefore = user.get('stats')

      yield user.update({$unset: {stats: ''}})
      user = yield User.findById(user.id)
      expect(user.get 'stats').toBeUndefined()
      recalculateStatsAsync = Promise.promisify(UserHandler.recalculateStats)
      yield [
        recalculateStatsAsync 'patchesContributed'
        recalculateStatsAsync 'patchesSubmitted'
        recalculateStatsAsync 'totalMiscPatches'
        recalculateStatsAsync 'totalTranslationPatches'
        recalculateStatsAsync 'articleMiscPatches'
      ]
      user = yield User.findById(user.id)
      statsAfter = user.get('stats')

      expect(_.isEqual(statsBefore, statsAfter)).toBe(true)
      done()

  describe 'when get target is student', ->
    beforeEach utils.wrap ->
      @student = yield utils.initUser({ role: 'student' })
    describe 'and getter is same user', ->
      it 'get is allowed', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(200)
    describe 'and getter is different non-admin user', ->
      beforeEach utils.wrap ->
        @getter = yield utils.initUser()
        yield utils.loginUser(@getter)
      it 'get is forbidden', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(403)
    describe 'and getter is different admin user', ->
      beforeEach utils.wrap ->
        @getter = yield utils.initAdmin()
        yield utils.loginUser(@getter)
      it 'get is allowed', utils.wrap ->
        url = utils.getURL("/db/user/#{@student.id}")
        [res, body] = yield request.getAsync({ url, json: true })
        expect(res.statusCode).toEqual(200)
