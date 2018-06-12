require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
User = require '../../../server/models/User'
TrialRequest = require '../../../server/models/TrialRequest'
Prepaid = require '../../../server/models/Prepaid'
Classroom = require '../../../server/models/Classroom'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
Campaign = require '../../../server/models/Campaign'
LevelSession = require '../../../server/models/LevelSession'
Level = require '../../../server/models/Level'
request = require '../request'
delighted = require '../../../server/delighted'
co = require 'co'

trialRequestFixture = {
  type: 'course'
  properties:
    location: 'SF, CA'
    age: '14-17'
    numStudents: 14
    heardAbout: 'magical interwebs'
    firstName: 'First'
    lastName: 'Last'
}

setupTeacher = co.wrap (trialRequestData) ->
  fixture = _.cloneDeep(trialRequestData)
  user = yield utils.initUser({gender: 'male', lastLevel: 'abcd', preferredLanguage: 'en', testGroupNumber: 1, role: 'teacher'})
  yield utils.loginUser(user)
  fixture.properties.email ?= user.get('email')
  fixture.properties.country ?= 'USA'
  fixture.type ?= 'course'
  [res, body] = yield request.postAsync(getURL('/db/trial.request'), { json: fixture })
  expect(delighted.postPeople).not.toHaveBeenCalled()
  user

makeClassroom = co.wrap (user, name) ->
  data = { name: name }
  [res, body] = yield request.postAsync {uri: getURL('/db/classroom'), json: data }
  expect(res.statusCode).toBe(201)
  expect(res.body.name).toBe(name)
  expect(res.body.members.length).toBe(0)
  expect(res.body.ownerID).toBe(user.id)

describe 'delighted', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User, TrialRequest, User, Classroom, Course, Level, Campaign])
    
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    
    campaignJSON = { name: 'Campaign', levels: {} }

    [res, body] = yield request.postAsync({uri: getURL('/db/campaign'), json: campaignJSON})
    @campaign = yield Campaign.findById(res.body._id)
    @course = Course({name: 'Course', campaignID: @campaign._id, releasePhase: 'released'})
    yield @course.save()

    spyOn(delighted, 'postPeople')

  it 'no longer creates a profile trial creation', utils.wrap ->
    @user = yield setupTeacher trialRequestFixture


  it 'creates a profile when the first class is created, to email 18 days after', utils.wrap ->
    @user = yield setupTeacher trialRequestFixture

    # Add class one
    yield makeClassroom @user, "Classroom 1"
    expect(delighted.postPeople).toHaveBeenCalled()
    delightedProps = delighted.postPeople.calls.first().args[0]
    
    expect(delightedProps.delay).toBe(3600 * 24 * 18)
    expect(delightedProps.properties.status).toBe('engaged')

    # Add reset
    delighted.postPeople.calls.reset()

    #Add class two
    yield makeClassroom @user, "Classroom 2"
    expect(delighted.postPeople).not.toHaveBeenCalled()

  it 'does not create a profile in Germany', utils.wrap ->
    fixture = _.cloneDeep(trialRequestFixture)
    fixture.properties.country = 'Germany'
    @user = yield setupTeacher fixture
    yield makeClassroom @user, "Classroom 1"
    expect(delighted.postPeople).not.toHaveBeenCalled()

  it 'creates a profile when the first course prepaid is added, to email 7 days after', utils.wrap ->
    @user = yield setupTeacher trialRequestFixture
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: @user.id
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('creator').equals(@user._id)).toBe(true)
    expect(prepaid.get('code')).toBeDefined()
    
    expect(delighted.postPeople).toHaveBeenCalled()
    delightedProps = delighted.postPeople.calls.first().args[0]
    expect(delightedProps.delay).toBe(3600 * 24 * 7)
    expect(delightedProps.properties.status).toBe('paid full')

    delighted.postPeople.calls.reset()

    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: @user.id
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('creator').equals(@user._id)).toBe(true)
    expect(prepaid.get('code')).toBeDefined()
    
    expect(delighted.postPeople).not.toHaveBeenCalled()

  it 'creates a profile when the first starter prepaid is added, to email 7 days after', utils.wrap ->
    @user = yield setupTeacher trialRequestFixture
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)

    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'starter_license'
      creator: @user.id
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('creator').equals(@user._id)).toBe(true)
    expect(prepaid.get('code')).toBeDefined()
    
    expect(delighted.postPeople).toHaveBeenCalled()
    delightedProps = delighted.postPeople.calls.first().args[0]
    expect(delightedProps.delay).toBe(3600 * 24 * 7)
    expect(delightedProps.properties.status).toBe('paid starter')

    delighted.postPeople.calls.reset()

    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'starter_license'
      creator: @user.id
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('creator').equals(@user._id)).toBe(true)
    expect(prepaid.get('code')).toBeDefined()
    
    expect(delighted.postPeople).not.toHaveBeenCalled()

  describe 'if the user is unsubscribed from all emails', ->
    it 'does not create a profile when the first class is created', utils.wrap ->
      @user = yield setupTeacher trialRequestFixture
      @user.set('unsubscribedFromMarketingEmails', true)
      yield @user.save()
      yield makeClassroom @user, "Classroom 1"
      expect(delighted.postPeople).not.toHaveBeenCalled()

    it 'does not create a profile when the first course prepaid is added', utils.wrap ->
      @user = yield setupTeacher trialRequestFixture
      @user.set('unsubscribedFromMarketingEmails', true)
      yield @user.save()
      admin = yield utils.initAdmin()
      yield utils.loginUser(admin)

      [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
        type: 'course'
        creator: @user.id
      }})
      expect(res.statusCode).toBe(201)
      expect(delighted.postPeople).not.toHaveBeenCalled()

    it 'does not create a profile when the first starter prepaid is added', utils.wrap ->
      @user = yield setupTeacher trialRequestFixture
      @user.set('unsubscribedFromMarketingEmails', true)
      yield @user.save()
      admin = yield utils.initAdmin()
      yield utils.loginUser(admin)
  
      [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
        type: 'starter_license'
        creator: @user.id
      }})
      expect(res.statusCode).toBe(201)
      expect(delighted.postPeople).not.toHaveBeenCalled()
