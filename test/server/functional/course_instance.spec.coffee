async = require 'async'
config = require '../../../server_config'
require '../common'
stripe = require('stripe')(config.stripe.secretKey)

# TODO: add permissiosn tests

describe 'CourseInstance', ->
  courseInstanceURL = getURL('/db/course_instance/-/create')
  userURL = getURL('/db/user')

  nameCount = 0
  createName = (name) -> name + nameCount++

  createCourse = (pricePerSeat, done) ->
    name = createName 'course '
    course = new Course
      name: name
      campaignID: ObjectId("55b29efd1cd6abe8ce07db0d")
      concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables']
      description: "Learn basic syntax, while loops, and the CodeCombat environment."
      pricePerSeat: pricePerSeat
      screenshot: "/images/pages/courses/101_info.png"
    course.save (err, course) ->
      return done(err) if err
      done(err, course)

  createCourseInstances = (user, courseID, seats, token, done) ->
    name = createName 'course instance '
    requestBody =
      courseID: courseID
      name: name
      seats: seats
      token: token
    request.post {uri: courseInstanceURL, json: requestBody }, (err, res) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(201)
      CourseInstance.find {name: name}, (err, courseInstances) ->
        expect(err).toBeNull()

        makeCourseInstanceVerifyFn = (courseInstance) ->
          (done) ->
            expect(courseInstance.get('name')).toEqual(name)
            expect(courseInstance.get('ownerID')).toEqual(user.get('_id'))
            expect(courseInstance.get('members')).toContain(user.get('_id'))
            query = {$and: [{creator: user.get('_id')}]}
            query.$and.push {'properties.courseIDs': {$in: [courseID]}} if courseID
            Prepaid.find query, (err, prepaids) ->
              expect(err).toBeNull()
              return done(err) if err
              expect(prepaids?.length).toEqual(1)
              return done() unless prepaids?.length > 0
              expect(prepaids[0].get('type')).toEqual('course')
              expect(prepaids[0].get('maxRedeemers')).toEqual(seats) if seats

              # TODO: verify Payment

              done(err)

        tasks = []
        for courseInstance in courseInstances
          tasks.push makeCourseInstanceVerifyFn(courseInstance)
        async.parallel tasks, (err) =>
          return done(err) if err
          done(err, courseInstances)

  it 'Clear database users and clans', (done) ->
    clearModels [User, Course, CourseInstance, Prepaid], (err) ->
      throw err if err
      done()

  describe 'Single courses', ->
    it 'Create for free course 1 seat', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 0, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            createCourseInstances user1, course.get('_id'), 1, token.id, (err, courseInstances) ->
              expect(err).toBeNull()
              return done(err) if err
              expect(courseInstances.length).toEqual(1)
              done()

    it 'Create for free course no seats', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 0, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            name = createName 'course instance '
            requestBody =
              courseID: course.get('_id')
              name: createName('course instance ')
            request.post {uri: courseInstanceURL, json: requestBody }, (err, res) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              done()

    it 'Create for free course no token', (done) ->
      loginNewUser (user1) ->
        createCourse 0, (err, course) ->
          expect(err).toBeNull()
          return done(err) if err
          createCourseInstances user1, course.get('_id'), 2, null, (err, courseInstances) ->
            expect(err).toBeNull()
            return done(err) if err
            expect(courseInstances.length).toEqual(1)
            done()

    it 'Create for paid course 1 seat', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 7000, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            createCourseInstances user1, course.get('_id'), 1, token.id, (err, courseInstances) ->
              expect(err).toBeNull()
              return done(err) if err
              expect(courseInstances.length).toEqual(1)
              done()

    it 'Create for paid course 50 seats', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 7000, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            createCourseInstances user1, course.get('_id'), 50, token.id, (err, courseInstances) ->
              expect(err).toBeNull()
              return done(err) if err
              expect(courseInstances.length).toEqual(1)
              done()

    it 'Create for paid course no token', (done) ->
      loginNewUser (user1) ->
        createCourse 7000, (err, course) ->
          expect(err).toBeNull()
          return done(err) if err
          name = createName 'course instance '
          requestBody =
            courseID: course.get('_id')
            name: createName('course instance ')
            seats: 1
          request.post {uri: courseInstanceURL, json: requestBody }, (err, res) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(422)
            done()

    it 'Create for paid course -1 seats', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 7000, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            name = createName 'course instance '
            requestBody =
              courseID: course.get('_id')
              name: createName('course instance ')
              seats: -1
            request.post {uri: courseInstanceURL, json: requestBody }, (err, res) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              done()

  describe 'All Courses', ->
    it 'Create for 50 seats', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 7000, (err, course1) ->
            expect(err).toBeNull()
            return done(err) if err
            createCourse 7000, (err, course2) ->
              expect(err).toBeNull()
              return done(err) if err
              createCourseInstances user1, null, 50, token.id, (err, courseInstances) ->
                expect(err).toBeNull()
                return done(err) if err
                Course.find {}, (err, courses) ->
                  expect(err).toBeNull()
                  return done(err) if err
                  expect(courseInstances.length).toEqual(courses.length)
                  done()
