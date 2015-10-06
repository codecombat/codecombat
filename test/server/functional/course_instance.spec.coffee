async = require 'async'
config = require '../../../server_config'
require '../common'
stripe = require('stripe')(config.stripe.secretKey)

# TODO: add permissiosn tests

describe 'CourseInstance', ->
  courseInstanceCreateURL = getURL('/db/course_instance/-/create')
  courseInstanceRedeemURL = getURL('/db/course_instance/-/redeem_prepaid')
  userURL = getURL('/db/user')

  createCourseInstances = (user, courseID, seats, token, done) ->
    name = createName 'course instance '
    requestBody =
      courseID: courseID
      name: name
      seats: seats
      stripe:
        token: token
    request.post {uri: courseInstanceCreateURL, json: requestBody }, (err, res) ->
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

  it 'Clear database', (done) ->
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
            request.post {uri: courseInstanceCreateURL, json: requestBody }, (err, res) ->
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
              Prepaid.findById courseInstances[0].get('prepaidID'), (err, prepaid) ->
                expect(err).toBeNull()
                return done(err) if err
                expect(prepaid.get('maxRedeemers')).toEqual(1)
                expect(prepaid.get('properties')?.courseIDs).toEqual([course.get('_id')])
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
              Prepaid.findById courseInstances[0].get('prepaidID'), (err, prepaid) ->
                expect(err).toBeNull()
                return done(err) if err
                expect(prepaid.get('maxRedeemers')).toEqual(50)
                expect(prepaid.get('properties')?.courseIDs).toEqual([course.get('_id')])
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
          request.post {uri: courseInstanceCreateURL, json: requestBody }, (err, res) ->
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
            request.post {uri: courseInstanceCreateURL, json: requestBody }, (err, res) ->
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
                  Prepaid.find creator: user1.get('_id'), (err, prepaids) ->
                    expect(err).toBeNull()
                    return done(err) if err
                    expect(prepaids.length).toEqual(1)
                    return done('no prepaids found') unless prepaids?.length > 0
                    prepaid = prepaids[0]
                    expect(prepaid.get('maxRedeemers')).toEqual(50)
                    expect(prepaid.get('properties')?.courseIDs?.length).toEqual(courses.length)
                    done()

  describe 'Invite to course', ->
    it 'takes a list of emails and sends invites', (done) ->
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
              inviteStudentsURL = getURL("/db/course_instance/#{courseInstances[0]._id}/invite_students")
              requestBody = {
                emails: ['test@test.com']
              }
              request.post { uri: inviteStudentsURL, json: requestBody }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                done()

  describe 'Redeem prepaid code', ->

    it 'Redeem prepaid code an instance of max 2', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        loginNewUser (user1) ->
          createCourse 0, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            createCourseInstances user1, course.get('_id'), 2, token.id, (err, courseInstances) ->
              expect(err).toBeNull()
              return done(err) if err
              expect(courseInstances.length).toEqual(1)
              Prepaid.findById courseInstances[0].get('prepaidID'), (err, prepaid) ->
                expect(err).toBeNull()
                return done(err) if err
                loginNewUser (user2) ->
                  request.post {uri: courseInstanceRedeemURL, json: {prepaidCode: prepaid.get('code')} }, (err, res) ->
                    expect(err).toBeNull()
                    expect(res.statusCode).toBe(200)

                    # Check prepaid
                    Prepaid.findById prepaid.id, (err, prepaid) ->
                      expect(err).toBeNull()
                      return done(err) if err
                      expect(prepaid.get('redeemers')?.length).toEqual(1)
                      expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                      expect(prepaid.get('redeemers')[0].userID).toEqual(user2.get('_id'))

                      # Check course instance
                      CourseInstance.findById courseInstances[0].id, (err, courseInstance) ->
                        expect(err).toBeNull()
                        return done(err) if err
                        members = courseInstance.get('members')
                        expect(members?.length).toEqual(2)
                        # TODO: must be a better way to check membership
                        usersFound = 0
                        for memberID in members
                          usersFound++ if memberID.equals(user1.get('_id'))
                          usersFound++ if memberID.equals(user2.get('_id'))
                        expect(usersFound).toEqual(2)
                        done()

    it 'Redeem full prepaid code on instance of max 1', (done) ->
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
              Prepaid.findById courseInstances[0].get('prepaidID'), (err, prepaid) ->
                expect(err).toBeNull()
                return done(err) if err
                loginNewUser (user2) ->
                  request.post {uri: courseInstanceRedeemURL, json: {prepaidCode: prepaid.get('code')} }, (err, res) ->
                    expect(err).toBeNull()
                    expect(res.statusCode).toBe(200)
                    loginNewUser (user3) ->
                      request.post {uri: courseInstanceRedeemURL, json: {prepaidCode: prepaid.get('code')} }, (err, res) ->
                        expect(err).toBeNull()
                        expect(res.statusCode).toBe(403)
                        done()

    it 'Redeem 50 count course prepaid codes 51 times, in parallel', (done) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        seatCount = 50
        loginNewUser (user1) ->
          createCourse 0, (err, course) ->
            expect(err).toBeNull()
            return done(err) if err
            createCourseInstances user1, course.get('_id'), seatCount, token.id, (err, courseInstances) ->
              expect(err).toBeNull()
              return done(err) if err
              expect(courseInstances.length).toEqual(1)
              Prepaid.findById courseInstances[0].get('prepaidID'), (err, prepaid) ->
                expect(err).toBeNull()
                return done(err) if err

                forbiddenResults = 0
                makeRedeemCall = ->
                  (callback) ->
                    loginNewUser (user2) ->
                      request.post {uri: courseInstanceRedeemURL, json: {prepaidCode: prepaid.get('code')} }, (err, res) ->
                        expect(err).toBeNull()
                        if res.statusCode is 403
                          forbiddenResults++
                        else
                          expect(res.statusCode).toBe(200)
                        callback err
                tasks = (makeRedeemCall() for i in [1..seatCount+1])
                async.parallel tasks, (err, results) ->
                  expect(err?).toEqual(false)
                  expect(forbiddenResults).toEqual(1)
                  Prepaid.findById courseInstances[0].get('prepaidID'), (err, prepaid) ->
                    expect(err).toBeNull()
                    return done(err) if err
                    expect(prepaid.get('redeemers')?.length).toEqual(prepaid.get('maxRedeemers'))
                    done()
