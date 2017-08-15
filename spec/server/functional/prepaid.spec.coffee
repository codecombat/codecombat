require '../common'
config = require '../../../server_config'
moment = require 'moment'
{findStripeSubscription} = require '../../../server/lib/utils'
async = require 'async'
nockUtils = require '../nock-utils'
utils = require '../utils'
Promise = require 'bluebird'
Payment = require '../../../server/models/Payment'
Prepaid = require '../../../server/models/Prepaid'
User = require '../../../server/models/User'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
request = require '../request'

describe 'POST /db/prepaid', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Prepaid])
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    done()

  it 'creates a new prepaid for type "course"', utils.wrap (done) ->
    user = yield utils.initUser()
    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: user.id
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('creator').equals(user._id)).toBe(true)
    expect(prepaid.get('code')).toBeDefined()
    done()

  it 'does not work for non-admins', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: user.id
    }})
    expect(res.statusCode).toBe(403)
    done()

  it 'accepts start and end dates', utils.wrap (done) ->
    user = yield utils.initUser()
    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: user.id
      startDate: new Date().toISOString(2001,1,1)
      endDate: new Date().toISOString(2010,1,1)
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('startDate')).toBeDefined()
    expect(prepaid.get('endDate')).toBeDefined()
    done()

describe 'GET /db/prepaid', ->
  beforeEach utils.wrap (done) ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    prepaid = new Prepaid({creator: @user.id, type: 'course'})
    yield prepaid.save()
    prepaid = new Prepaid({creator: @user.id, type: 'starter_license'})
    yield prepaid.save()
    prepaid = new Prepaid({creator: @user.id, type: 'terminal_subscription'})
    yield prepaid.save()
    prepaid = new Prepaid({creator: @user.id, type: 'subscription'})
    yield prepaid.save()
    done()

  describe 'when creator param', ->
    it 'returns only course and starter_license prepaids for creator', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: getURL("/db/prepaid?creator=#{@user.id}"), json: true})
      expect(body.length).toEqual(2)
      done()

  describe 'when creator and allTypes=true', ->
    it 'returns all for creator', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: getURL("/db/prepaid?creator=#{@user.id}&allTypes=true"), json: true})
      expect(body.length).toEqual(4)
      done()

describe 'GET /db/prepaid/:handle/creator', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @creator = yield utils.initUser({role: 'teacher'})
    @joiner = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @creator.id })
    yield utils.loginUser(@creator)
    yield utils.addJoinerToPrepaid(@prepaid, @joiner)
    @url = getURL("/db/prepaid/#{@prepaid.id}/creator")
    done()

  describe 'when the prepaid ID is wrong', ->
    beforeEach utils.wrap (done) ->
      yield utils.loginUser(@creator)
      @url = getURL("/db/prepaid/123456789012345678901234/creator")
      done()

    it 'returns a NotFound error', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(404)
      done()

  describe 'when user is the creator', ->
    beforeEach utils.wrap (done) ->
      yield utils.loginUser(@creator)
      done()

    it 'returns only course and starter_license prepaids for creator', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(200)
      expect(body.email).toEqual(@creator.email)
      expect(body.name).toEqual(@creator.name)
      expect(body.firstName).toEqual(@creator.firstName)
      expect(body.lastName).toEqual(@creator.lastName)
      done()

  describe 'when user is a joiner', ->
    beforeEach utils.wrap (done) ->
      yield utils.loginUser(@joiner)
      done()
      
    it 'returns only course and starter_license prepaids for creator', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(200)
      expect(body.email).toEqual(@creator.email)
      expect(body.name).toEqual(@creator.name)
      expect(body.firstName).toEqual(@creator.firstName)
      expect(body.lastName).toEqual(@creator.lastName)
      done()

  describe 'when user is not a teacher', ->
    beforeEach utils.wrap (done) ->
      @user = yield utils.initUser()
      yield utils.loginUser(@user)
      done()

    it 'returns a Forbidden Error', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(403)
      expect(body.email).toBeUndefined()
      done()

  describe 'when user is neither the creator nor joiner', ->
    beforeEach utils.wrap (done) ->
      @user = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(@user)
      done()

    it 'returns a Forbidden Error', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(403)
      expect(body.email).toBeUndefined()
      done()
      
