config = require '../../../server_config'
require '../common'
utils = require '../../../app/core/utils' # Must come after require /common
mongoose = require 'mongoose'

classroomsURL = getURL('/db/classroom')

describe 'GET /db/classroom?ownerID=:id', ->
  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()
      
  it 'returns an array of classrooms with the given owner', (done) ->
    loginNewUser (user1) ->
      new Classroom({name: 'Classroom 1', ownerID: user1.get('_id') }).save (err, classroom) ->
        expect(err).toBeNull()
        loginNewUser (user2) ->
          new Classroom({name: 'Classroom 2', ownerID: user2.get('_id') }).save (err, classroom) ->
            expect(err).toBeNull()
            url = getURL('/db/classroom?ownerID='+user2.id)
            request.get { uri: url, json: true }, (err, res, body) ->
              expect(res.statusCode).toBe(200)
              expect(body.length).toBe(1)
              expect(body[0].name).toBe('Classroom 2')
              done()
              
  it 'returns 403 when a non-admin tries to get classrooms for another user', (done) ->
    loginNewUser (user1) ->
      loginNewUser (user2) ->
        url = getURL('/db/classroom?ownerID='+user1.id)
        request.get { uri: url }, (err, res, body) ->
          expect(res.statusCode).toBe(403)
          done()
  

describe 'GET /db/classroom/:id', ->
  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'returns the classroom for the given id', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 1' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        classroomID = body._id
        request.get {uri: classroomsURL + '/'  + body._id }, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          expect(body._id).toBe(classroomID = body._id)
          done()

describe 'POST /db/classroom', ->
  
  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'creates a new classroom for the given user', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 1' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        expect(body.name).toBe('Classroom 1')
        expect(body.members.length).toBe(0)
        expect(body.ownerID).toBe(user1.id)
        done()
        
  it 'does not work for anonymous users', (done) ->
    logoutUser ->
      data = { name: 'Classroom 2' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(401)
        done()
        
        
describe 'PUT /db/classroom', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'edits name and description', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 2' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        data = { name: 'Classroom 3', description: 'New Description' }
        url = classroomsURL + '/' + body._id
        request.put { uri: url, json: data }, (err, res, body) ->
          expect(body.name).toBe('Classroom 3')
          expect(body.description).toBe('New Description')
          done()
          
  it 'is not allowed if you are just a member', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 4' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        classroomCode = body.code
        loginNewUser (user2) ->
          url = getURL("/db/classroom/~/members")
          data = { code: classroomCode }
          request.post { uri: url, json: data }, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            url = classroomsURL + '/' + body._id
            request.put { uri: url, json: data }, (err, res, body) ->
              expect(res.statusCode).toBe(403)
              done()
            
describe 'POST /db/classroom/~/members', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'adds the signed in user to the list of members in the classroom', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 5' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        classroomCode = body.code
        classroomID = body._id
        expect(res.statusCode).toBe(200)
        loginNewUser (user2) ->
          url = getURL("/db/classroom/~/members")
          data = { code: classroomCode }
          request.post { uri: url, json: data }, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            Classroom.findById classroomID, (err, classroom) ->
              expect(classroom.get('members').length).toBe(1)
              done()


describe 'DELETE /db/classroom/:id/members', ->

  it 'clears database users and classrooms', (done) ->
    clearModels [User, Classroom], (err) ->
      throw err if err
      done()

  it 'removes the given user from the list of members in the classroom', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 6' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        classroomCode = body.code
        classroomID = body._id
        expect(res.statusCode).toBe(200)
        loginNewUser (user2) ->
          url = getURL("/db/classroom/~/members")
          data = { code: classroomCode }
          request.post { uri: url, json: data }, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            Classroom.findById classroomID, (err, classroom) ->
              expect(classroom.get('members').length).toBe(1)
              url = getURL("/db/classroom/#{classroom.id}/members")
              data = { userID: user2.id }
              request.del { uri: url, json: data }, (err, res, body) ->
                expect(res.statusCode).toBe(200)
                Classroom.findById classroomID, (err, classroom) ->
                  expect(classroom.get('members').length).toBe(0)
                  done()


describe 'POST /db/classroom/:id/invite-members', ->

  it 'takes a list of emails and sends invites', (done) ->
    loginNewUser (user1) ->
      data = { name: 'Classroom 6' }
      request.post {uri: classroomsURL, json: data }, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        url = classroomsURL + '/' + body._id + '/invite-members'
        data = { emails: ['test@test.com'] }
        request.post { uri: url, json: data }, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          done()
