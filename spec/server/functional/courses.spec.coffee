require '../common'
utils = require '../utils'
_ = require 'lodash'
Promise = require 'bluebird'
request = require '../request'
requestAsync = Promise.promisify(request, {multiArgs: true})
Course = require '../../../server/models/Course'
User = require '../../../server/models/User'

describe 'GET /db/course', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, User])
    yield new Course({ name: 'Course 1' }).save()
    yield new Course({ name: 'Course 2' }).save()
    done()


  it 'returns an array of Course objects', utils.wrap (done) ->
    [res, body] = yield request.getAsync { uri: getURL('/db/course'), json: true }
    expect(body.length).toBe(2)
    done()

describe 'GET /db/course/:handle', ->

  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, User])
    @course = yield new Course({ name: 'Some Name' }).save()
    done()


  it 'returns Course by id', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/course/#{@course.id}"), json: true}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@course.id)
    done()


  it 'returns Course by slug', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/course/some-name"), json: true}
    expect(res.statusCode).toBe(200)
    expect(body._id).toBe(@course.id)
    done()


  it 'returns not found if handle does not exist in the db', utils.wrap (done) ->
    [res, body] = yield request.getAsync {uri: getURL("/db/course/dne"), json: true}
    expect(res.statusCode).toBe(404)
    done()