describe 'GET /db/prepaid/:handle/joiners', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @creator = yield utils.initUser({role: 'teacher'})
    @joiner = yield utils.initUser({role: 'teacher', firstName: 'joiner', lastName: 'one'})
    @joiner2 = yield utils.initUser({role: 'teacher', firstName: 'joiner', lastName: 'two'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @creator.id })
    yield utils.loginUser(@creator)
    yield utils.addJoinerToPrepaid(@prepaid, @joiner)
    yield utils.addJoinerToPrepaid(@prepaid, @joiner2)
    @url = getURL("/db/prepaid/#{@prepaid.id}/joiners")
    done()

  describe 'when user is the creator', ->
    beforeEach utils.wrap (done) ->
      yield utils.loginUser(@creator)
      done()

    it 'returns an array of users', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(200)
      expect(body.length).toBe(2)
      expect(body[0]._id).toEqual(@joiner._id+'')
      expect(_.omit(body[0], '_id')).toEqual(_.pick(@joiner.toObject(), 'name', 'email', 'firstName', 'lastName'))
      expect(_.omit(body[1], '_id')).toEqual(_.pick(@joiner2.toObject(), 'name', 'email', 'firstName', 'lastName'))
      done()

  describe 'when user is not a teacher', ->
    beforeEach utils.wrap (done) ->
      @user = yield utils.initUser()
      yield utils.loginUser(@user)
      done()

    it 'returns a Forbidden Error', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(403)
      expect(body.email).toBeUndefined()
      done()

  describe 'when user is not the creator', ->
    beforeEach utils.wrap (done) ->
      yield utils.loginUser(@joiner)
      done()

    it 'returns a Forbidden Error', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(403)
      expect(body.email).toBeUndefined()
      done()

  describe 'when user is neither the creator nor joiner', ->
    beforeEach utils.wrap (done) ->
      @user = yield utils.initUser({role: 'teacher'})
      yield utils.loginUser(@user)
      done()

    it 'returns a Forbidden Error', utils.wrap (done) ->
      [res, body] = yield request.getAsync({url: @url, json: true})
      expect(res.statusCode).toBe(403)
      expect(body.email).toBeUndefined()
      done()

describe 'GET /db/prepaid/:handle', ->
  it 'populates startDate and endDate with default values', utils.wrap (done) ->
    prepaid = new Prepaid({type: 'course' })
    yield prepaid.save()
    [res, body] = yield request.getAsync({url: getURL("/db/prepaid/#{prepaid.id}"), json: true})
    expect(body.endDate).toBe(Prepaid.DEFAULT_END_DATE)
    expect(body.startDate).toBe(Prepaid.DEFAULT_START_DATE)
    done()

describe 'POST /db/prepaid/:handle/redeemers', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser()
    @url = getURL("/db/prepaid/#{@prepaid.id}/redeemers")
    done()

  it 'adds a given user to the redeemers property', utils.wrap (done) ->
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(1)
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(body._id)
    expect(prepaid.get('redeemers').length).toBe(1)
    @student = yield User.findById(@student.id)
    expect(@student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    expect(@student.get('role')).toBe('student')
    done()

  describe 'when user is a joiner', ->
    beforeEach ->
      @joiner = yield utils.initUser({role: 'teacher', firstName: 'joiner', lastName: 'one'})
      yield utils.loginUser(@admin)
      yield utils.loginUser(@teacher)
      yield utils.addJoinerToPrepaid(@prepaid, @joiner)
      yield utils.loginUser(@joiner)

    it 'adds a given user to the redeemers property', utils.wrap (done) ->
      [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
      expect(body.redeemers.length).toBe(1)
      expect(res.statusCode).toBe(201)
      prepaid = yield Prepaid.findById(body._id)
      expect(prepaid.get('redeemers').length).toBe(1)
      @student = yield User.findById(@student.id)
      expect(@student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
      expect(@student.get('role')).toBe('student')
      done()

  it 'returns 403 if maxRedeemers is reached', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    prepaid = yield utils.makePrepaid({ creator: @teacher.id, maxRedeemers: 0 })
    url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync({uri: url, json: { userID: @student.id } })
    expect(res.statusCode).toBe(403)
    expect(res.body.message).toBe('Too many redeemers')
    done()

  it 'returns 403 unless the user is the "creator" or a joiner', utils.wrap (done) ->
    @otherTeacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@otherTeacher)
    [res, body] = yield request.postAsync({uri: @url, json: { userID: @student.id } })
    expect(res.statusCode).toBe(403)
    expect(res.body.message).toBe('You may not redeem licenses from this prepaid')
    done()

  it 'returns 403 if the prepaid is expired', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    prepaid = yield utils.makePrepaid({ creator: @teacher.id, endDate: moment().subtract(1, 'month').toISOString() })
    url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync({uri: url, json: { userID: @student.id } })
    expect(res.statusCode).toBe(403)
    expect(res.body.message).toBe('This prepaid is expired')
    done()

  it 'is idempotent across prepaids collection', utils.wrap (done) ->
    student = yield utils.initUser({ coursePrepaid: { _id: new Prepaid()._id } })
    [res, body] = yield request.postAsync({uri: @url, json: { userID: student.id } })
    expect(res.statusCode).toBe(200)
    expect(body.redeemers.length).toBe(0)
    done()

  it 'is idempotent to itself', utils.wrap (done) ->
    [res, body] = yield request.postAsync({uri: @url, json: { userID: @student.id } })
    expect(body.redeemers?.length).toBe(1)
    expect(res.statusCode).toBe(201)
    [res, body] = yield request.postAsync({uri: @url, json: { userID: @student.id } })
    expect(body.redeemers?.length).toBe(1)
    expect(res.statusCode).toBe(200)
    prepaid = yield Prepaid.findById(body._id)
    expect(prepaid.get('redeemers').length).toBe(1)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    done()

  it 'updates the user if their license is expired', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    prepaid = yield utils.makePrepaid({
      creator: @teacher.id
      startDate: moment().subtract(2, 'month').toISOString()
      endDate: moment().subtract(1, 'month').toISOString()
    })
    @student.set('coursePrepaid', _.pick(prepaid.toObject(), '_id', 'startDate', 'endDate'))
    yield @student.save()
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(1)
    expect(res.statusCode).toBe(201)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    done()

  it 'replaces a starter license with a full license', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    oldPrepaid = yield utils.makePrepaid({
      creator: @teacher.id
      startDate: moment().subtract(2, 'month').toISOString()
      endDate: moment().add(4, 'month').toISOString()
      type: 'starter_license'
    })
    @student.set('coursePrepaid', _.pick(oldPrepaid.toObject(), '_id', 'startDate', 'endDate', 'type'))
    yield @student.save()
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(1)
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(@prepaid._id)
    expect(prepaid.get('redeemers').length).toBe(1)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    done()

  it 'does NOT replace a full license with a starter license', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    @prepaid.set({
      creator: @teacher.id
      startDate: moment().subtract(2, 'month').toISOString()
      endDate: moment().add(4, 'month').toISOString()
      type: 'starter_license'
    })
    yield @prepaid.save()
    oldPrepaid = yield utils.makePrepaid({
      creator: @teacher.id
      startDate: moment().subtract(2, 'month').toISOString()
      endDate: moment().add(10, 'month').toISOString()
      type: 'course'
    })
    yield oldPrepaid.redeem(@student)
    yield utils.loginUser(@teacher)

    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(oldPrepaid._id)).toBe(true)
    expect(student.get('coursePrepaid')._id.toString()).toBe(oldPrepaid._id.toString())

    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(0)
    expect(res.statusCode).toBe(200)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(oldPrepaid._id)).toBe(true)
    expect(student.get('coursePrepaid')._id.toString()).toBe(oldPrepaid._id.toString())
    expect((yield Prepaid.findById(oldPrepaid._id)).get('redeemers').length).toBe(1)
    done()

  it 'adds includedCourseIDs to the user when redeeming', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    @prepaid.set({
      type: 'starter_license'
      includedCourseIDs: ['course_1', 'course_2']
    })
    yield @prepaid.save()
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync { uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(1)
    expect(res.statusCode).toBe(201)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')?.includedCourseIDs).toEqual(['course_1', 'course_2'])
    expect(student.get('coursePrepaid')?.type).toEqual('starter_license')
    done()

  describe 'when user is a joiner on a shared license', ->
    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
      @creator = yield utils.initUser({role: 'teacher'})
      @joiner = yield utils.initUser({role: 'teacher'})
      @admin = yield utils.initAdmin()
      yield utils.loginUser(@admin)
      @prepaid = yield utils.makePrepaid({ creator: @creator.id })
      yield utils.loginUser(@creator)
      yield utils.addJoinerToPrepaid(@prepaid, @joiner)
      yield utils.loginUser(@joiner)
      @student = yield utils.initUser()
      @url = getURL("/db/prepaid/#{@prepaid.id}/redeemers")
      done()
    
    it 'allows teachers with shared licenses to redeem', utils.wrap (done) ->
      prepaid = yield Prepaid.findById(@prepaid.id)
      expect(prepaid.get('redeemers').length).toBe(0)
      [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
      expect(body.redeemers.length).toBe(1)
      expect(res.statusCode).toBe(201)
      prepaid = yield Prepaid.findById(body._id)
      expect(prepaid.get('redeemers').length).toBe(1)
      @student = yield User.findById(@student.id)
      expect(@student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
      expect(@student.get('role')).toBe('student')
      done()

describe 'DELETE /db/prepaid/:handle/redeemers', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser()
    @url = getURL("/db/prepaid/#{@prepaid.id}/redeemers")
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(res.statusCode).toBe(201)
    done()

  it 'removes a given user to the redeemers property', utils.wrap (done) ->
    prepaid = yield Prepaid.findById(@prepaid.id)
    expect(prepaid.get('redeemers').length).toBe(1)
    [res, body] = yield request.delAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(0)
    expect(res.statusCode).toBe(200)
    prepaid = yield Prepaid.findById(body._id)
    expect(prepaid.get('redeemers').length).toBe(0)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')).toBeUndefined()
    done()

  it 'returns 403 unless the user is the "creator"', utils.wrap (done) ->
    otherTeacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(otherTeacher)
    [res, body] = yield request.delAsync {uri: @url, json: { userID: @student.id } }
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 422 unless the target user is in "redeemers"', utils.wrap (done) ->
    otherStudent = yield utils.initUser({role: 'student'})
    [res, body] = yield request.delAsync {uri: @url, json: { userID: otherStudent.id } }
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 403 if the prepaid is a starter license', utils.wrap ->
    yield @prepaid.update({$set: {type: 'starter_license'}})
    [res, body] = yield request.delAsync {uri: @url, json: { userID: @student.id } }
    expect(res.statusCode).toBe(403)

  describe 'when user is a joiner on a shared license', ->
    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
      @creator = yield utils.initUser({role: 'teacher'})
      @joiner = yield utils.initUser({role: 'teacher'})
      @admin = yield utils.initAdmin()
      yield utils.loginUser(@admin)
      @prepaid = yield utils.makePrepaid({ creator: @creator.id })
      yield utils.loginUser(@creator)
      yield utils.addJoinerToPrepaid(@prepaid, @joiner)
      yield utils.loginUser(@joiner)
      @student = yield utils.initUser()
      @url = getURL("/db/prepaid/#{@prepaid.id}/redeemers")
      [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
      expect(res.statusCode).toBe(201)
      done()

    it 'allows teachers with shared licenses to revoke', utils.wrap (done) ->
      prepaid = yield Prepaid.findById(@prepaid.id)
      expect(prepaid.get('redeemers').length).toBe(1)
      [res, body] = yield request.delAsync {uri: @url, json: { userID: @student.id } }
      expect(body.redeemers.length).toBe(0)
      expect(res.statusCode).toBe(200)
      prepaid = yield Prepaid.findById(body._id)
      expect(prepaid.get('redeemers').length).toBe(0)
      student = yield User.findById(@student.id)
      expect(student.get('coursePrepaid')).toBeUndefined()
      done()

describe 'POST /db/prepaid/:handle/joiners', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield utils.loginUser(@teacher)
    @joiner = yield utils.initUser({role: 'teacher'})
    @url = getURL("/db/prepaid/#{@prepaid.id}/joiners")
    done()

  it 'adds a given user to the joiners property', utils.wrap (done) ->
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @joiner.id } }
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(body._id)
    expect(prepaid.get('joiners').length).toBe(1)
    expect(prepaid.get('joiners')[0].userID + '').toBe(@joiner.id)
    done()
  
  describe 'when a user has already been added to joiners', ->
    it "doesn't add a user twice", utils.wrap (done) ->
      [res, body] = yield request.postAsync {uri: @url, json: { userID: @joiner.id } }
      expect(res.statusCode).toBe(201)
      [res, body] = yield request.postAsync {uri: @url, json: { userID: @joiner.id } }
      expect(res.statusCode).toBe(422)
      expect(body.i18n).toBe('share_licenses.already_shared')
      prepaid = yield Prepaid.findById(@prepaid.id)
      expect(prepaid.get('joiners').length).toBe(1)
      expect(prepaid.get('joiners')[0].userID + '').toBe(@joiner.id)
      done()

  it 'returns 403 if user is not the creator', utils.wrap (done) ->
    yield utils.loginUser(@joiner)
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @joiner.id } }
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 403 if user is not a teacher', utils.wrap (done) ->
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @joiner.id } }
    expect(res.statusCode).toBe(403)
    done()

  it 'returns 422 if joiner is not a teacher', utils.wrap (done) ->
    @nonteacher = yield utils.initUser()
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @nonteacher.id } }
    expect(res.statusCode).toBe(422)
    done()

  it 'returns 404 if prepaid is not found', utils.wrap (done) ->
    @url = getURL("/db/prepaid/123456789012345678901234/joiners")
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @joiner.id } }
    expect(res.statusCode).toBe(404)
    done()

describe 'GET /db/prepaid?creator=:id', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    @otherPrepaid = yield utils.makePrepaid({ creator: @admin.id })
    @expiredPrepaid = yield utils.makePrepaid({ creator: @teacher.id, endDate: moment().subtract(1, 'month').toISOString() })
    @unmigratedPrepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield @unmigratedPrepaid.update({$unset: { endDate: '', startDate: '' }})
    yield utils.loginUser(@teacher)
    done()

  it 'return all prepaids for the creator', utils.wrap (done) ->
    url = getURL("/db/prepaid?creator=#{@teacher.id}")
    [res, body] = yield request.getAsync({uri: url, json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toEqual(3)
    if _.any((prepaid._id is @otherPrepaid.id for prepaid in res.body))
      fail('Found the admin prepaid in response')
    for prepaid in res.body
      unless prepaid.startDate and prepaid.endDate
        fail('All prepaids should have start and end dates')
    expect(res.body[0]._id).toBe(@prepaid.id)
    done()

  it 'returns 403 if the user tries to view another user\'s prepaids', utils.wrap (done) ->
    anotherUser = yield utils.initUser()
    url = getURL("/db/prepaid?creator=#{anotherUser.id}")
    [res, body] = yield request.getAsync({uri: url, json: true})
    expect(res.statusCode).toBe(403)
    done()

  describe 'when includeShared is set to true', ->
    beforeEach utils.wrap (done) ->
      yield utils.loginUser(@admin)
      @joiner = yield utils.initUser({role: 'teacher'})
      @joinersPrepaid = yield utils.makePrepaid({ creator: @joiner.id })
      yield @prepaid.update({$set: { joiners: { userID: @joiner._id }}})
      yield utils.loginUser(@joiner)
      done()

    it 'returns licenses that have been shared with the user', utils.wrap (done) ->
      url = getURL("/db/prepaid?creator=#{@joiner.id}&includeShared=true")
      [res, body] = yield request.getAsync({uri: url, json: true})
      expect(res.statusCode).toBe(200)
      expect(res.body.length).toEqual(2)
      if _.any((prepaid._id is @otherPrepaid.id for prepaid in res.body))
        fail('Found the admin prepaid in response')
      for prepaid in res.body
        unless prepaid.startDate and prepaid.endDate
          fail('All prepaids should have start and end dates')
      expect(res.body[0]._id).toBe(@prepaid.id)
      done()

describe '/db/prepaid', ->
  beforeEach utils.wrap (done) ->
    yield utils.populateProducts()
    done()

  prepaidURL = getURL('/db/prepaid')

  headers = {'X-Change-Plan': 'true'}

  joeData = null
  stripe = require('stripe')(config.stripe.secretKey)
  joeCode = null

  verifyCoursePrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('course')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    return done() if user.isAdmin()
    Payment.findOne {prepaidID: new ObjectId(prepaid._id)}, (err, payment) ->
      expect(err).toBeNull()
      expect(payment).not.toBeNull()
      expect(payment?.get('purchaser')).toEqual(user._id)
      done()

  verifySubscriptionPrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('subscription')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    expect(prepaid.properties?.couponID).toEqual('free')
    return done() if user.isAdmin()
    Payment.findOne {prepaidID: new ObjectId(prepaid._id)}, (err, payment) ->
      expect(err).toBeNull()
      expect(payment).not.toBeNull()
      expect(payment?.get('purchaser')).toEqual(user._id)
      done()

  it 'Clear database', (done) ->
    clearModels [Course, CourseInstance, Payment, Prepaid, User], (err) ->
      throw err if err
      done()

  it 'Anonymous creates prepaid code', (done) ->
    createPrepaid 'subscription', 1, 0, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(401)
      done()

  it 'Non-admin creates prepaid code', (done) ->
    loginNewUser (user1) ->
      expect(user1.isAdmin()).toEqual(false)
      createPrepaid 'subscription', 4, 0, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Admin creates prepaid code with type subscription', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 1, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          verifySubscriptionPrepaid user1, body, done

  it 'Admin creates prepaid code with type terminal_subscription', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'terminal_subscription', 2, 3, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          expect(body.creator).toEqual(user1.id)
          expect(body.type).toEqual('terminal_subscription')
          expect(body.maxRedeemers).toEqual(2)
          expect(body.properties?.months).toEqual(3)
          expect(body.code).toMatch(/^\w{8}$/)
          done()


  it 'Admin creates prepaid code with invalid type', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'bulldozer', 1, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Admin creates prepaid code with no type specified', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid null, 1, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Admin creates prepaid code with invalid maxRedeemers', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 0, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Non-admin requests /db/prepaid', (done) ->
    loginNewUser (user1) ->
      expect(user1.isAdmin()).toEqual(false)
      request.get {uri: prepaidURL}, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Admin requests /db/prepaid', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          request.get {uri: prepaidURL}, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            prepaids = JSON.parse(body)
            found = false
            for p in prepaids
              if p._id is prepaid._id
                found = true
                verifySubscriptionPrepaid user1, p, done
                break
            expect(found).toEqual(true)
            done() unless found

  describe 'Purchase course', ->
    afterEach nockUtils.teardownNock

    it 'Standard user purchases a prepaid for 0 seats', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-course-test-1.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'course', {}, 0, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Standard user purchases a prepaid for 1 seat', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-course-test-2.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'course', {}, 1, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              verifyCoursePrepaid user1, prepaid, ->
                nockDone()
                done()

    it 'Standard user purchases a prepaid for 3 seats', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-course-test-3.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'course', {}, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              verifyCoursePrepaid user1, prepaid, ->
                nockDone()
                done()

  describe 'Purchase terminal_subscription', ->
    afterEach nockUtils.teardownNock

    it 'Anonymous submits a prepaid purchase', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-1.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          logoutUser () ->
            purchasePrepaid 'terminal_subscription', months: 3, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(401)
              nockDone()
              done()

    it 'Should error if type isnt terminal_subscription', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-2.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'subscription', months: 3, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(403)
              nockDone()
              done()

    it 'Should error if maxRedeemers is -1', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-3.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 3, -1, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if maxRedeemers is foo', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-4.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 3, 'foo', token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if months is -1', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-5.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: -1, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if months is foo', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-6.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 'foo', 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if maxRedeemers and months are less than 3', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-7.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 1, 1, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(403)
              nockDone()
              done()

    it 'User submits valid prepaid code purchase', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-8.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          stripeTokenID = token.id
          loginJoe (joe) ->
            joeData = joe.toObject()
            joeData.stripe = {
              token: stripeTokenID
              planID: 'basic'
            }
            request.put {uri: getURL('/db/user'), json: joeData, headers: headers }, (err, res, body) ->
              joeData = body
              expect(res.statusCode).toBe(200)
              expect(joeData.stripe.customerID).toBeDefined()
              expect(firstSubscriptionID = joeData.stripe.subscriptionID).toBeDefined()
              expect(joeData.stripe.planID).toBe('basic')
              expect(joeData.stripe.token).toBeUndefined()
              # TODO: is this test still valid after new token?
              stripe.tokens.create {
                card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
              }, (err, token) ->
                purchasePrepaid 'terminal_subscription', months: 3, 3, token.id, (err, res, prepaid) ->
                  expect(err).toBeNull()
                  expect(res.statusCode).toBe(200)
                  expect(prepaid.type).toEqual('terminal_subscription')
                  expect(prepaid.code).toBeDefined()
                  # Saving this code for later tests
                  # TODO: don't make tests dependent on each other
                  joeCode = prepaid.code
                  expect(prepaid.creator).toBeDefined()
                  expect(prepaid.maxRedeemers).toEqual(3)
                  expect(prepaid.exhausted).toBe(false)
                  expect(prepaid.properties).toBeDefined()
                  expect(prepaid.properties.months).toEqual(3)
                  nockDone()
                  done()

    it 'Should have logged a Payment with the correct amount', (done) ->
      loginJoe (joe) ->
        query =
          purchaser: joe._id
        Payment.find query, (err, payments) ->
          expect(err).toBeNull()
          expect(payments).not.toBeNull()
          expect(payments.length).toEqual(1)
          expect(payments[0].get('amount')).toEqual(900)
          done()

    it 'Anonymous cant redeem a prepaid code', (done) ->
      logoutUser () ->
        subscribeWithPrepaid joeCode, (err, res) ->
          expect(err).toBeNull()
          expect(res?.statusCode).toEqual(401)
          done()

    it 'User cant redeem a nonexistant prepaid code', (done) ->
      loginJoe (joe) ->
        subscribeWithPrepaid 'abc123', (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(404)
          done()

    it 'User cant redeem empty code', (done) ->
      loginJoe (joe) ->
        subscribeWithPrepaid '', (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(422)
          done()

    it 'Anonymous cant fetch a prepaid code', (done) ->
      expect(joeCode).not.toBeNull()
      logoutUser () ->
        fetchPrepaid joeCode, (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(403)
          done()

    it 'User can fetch a prepaid code', (done) ->
      expect(joeCode).not.toBeNull()
      loginJoe (joe) ->
        fetchPrepaid joeCode, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(200)

          expect(body).toBeDefined()
          return done() unless body

          prepaid = JSON.parse(body)
          expect(prepaid.code).toEqual(joeCode)
          expect(prepaid.maxRedeemers).toEqual(3)
          expect(prepaid.properties?.months).toEqual(3)
          done()

  # TODO: Move redeem subscription prepaid code tests to subscription tests file
  describe 'Subscription redeem tests', ->
    afterEach nockUtils.teardownNock

    it 'Creator can redeeem a prepaid code', (done) ->
      nockUtils.setupNock 'db-sub-redeem-test-1.json', (err, nockDone) ->
        loginJoe (joe) ->
          expect(joeCode).not.toBeNull()
          expect(joeData.stripe?.customerID).toBeDefined()
          expect(joeData.stripe?.subscriptionID).toBeDefined()
          return done() unless joeData.stripe?.customerID

          # joe has a stripe subscription, so test if the months are added to the end of it.
          stripe.customers.retrieve joeData.stripe.customerID, (err, customer) =>
            expect(err).toBeNull()

            findStripeSubscription customer.id, subscriptionID: joeData.stripe?.subscriptionID, (err, subscription) =>
              if subscription
                stripeSubscriptionPeriodEndDate = new moment(subscription.current_period_end * 1000)
              else
                expect(stripeSubscriptionPeriodEndDate).toBeDefined()
                return done()

              subscribeWithPrepaid joeCode, (err, res, result) =>
                expect(err).toBeNull()
                expect(res.statusCode).toEqual(200)
                endDate = stripeSubscriptionPeriodEndDate.add(3, 'months').toISOString().substring(0, 10)
                expect(result?.stripe?.free.substring(0,10)).toEqual(endDate)
                expect(result?.purchased?.gems).toEqual(14000)
                findStripeSubscription customer.id, subscriptionID: joeData.stripe?.subscriptionID, (err, subscription) =>
                  expect(subscription).toBeNull()
                  nockDone()
                  done()

    it 'User can redeem a prepaid code', (done) ->
      loginSam (sam) ->
        subscribeWithPrepaid joeCode, (err, res, result) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(200)
          endDate = new moment().add(3, 'months').toISOString().substring(0, 10)
          expect(result?.stripe?.free.substring(0,10)).toEqual(endDate)
          expect(result?.purchased?.gems).toEqual(10500)
          done()

    it 'Wont allow the same person to redeem twice', (done) ->
      loginSam (sam) ->
        subscribeWithPrepaid joeCode, (err, res, result) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(403)
          done()

    it 'Will return redeemed code as part of codes list', (done) ->
      loginSam (sam) ->
        request.get "#{getURL('/db/user')}/#{sam.id}/prepaid_codes", (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(200)
          codes = JSON.parse res.body
          expect(codes.length).toEqual(1)
          done()

    it 'Third user can redeem a prepaid code', (done) ->
      loginNewUser (user) ->
        subscribeWithPrepaid joeCode, (err, res, result) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(200)
          endDate = new moment().add(3, 'months').toISOString().substring(0, 10)
          expect(result?.stripe?.free.substring(0,10)).toEqual(endDate)
          expect(result?.purchased?.gems).toEqual(10500)
          done()

    it 'Fourth user cannot redeem code', (done) ->
      loginNewUser (user) ->
        subscribeWithPrepaid joeCode, (err, res, result) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(403)
          done()

    it 'Can fetch a list of purchased and redeemed prepaid codes', (done) ->
      nockUtils.setupNock 'db-sub-redeem-test-2.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user) ->
            purchasePrepaid 'terminal_subscription', months: 1, 3, token.id, (err, res, prepaid) ->
              request.get "#{getURL('/db/user')}/#{user.id}/prepaid_codes", (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toEqual(200);
                codes = JSON.parse res.body
                expect(codes.length).toEqual(1)
                expect(codes[0].maxRedeemers).toEqual(3)
                expect(codes[0].properties).toBeDefined()
                expect(codes[0].properties.months).toEqual(1)
                nockDone()
                done()

    it 'thwarts query injections', utils.wrap (done) ->
      user = yield utils.initUser()
      yield utils.loginUser(user)
      code = { $exists: true }
      subscribeWithPrepaidAsync = Promise.promisify(subscribeWithPrepaid)
      res = yield subscribeWithPrepaidAsync(code)
      expect(res.statusCode).toBe(422)
      expect(res.body.message).toBe('You must provide a valid prepaid code.')
      done()

    it 'enforces the maximum number of redeemers in a race condition', utils.wrap (done) ->
      nockDone = yield nockUtils.setupNockAsync 'db-sub-redeem-test-3.json'
      stripe.tokens.createAsync = Promise.promisify(stripe.tokens.create, {context: stripe.tokens})
      token = yield stripe.tokens.createAsync({
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      })

      user = yield utils.initUser()
      yield utils.loginUser(user)

      codeRedeemers = 50
      codeMonths = 3
      redeemers = 51

      purchasePrepaidAsync = Promise.promisify(purchasePrepaid, {multiArgs: true})
      [res, prepaid] = yield purchasePrepaidAsync('terminal_subscription', months: codeMonths, codeRedeemers, token.id)

      expect(prepaid).toBeDefined()
      expect(prepaid.code).toBeDefined()

      # Make 'threads', which are objects that encapsulate each user and their cookies
      threads = []
      for index in [0...redeemers]
        thread = {}
        thread.request = request.defaults({jar: request.jar()})
        thread.request.postAsync = Promise.promisify(thread.request.post, { context: thread.request })
        thread.user = yield utils.initUser()
        yield utils.loginUser(thread.user, {request: thread.request})
        threads.push(thread)

      # Spawn all requests at once!
      requests = []
      options = {
        url: getURL('/db/subscription/-/subscribe_prepaid')
        json: { ppc: prepaid.code }
      }
      for thread in threads
        requests.push(thread.request.postAsync(options))

      # Wait until all requests finish, make sure all but one succeeded
      responses = yield requests
      redeemed = _.size(_.where(responses, {statusCode: 200}))
      errors = _.size(_.where(responses, {statusCode: 403}))
      expect(redeemed).toEqual(codeRedeemers)
      expect(errors).toEqual(redeemers - codeRedeemers)
      nockDone()
      done()
